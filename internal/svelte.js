const fs = require("fs");

const outputJs = process.argv[3];
const input = process.argv[2];

const svelte = require("svelte/compiler");

const source = fs.readFileSync(input, "utf8");

const preprocessOptions = require("svelte-preprocess")({});
preprocessOptions.filename = input;

svelte.preprocess(source, preprocessOptions).then(
  (processed) => {
    let result;
    try {
      result = svelte.compile(processed.toString(), {
        format: "esm",
        generate: "dom",
        filename: outputJs,
      });
    } catch (err) {
      console.log(`compile failed: ${err}`);
      return;
    }
    if (result.warnings.length > 0) {
      console.log(`warnings during compile: ${result.warnings}`);
      return;
    }
    fs.writeFileSync(outputJs, result.js.code);
  },
  (error) => {
    console.log(`preprocess failed: ${error}`);
  }
);
