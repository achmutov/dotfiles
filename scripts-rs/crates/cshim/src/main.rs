use clap::Parser;
use std::{
    io::{BufWriter, Read, Write},
    os::unix::fs::PermissionsExt,
    path::PathBuf,
    process::ExitCode,
};

#[derive(Parser, Debug)]
enum CshimArgs {
    Init(InitArgs),
    Gen(GenerateArgs),
    Run(RunArgs),
    Clean,
}

const SHIMS_DEFAULT_PATH: &str = ".shims";

fn find_logs_path() -> Option<PathBuf> {
    std::env::home_dir().map(|home| home.join(PathBuf::from(".local/state/cshim")))
}

#[derive(Parser, Debug)]
struct InitArgs {
    #[arg(long, default_value = SHIMS_DEFAULT_PATH)]
    shims_path: PathBuf,
}

#[derive(Parser, Debug)]
struct GenerateArgs {
    target_command: PathBuf,
    #[arg(long, default_value = SHIMS_DEFAULT_PATH)]
    shims_path: PathBuf,
    #[arg(long, default_value = "/usr/bin/env sh")]
    shebang: String,
    #[arg(short, default_value_t = false)]
    force: bool,
}

#[derive(Parser, Debug)]
struct RunArgs {
    command_name: String,
    command: String,
    #[arg(last = true)]
    args: Vec<String>,
}

fn main() -> ExitCode {
    let mut args = std::env::args();

    // get cshim
    let Some(cshim_program_name) = args.next() else {
        eprintln!("failed get program name");
        return ExitCode::FAILURE;
    };

    match CshimArgs::parse() {
        CshimArgs::Init(InitArgs { shims_path }) => {
            if !shims_path.exists() {
                // create
                println!("creating new shims directory {}", shims_path.display());
                if let Err(err) = std::fs::create_dir(&shims_path) {
                    eprintln!("failed to create directory at '{}'", shims_path.display());
                    eprintln!("reason: {err:?}");
                    return ExitCode::FAILURE;
                }
            } else if !shims_path.is_dir() {
                // not dir => report
                eprintln!("shims path '{}' is not a directory", shims_path.display());
                return ExitCode::FAILURE;
            } else {
                eprintln!(
                    "failed to init shims path '{}': directory already exists",
                    shims_path.display()
                );
                return ExitCode::FAILURE;
            }

            let mut shims_bin_path = shims_path.join("bin");

            println!("creating new bin directory {}", shims_bin_path.display());
            if let Err(err) = std::fs::create_dir(&shims_bin_path) {
                eprintln!(
                    "failed to create directory at '{}'",
                    shims_bin_path.display()
                );
                eprintln!("reason: {err:?}");
                return ExitCode::FAILURE;
            }

            println!("creating new activate script");
            shims_bin_path.push("activate");

            let contents = format!(
                "export _SHIMS_PATH={}\n{}",
                shims_bin_path.display(),
                include_str!("../assets/activate")
            );

            if let Err(err) = std::fs::write(shims_bin_path, contents) {
                eprintln!("failed to save activate script");
                eprintln!("reason: {err:?}");
            }
        }
        CshimArgs::Gen(GenerateArgs {
            target_command,
            shims_path,
            shebang,
            force,
        }) => {
            let (new_shim_path, target_command_name) = {
                if !shims_path.exists() {
                    // create
                    eprintln!("shims path '{}' does not exist", shims_path.display());
                    eprintln!("consider initializing shims first");
                    return ExitCode::FAILURE;
                } else if !shims_path.is_dir() {
                    // not dir => report
                    eprintln!("shims path '{}' is not a directory", shims_path.display());
                    return ExitCode::FAILURE;
                };

                // get file name
                let target_command_name = match target_command.file_name() {
                    Some(target_command_name) => target_command_name,
                    None => {
                        eprintln!("failed to get target command name");
                        return ExitCode::FAILURE;
                    }
                };

                // create new shim path
                let mut shims_path = shims_path;
                shims_path.push(target_command_name);
                (shims_path, target_command_name)
            };

            // verify new shim path
            let exists = new_shim_path.exists();
            if new_shim_path.is_file() {
                if !force {
                    eprintln!(
                        "found existing shim file '{}', please provide --force to override it",
                        new_shim_path.display()
                    );
                    return ExitCode::FAILURE;
                }
            } else if new_shim_path.is_dir() {
                eprintln!(
                    "found existing shim and it is a directory: '{}'",
                    new_shim_path.display()
                );
                return ExitCode::FAILURE;
            } else if exists {
                println!("unknown destination '{}'", new_shim_path.display());
                return ExitCode::FAILURE;
            }

            let shim_content = format!(
                "#!{shebang}\n{cshim_program_name} run {} {} -- $@\n",
                target_command_name.display(),
                target_command.display(),
            );
            if let Err(err) = std::fs::write(&new_shim_path, shim_content) {
                eprintln!("failed to write shim file '{}'", new_shim_path.display());
                eprintln!("reason: {err:?}");
                return ExitCode::FAILURE;
            };

            // set executable permissions if not existed
            if !exists {
                let metadata = match std::fs::metadata(&new_shim_path) {
                    Ok(metadata) => metadata,
                    Err(err) => {
                        eprintln!("failed to obtain file permissions");
                        eprintln!("reason: {err:?}");
                        return ExitCode::FAILURE;
                    }
                };
                let mut permissions = metadata.permissions();
                permissions.set_mode(permissions.mode() | 0o111);
                if let Err(err) = std::fs::set_permissions(&new_shim_path, permissions) {
                    eprintln!("failed to set file permissions");
                    eprintln!("reason: {err:?}");
                    return ExitCode::FAILURE;
                }
            }

            println!("wrote shim {} successfully", new_shim_path.display());
        }
        CshimArgs::Run(RunArgs {
            command_name,
            command,
            args,
        }) => {
            let logs_path = match find_logs_path() {
                Some(logs_path) => logs_path,
                None => {
                    eprintln!("failed to access home path");
                    return ExitCode::FAILURE;
                }
            };

            // verify cshim_state_dir
            if !logs_path.exists() {
                // create
                println!(
                    "creating new cshims state directory {}",
                    logs_path.display()
                );
                if let Err(err) = std::fs::create_dir(&logs_path) {
                    eprintln!("failed to create directory at '{}'", logs_path.display());
                    eprintln!("reason: {err:?}");
                    return ExitCode::FAILURE;
                }
            } else if !logs_path.is_dir() {
                // not dir => report
                eprintln!(
                    "cshims state path '{}' is not a directory",
                    logs_path.display()
                );
                return ExitCode::FAILURE;
            };

            let (mut pipe_reader, writer) = match std::io::pipe() {
                Ok(rw) => rw,
                Err(err) => {
                    eprintln!("failed to create io pipe");
                    eprintln!("reason: {err:?}");
                    return ExitCode::FAILURE;
                }
            };

            let out_thread = std::thread::spawn(move || -> std::io::Result<()> {
                let now = jiff::ZonedDateTime::now();
                let now_fmt = now.strftime("%Y-%m-%d-%H:%M:%S%.3f");
                let log_path =
                    logs_path.join(PathBuf::from(format!("{now_fmt}-{command_name}.log")));

                let stdout = std::io::stdout();
                let file = std::fs::File::create(log_path)?;

                let mut buf_writer = BufWriter::new(file);
                let mut buf = [0u8; 4096];
                loop {
                    let n = pipe_reader.read(&mut buf)?;

                    if n == 0 {
                        break;
                    }

                    stdout.lock().write_all(&buf[0..n])?;
                    buf_writer.write_all(&buf[0..n])?;
                }
                Ok(())
            });

            // fire a command
            let execution_status = {
                let mut cmd = std::process::Command::new(&command);
                cmd.args(args)
                    .stderr(writer.try_clone().expect("failed to clone writer"))
                    .stdout(writer);

                match cmd.status() {
                    Ok(status) => {
                        if !status.success() {
                            status
                                .code()
                                .and_then(|code| u8::try_from(code).ok())
                                .map(ExitCode::from)
                                .unwrap_or(ExitCode::FAILURE)
                        } else {
                            ExitCode::SUCCESS
                        }
                    }
                    Err(err) => {
                        eprintln!("process failed to run");
                        eprintln!("reason: {err:?}");
                        return ExitCode::FAILURE;
                    }
                }
            };

            match out_thread.join() {
                Ok(Ok(())) => {}
                Ok(Err(err)) => {
                    eprintln!("output thread failed: {err:?}");
                    return ExitCode::FAILURE;
                }
                Err(err) => {
                    eprintln!("failed to join output thread: {err:?}");
                    return ExitCode::FAILURE;
                }
            };

            return execution_status;
        }
        CshimArgs::Clean => {
            let logs_path = match find_logs_path() {
                Some(logs_path) => logs_path,
                None => {
                    eprintln!("failed to access home path");
                    return ExitCode::FAILURE;
                }
            };

            let entries = match logs_path.read_dir() {
                Ok(entries) => entries,
                Err(err) => {
                    eprintln!("failed to read entries from logs dir");
                    eprintln!("reason: {err:?}");
                    return ExitCode::FAILURE;
                }
            };

            for entry in entries {
                let entry = match entry {
                    Ok(entry) => entry,
                    Err(err) => {
                        eprintln!("failed to access dir entry");
                        eprintln!("reason: {err:?}");
                        return ExitCode::FAILURE;
                    }
                };
                let path = entry.path();

                if entry.file_type().is_ok_and(|ty| ty.is_file())
                    && path.extension().is_some_and(|ext| ext == "log")
                    && let Err(err) = std::fs::remove_file(&path)
                {
                    eprintln!("failed to remove log file {path:?}");
                    eprintln!("reason: {err:?}");
                    return ExitCode::FAILURE;
                }
            }
        }
    };
    ExitCode::SUCCESS
}
