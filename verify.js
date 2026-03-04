var fs = require('fs');
var targetRt = fs.readFileSync('bytecode/runtime-bytecode.txt', 'utf8').trim();
var src = fs.readFileSync('src/GavCoin-final.sol', 'utf8');

// Use any v0.3.x compiler
var solcPath = '.solc-bins/soljson-v0.3.1+commit.c492d9be.js';
if (!fs.existsSync(solcPath)) {
  console.error('Download solc first: curl -O https://binaries.soliditylang.org/bin/' + solcPath.split('/')[1]);
  process.exit(1);
}

var Module = require('./' + solcPath);
var compileFn = Module.cwrap('compileJSONMulti', 'string', ['string', 'number']);
var input = JSON.stringify({sources: {'GavCoin.sol': src}});
var output = JSON.parse(compileFn(input, 1));
var errs = (output.errors || []).filter(function(e) { return e.indexOf('Error') >= 0; });
if (errs.length > 0) { console.error('Compile errors:', errs); process.exit(1); }

var rt = '0x' + output.contracts['GavCoin'].runtimeBytecode;
if (rt === targetRt) {
  console.log('✅ EXACT MATCH: runtime bytecode matches on-chain 0xb4abc1bfc403a7b82c777420c81269858a4b8aa4');
  console.log('   Length:', rt.length, 'chars (' + rt.length/2 + ' bytes)');
} else {
  var diffs = 0;
  for (var i = 0; i < rt.length; i++) { if (rt[i] !== targetRt[i]) diffs++; }
  console.log('❌ MISMATCH:', diffs, 'chars differ, lengths: ours=' + rt.length + ' target=' + targetRt.length);
}
