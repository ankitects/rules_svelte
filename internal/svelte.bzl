"Implementation of the svelte rule"

load("@build_bazel_rules_nodejs//:providers.bzl", "declaration_info")

SvelteFilesInfo = provider("transitive_sources")

def get_transitive_srcs(srcs, deps):
    return depset(
        srcs,
        transitive = [dep[SvelteFilesInfo].transitive_sources for dep in deps],
    )

def _svelte(ctx):
    ctx.actions.run_shell(
        mnemonic = "Svelte",
        command = """\
{svelte} {input} {output_js} && \
{tsc} {tsc_args} temp.tsx {shims} && \
mv temp.d.ts {output_def}""".format(
            svelte = ctx.executable._svelte.path,
            input = ctx.file.entry_point.path,
            output_js = ctx.outputs.build.path,
            tsc = ctx.executable._typescript.path,
            output_def = ctx.outputs.buildDef.path,
            tsc_args = "--jsx preserve --emitDeclarationOnly --declaration --skipLibCheck",
            shims = " ".join([f.path for f in ctx.files._shims]),
        ),
        outputs = [ctx.outputs.build, ctx.outputs.buildDef],
        inputs = [ctx.file.entry_point] + ctx.files._shims,
        tools = [ctx.executable._svelte, ctx.executable._typescript],
    )

    trans_srcs = get_transitive_srcs(ctx.files.srcs + [ctx.outputs.build, ctx.outputs.buildDef], ctx.attr.deps)

    return [
        declaration_info(depset([ctx.outputs.buildDef])),
        SvelteFilesInfo(transitive_sources = trans_srcs),
        DefaultInfo(files = trans_srcs),
    ]

svelte = rule(
    implementation = _svelte,
    attrs = {
        "entry_point": attr.label(allow_single_file = True),
        "deps": attr.label_list(),
        "srcs": attr.label_list(allow_files = True),
        "_svelte": attr.label(
            default = Label("//internal:svelte"),
            executable = True,
            cfg = "host",
        ),
        "_typescript": attr.label(
            default = Label("//internal:typescript"),
            executable = True,
            cfg = "host",
        ),
        "_shims": attr.label(
            default = Label("@npm//svelte2tsx:svelte2tsx__typings"),
            allow_files = True,
        ),
    },
    outputs = {
        "build": "%{name}.svelte.js",
        "buildDef": "%{name}.svelte.d.ts",
    },
)
