#!/bin/bash
# try-version.sh - Try a specific solc version against the flattened source
#
# Usage: ./scripts/try-version.sh 0.3.6 [--optimize]

set -e

VERSION="${1:?Usage: try-version.sh <version> [--optimize]}"
OPTIMIZE="${2:-}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SOLC_DIR="$REPO_DIR/.solc-bins"
SOURCE_FILE="$REPO_DIR/src/GavCoin-flattened.sol"

RUNTIME_BYTECODE=$(cat "$REPO_DIR/bytecode/runtime-bytecode.txt" | tr -d '\n')
CREATION_BYTECODE=$(cat "$REPO_DIR/bytecode/creation-bytecode.txt" | tr -d '\n')

mkdir -p "$SOLC_DIR"

# Find the full version string
FULL_VER=$(curl -s "https://binaries.soliditylang.org/bin/list.json" | \
    node -e "var d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')); \
    var r=d.releases['$VERSION']||''; \
    if(r){console.log(r.replace('soljson-','').replace('.js',''))}else{ \
    for(var k in d.releases){if(k.startsWith('$VERSION')){console.log(d.releases[k].replace('soljson-','').replace('.js',''));break}}}")

if [ -z "$FULL_VER" ]; then
    echo "Version $VERSION not found"
    exit 1
fi

SOLC_JS="$SOLC_DIR/soljson-$FULL_VER.js"

if [ ! -f "$SOLC_JS" ]; then
    echo "Downloading solc $FULL_VER..."
    curl -sL "https://binaries.soliditylang.org/bin/soljson-$FULL_VER.js" -o "$SOLC_JS"
fi

echo "Compiling with solc $FULL_VER ${OPTIMIZE:-(no optimization)}..."
echo "Source: $SOURCE_FILE"
echo ""

node -e "
    var solc = require('$SOLC_JS');
    var input = require('fs').readFileSync('$SOURCE_FILE', 'utf8');
    var optimize = '$OPTIMIZE' === '--optimize' ? 1 : 0;
    var output;

    try {
        output = solc.compile(input, optimize);
    } catch(e) {
        console.error('Compile error:', e.message);
        process.exit(1);
    }

    var parsed;
    if (typeof output === 'string') {
        parsed = JSON.parse(output);
    } else {
        parsed = output;
    }

    if (parsed.errors) {
        parsed.errors.forEach(function(e) {
            console.error(typeof e === 'string' ? e : e.formattedMessage || e.message);
        });
    }

    var contracts = parsed.contracts || {};
    var found = false;
    for (var name in contracts) {
        var c = contracts[name];
        var bytecode = '0x' + (c.bytecode || '');
        var runtime = '0x' + (c.runtimeBytecode || c.deployedBytecode || '');
        console.log('Contract: ' + name);
        console.log('  Creation bytecode: ' + bytecode.substring(0, 60) + '...');
        console.log('  Creation length: ' + bytecode.length + ' chars');

        if (name.indexOf('GavCoin') >= 0) {
            found = true;
            console.log('');
            console.log('=== COMPARISON ===');
            console.log('Compiled creation: ' + bytecode.substring(0, 80));
            console.log('On-chain creation: ' + '$CREATION_BYTECODE'.substring(0, 80));
            console.log('');

            if (bytecode === '$CREATION_BYTECODE') {
                console.log('✅ EXACT CREATION BYTECODE MATCH!');
            } else {
                // Find first difference
                var minLen = Math.min(bytecode.length, '$CREATION_BYTECODE'.length);
                var diffAt = -1;
                for (var i = 0; i < minLen; i++) {
                    if (bytecode[i] !== '$CREATION_BYTECODE'[i]) {
                        diffAt = i;
                        break;
                    }
                }
                if (diffAt >= 0) {
                    console.log('❌ First difference at char ' + diffAt);
                    console.log('   Compiled: ...' + bytecode.substring(Math.max(0,diffAt-10), diffAt+20) + '...');
                    console.log('   On-chain: ...' + '$CREATION_BYTECODE'.substring(Math.max(0,diffAt-10), diffAt+20) + '...');
                } else if (bytecode.length !== '$CREATION_BYTECODE'.length) {
                    console.log('❌ Length mismatch: compiled=' + bytecode.length + ' on-chain=' + '$CREATION_BYTECODE'.length);
                }
            }
        }
    }

    if (!found) {
        console.log('');
        console.log('⚠️  GavCoin contract not found in compilation output');
        console.log('Available contracts:', Object.keys(contracts).join(', '));
    }
"
