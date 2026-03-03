#!/bin/bash
# compare.sh - Download old solc versions and try to compile GavCoin to match on-chain bytecode
#
# Usage: ./scripts/compare.sh
#
# Tries all Solidity compiler versions from 0.1.1 through 0.3.6 with various settings.
# Uses the JavaScript compiler binaries from binaries.soliditylang.org.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SOLC_DIR="$REPO_DIR/.solc-bins"
RESULTS_FILE="$REPO_DIR/results.md"

CREATION_BYTECODE=$(cat "$REPO_DIR/bytecode/creation-bytecode.txt" | tr -d '\n')
RUNTIME_BYTECODE=$(cat "$REPO_DIR/bytecode/runtime-bytecode.txt" | tr -d '\n')

mkdir -p "$SOLC_DIR"

echo "# Compilation Results" > "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"
echo "On-chain runtime bytecode (first 40 chars): ${RUNTIME_BYTECODE:0:40}..." >> "$RESULTS_FILE"
echo "On-chain runtime bytecode length: ${#RUNTIME_BYTECODE} chars" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

# Candidate versions (all versions available at or before April 2016)
VERSIONS=(
    "v0.1.1+commit.6ff4cd6"
    "v0.1.2+commit.d0d36e3"
    "v0.1.3+commit.028f561d"
    "v0.1.4+commit.5f6c3cdf"
    "v0.1.5+commit.23865e39"
    "v0.1.6+commit.d41f8b7c"
    "v0.1.7+commit.b4e666cc"
    "v0.2.0+commit.4dc2445e"
    "v0.2.1+commit.91a6b35f"
    "v0.2.2+commit.ef92f566"
    "v0.3.0+commit.11d67369"
    "v0.3.1+commit.c492d9be"
    "v0.3.2+commit.81ae2a78"
    "v0.3.3+commit.4dc1cb14"
    "v0.3.4+commit.7dab8902"
    "v0.3.5+commit.5f97274a"
    "v0.3.6+commit.3fc68da5"
)

SOURCE_FILE="$REPO_DIR/src/GavCoin-flattened.sol"

for ver in "${VERSIONS[@]}"; do
    SOLC_JS="$SOLC_DIR/soljson-$ver.js"

    # Download if not cached
    if [ ! -f "$SOLC_JS" ]; then
        echo "Downloading solc $ver..."
        curl -sL "https://binaries.soliditylang.org/bin/soljson-$ver.js" -o "$SOLC_JS"
    fi

    echo "Trying $ver..."

    # Try without optimization
    for optimize in "" "--optimize"; do
        opt_label="${optimize:-(no-opt)}"

        # Use solcjs via node to compile
        RESULT=$(node -e "
            var solc = require('$SOLC_JS');
            // Handle different API versions
            if (typeof solc.compile === 'function') {
                // Newer API (0.2+)
                try {
                    var input = require('fs').readFileSync('$SOURCE_FILE', 'utf8');
                    var output;
                    if (solc.compile.length > 1) {
                        output = solc.compile(input, '$optimize' === '--optimize' ? 1 : 0);
                    } else {
                        var inputJson = JSON.stringify({
                            language: 'Solidity',
                            sources: { 'GavCoin.sol': { content: input } },
                            settings: {
                                optimizer: { enabled: '$optimize' === '--optimize', runs: 200 },
                                outputSelection: { '*': { '*': ['evm.bytecode', 'evm.deployedBytecode'] } }
                            }
                        });
                        output = JSON.parse(solc.compile(inputJson));
                    }

                    if (typeof output === 'string') {
                        var parsed = JSON.parse(output);
                        if (parsed.errors) {
                            var errs = parsed.errors.filter(function(e) { return e.type === 'Error' || (typeof e === 'string' && e.indexOf('Error') >= 0); });
                            if (errs.length > 0) {
                                console.log('COMPILE_ERROR: ' + (errs[0].message || errs[0]).substring(0, 200));
                            } else {
                                var contracts = parsed.contracts || {};
                                for (var name in contracts) {
                                    if (name.indexOf('GavCoin') >= 0) {
                                        var bytecode = contracts[name].bytecode || '';
                                        console.log('BYTECODE:0x' + bytecode);
                                    }
                                }
                            }
                        } else {
                            var contracts = parsed.contracts || {};
                            for (var name in contracts) {
                                if (name.indexOf('GavCoin') >= 0) {
                                    var bytecode = contracts[name].bytecode || '';
                                    console.log('BYTECODE:0x' + bytecode);
                                }
                            }
                        }
                    } else if (output && output.contracts) {
                        for (var name in output.contracts) {
                            if (name.indexOf('GavCoin') >= 0) {
                                var c = output.contracts[name];
                                var bytecode = c.bytecode || (c.evm && c.evm.bytecode && c.evm.bytecode.object) || '';
                                console.log('BYTECODE:0x' + bytecode);
                            }
                        }
                        if (output.errors) {
                            output.errors.forEach(function(e) {
                                if (e.type === 'Error' || (typeof e === 'string' && e.indexOf('Error') >= 0)) {
                                    console.log('COMPILE_ERROR: ' + (e.message || e).substring(0, 200));
                                }
                            });
                        }
                    }
                } catch(e) {
                    console.log('COMPILE_ERROR: ' + e.message.substring(0, 200));
                }
            } else {
                console.log('COMPILE_ERROR: Unknown solc API');
            }
        " 2>&1)

        if echo "$RESULT" | grep -q "^BYTECODE:"; then
            COMPILED=$(echo "$RESULT" | grep "^BYTECODE:" | sed 's/^BYTECODE://')
            COMPILED_LEN=${#COMPILED}

            if [ "$COMPILED" = "$CREATION_BYTECODE" ]; then
                echo "  ✅ EXACT MATCH (creation)! $ver $opt_label"
                echo "## ✅ EXACT MATCH: $ver $opt_label" >> "$RESULTS_FILE"
            elif [ "${COMPILED: -${#RUNTIME_BYTECODE}}" = "$RUNTIME_BYTECODE" ]; then
                echo "  ✅ Runtime bytecode match! $ver $opt_label"
                echo "## ✅ Runtime match: $ver $opt_label" >> "$RESULTS_FILE"
            else
                # Check partial match
                MATCH_CHARS=0
                for i in $(seq 0 $((${#RUNTIME_BYTECODE} - 1))); do
                    if [ "${COMPILED:$i:1}" = "${RUNTIME_BYTECODE:$i:1}" ]; then
                        MATCH_CHARS=$((MATCH_CHARS + 1))
                    fi
                done
                MATCH_PCT=$((MATCH_CHARS * 100 / ${#RUNTIME_BYTECODE}))
                echo "  ❌ No match ($COMPILED_LEN chars, ${MATCH_PCT}% similar) $ver $opt_label"
                echo "- $ver $opt_label: $COMPILED_LEN chars, ${MATCH_PCT}% similar" >> "$RESULTS_FILE"
            fi
        else
            ERROR=$(echo "$RESULT" | grep "COMPILE_ERROR" | head -1)
            echo "  ⚠️  $ver $opt_label: ${ERROR:-unknown error}"
            echo "- $ver $opt_label: ${ERROR:-compile failed}" >> "$RESULTS_FILE"
        fi
    done
done

echo ""
echo "Results saved to $RESULTS_FILE"
