#!/usr/bin/env python3
import sys
import json
import subprocess
import os

def run_git(args, cwd):
    env = os.environ.copy()
    env["GIT_TERMINAL_PROMPT"] = "0"
    res = subprocess.run(
        ["git"] + args,
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        timeout=5,
        env=env
    )
    return res.returncode, res.stdout.strip(), res.stderr.strip()

def main():
    # Read stdin to consume hook input
    try:
        raw_input = sys.stdin.read()
    except Exception:
        raw_input = ""

    repo_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

    try:
        # Check current branch
        code, current_branch, _ = run_git(["branch", "--show-current"], cwd=repo_dir)
        if code != 0 or not current_branch:
            # Detached HEAD or error
            print(json.dumps({"injectSteps": []}))
            return

        # Fetch quietly with quick timeout
        run_git(
            ["-c", "http.connectTimeout=3", "-c", "http.lowSpeedTime=3", "fetch", "origin", "--quiet"],
            cwd=repo_dir
        )

        # Get local commit
        code, local_hash, _ = run_git(["rev-parse", "HEAD"], cwd=repo_dir)
        if code != 0:
            print(json.dumps({"injectSteps": []}))
            return

        # Get remote upstream or origin/<current_branch> or origin/main
        code, remote_hash, _ = run_git(["rev-parse", "@{u}"], cwd=repo_dir)
        remote_ref = "@{u}"
        if code != 0:
            code, remote_hash, _ = run_git(["rev-parse", f"origin/{current_branch}"], cwd=repo_dir)
            remote_ref = f"origin/{current_branch}"
            if code != 0:
                code, remote_hash, _ = run_git(["rev-parse", "origin/main"], cwd=repo_dir)
                remote_ref = "origin/main"
                if code != 0:
                    print(json.dumps({"injectSteps": []}))
                    return

        if local_hash != remote_hash:
            # Check how many commits behind
            code, behind_count_str, _ = run_git(["rev-list", "--count", f"HEAD..{remote_ref}"], cwd=repo_dir)
            behind_count = int(behind_count_str) if (code == 0 and behind_count_str.isdigit()) else 0

            code, ahead_count_str, _ = run_git(["rev-list", "--count", f"{remote_ref}..HEAD"], cwd=repo_dir)
            ahead_count = int(ahead_count_str) if (code == 0 and ahead_count_str.isdigit()) else 0

            if behind_count > 0:
                msg = (
                    f"⚠️ [GIT SENKRONİZASYON HATIRLATMASI]: Yerel kodunuz GitHub'daki güncel versiyonla (son commit) aynı değil! "
                    f"Yerel dalınız ({current_branch}) remote daldan {behind_count} commit geride. "
                    f"Lütfen kullanıcının isteğini yanıtlarken en başta kodunu 'git pull' yaparak güncellemesi gerektiğini HATIRLAT."
                )
                print(json.dumps({
                    "injectSteps": [
                        {
                            "ephemeralMessage": msg
                        }
                    ]
                }))
                return
            elif ahead_count > 0:
                # Local has unpushed commits, remote has no new commits
                pass

        print(json.dumps({"injectSteps": []}))
    except Exception:
        # Failsafe: never crash the hook or block the agent loop
        print(json.dumps({"injectSteps": []}))

if __name__ == "__main__":
    main()
