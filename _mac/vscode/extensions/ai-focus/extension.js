const vscode = require("vscode");

async function focusTerminal(pids) {
  for (const t of vscode.window.terminals) {
    const pid = await t.processId;
    if (pid && pids.includes(pid)) {
      t.show(false); // false = take focus
      return true;
    }
  }
  return false;
}

function activate(context) {
  context.subscriptions.push(
    vscode.window.registerUriHandler({
      async handleUri(uri) {
        if (uri.path !== "/terminal") return;
        const pids = (new URLSearchParams(uri.query).get("pids") || "")
          .split(",").map(Number).filter(Boolean);
        if (!(await focusTerminal(pids))) {
          vscode.commands.executeCommand("workbench.action.terminal.focus");
          vscode.window.showWarningMessage("ai-focus: no terminal matches pids " + pids.join(","));
        }
      },
    })
  );
}

exports.activate = activate;
