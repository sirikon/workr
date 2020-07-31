# Workr Documentation

Workr is a **simple** and **easy** to setup job runner for any kind of
automation. Think of it like a lightweight and super-simplified
[Jenkins](https://www.jenkins.io/) or a self-hosted
[CircleCI](https://circleci.com/) that you configure using **plain text files**
and each job is just a **runnable script**.

The whole documentation is one big document (this document), but divided in
many sections. This way you can:

- Get both the superficial docs (The Quickstart) and the more detailed docs.
- Use `Ctrl + F` to find anything in it.

## Quickstart

The first step is to install Workr. Workr is distributed as a pre-compiled
static binary in the `Releases` section. There you can use the `.deb` package
if you're on a Debian-based distro, or use the `.tar.gz` package that just has
the `workr` binary inside it.

Whatever installation method you choose, make sure the `workr` binary ends up
available under your system's `PATH`.

Now we need to define a working directory for Workr, which will contain both
the **job definitions** and all the **data related to them**. From now on,
during the examples this folder will be `/srv/workr`, but choose any other
folder if you want.

In our working directory, let's run:

```bash
workr configure
```

This will start a short configuration wizard asking for a
[JWT](https://en.wikipedia.org/wiki/JSON_Web_Token) secret and a password for
the admin user. Once finished, a file `workr.json` will be generated.

At this point you can start Workr. Leave this running on the working directory,
on another terminal:

```bash
workr daemon
```

And visit http://127.0.0.1:8080/. It looks a bit empty, but no worries. Now
it's time to define our **first job**.

Create a `jobs` folder and, inside it, another folder called `pinger` with a
file in it called `run`, with the following content:

```bash
#!/usr/bin/env bash

ping 8.8.8.8 -c 4
# This just pings 8.8.8.8 four times. No big deal :)
```

At the end, the file hierarchy should look like this:

```
jobs/
  pinger/
    run
```

Don't forget to make the `run` file an executable file, running this:
```bash
chmod +x ./jobs/pinger/run
```

Now go back to http://127.0.0.1:8080/, you should see a new job called
`pinger`.

Clicking on it you'll see, again, an empty list, but that's because we didn't
execute the job yet. For executing jobs you need to be logged in as `admin`, so
go to the Login page (clicking on the upper-right link "Login") and enter the
admin credentials:

- Username: `admin`
- Password: The password you wrote earlier during the configuration wizard.

If login succeeded, go again to http://127.0.0.1:8080/job/pinger, this time an
"Execute" button is available right after "Job pinger". Click on it!.

While jobs are being executed, their output is streamed directly to the web
clients, so you can see the progress in real time.

Going back to http://127.0.0.1:8080/job/pinger, the execution list now has a
new row. Here you can see all the executions that a job has, and the output of
all of them is available with a single click.

Now it's your turn to automate cool stuff with Workr. Enjoy it!.

## Design decisions

### Workr is a job runner. Nothing more

Workr tries to do just one thing and do it as good as possible: You give Workr
something to do, and it presents you an interface to execute it and see the
progress.

That's why Workr may be missing some functionalities that people could expect
from similar CI/CD services or job runners, like:

- **Job sandboxing**: You give Workr a job, and it executes it. If that job
  requires some kind of sandboxing to protect it from external resources or
  code execution, that's something you have to provide. If your job is
  vulnerable to arbitrary code execution (like, for example, `npm install`ing
  stuff that may come with shady post-install scripts that do some evil), maybe
  you need to setup QEMU in the machine and use it in the job, so the external
  dependencies are downloaded in a sandboxed environment.

- **Integration with third party services**: Workr can surely improve in
  reporting and transparency, so you can run extra steps when jobs are started
  or done, but Workr won't include, by itself, any code that knows how to talk
  with external services. For example: If you need to get notified on Slack
  when an specific job is finished, then run some script within the job itself
  that does so.

As of today, don't expect to get any of those functionalities in Workr anytime
soon. But if you disagree and you really think that any of those features
definitely should exist in Workr, please,
[open an issue](https://github.com/sirikon/workr/issues) and let's discuss it.

### Workr is small

Small technology is better than big technology. It makes it a piece easier to
introduce in a puzzle and solve problems.

That means that Workr should be minimal in terms of weight, resource
consumption, and, most importanly, **complexity**, both on maintainance and
usage.

Right now, all you need to have Workr running is a couple of folders, a
runnable script and a configuration file that can be generated by Workr itself.
And that shouldn't get worse over time.
