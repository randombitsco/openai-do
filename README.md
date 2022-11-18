# openai-do

A Command-Line Interface (CLI) tool named `openai-do` to access the [OpenAI](https://openai.com) [GPT-3](https://beta.openai.com/) and [DALL-E](https://labs.openai.com) API.

It makes use of the [OpenAIBits](https://github.com/randombitsco/swift-openai-bits/) library to connect with OpenAI's public API.

## Installation

*TBD*

## Setup

While it is optional, it is suggested that you set your `OPENAI_API_KEY` and/or `OPENAI_ORG_KEY` environment values to the appropriate value for your organisation. If you chose not to, you can pass them in on each command by using the `--api-key` and `--org-key` arguments, respectively.

1. To create new key, sign in to your OpenAI account at [beta.openai.com](https://beta.openai.com/)
2. Find the [API Keys](https://beta.openai.com/account/api-keys) section.
3. Click the "Add Secret Key" button and record the new key value.
4. In your command line, use your preferred shell's profile to export the key (`zsh` use `.zshenv`, `bash`/`sh` use `.profile`):
   ```sh
   export OPENAI_API_KEY=sk-HGEI...FHIG%
   ```
5. (Optional) Export the organization key:
   ```sh
   export OPENAI_ORG_KEY=ok-BHGE...HGHE%
   ```

## Usage

The `openai-do` command provides access to built-in help documentation. If you enter:

```sh
$ openai-do --help
```

...you will be given a list of top-level commands:

```
OVERVIEW: A utility for working with OpenAI APIs.

USAGE: openai-do <subcommand>

OPTIONS:
  --version               Show the version.
  -h, --help              Show help information.

SUBCOMMANDS:
  models                  Commands to list and describe the various models available.
  completions             Commands relating to completions.
  edits                   Commands relating to edits.
  images                  Commands relating to images.
  embeddings              Commands relating to embeddings.
  files                   Used to manage documents that can be used with features like
                          `fine-tunes`.
  fine-tunes              Commands relating to listing, creating, and managing
                          fine-tuning models.
  moderations             Commands relating to moderations.
  tokens                  Commands relating to tokens.

  See 'openai-do help <subcommand>' for detailed help.
```

Each subscommand has its own list of commands. For example, you can get the details for the `models` subcommand:

```
$ openai-do help models
OVERVIEW: Commands to list and describe the various models available.

USAGE: openai-do models <subcommand>

OPTIONS:
  --version               Show the version.
  -h, --help              Show help information.

SUBCOMMANDS:
  list                    Lists the currently available models, and provides basic
                          information about each one, such as the owner and availability.
  detail                  Retrieves a model instance, providing basic information about
                          the model such as the owner and permissioning.

  See 'openai-do help models <subcommand>' for detailed help.
```

Then you can get further detail on the desired subcommand like so. This time, we'll use the `--help` argument instead:

```
$ openai-do models list --help
OVERVIEW: Lists the currently available models, and provides basic information about
each one, such as the owner and availability.

USAGE: openai-do models list [--edits] [--code] [--embeddings] [--fine-tuned] [--contains <contains>] [--api-key <api-key>] [--org-key <org-key>] [--verbose] [--debug]

OPTIONS:
  --edits                 If set, only models compatible with `edits` calls will be
                          listed.
  --code                  If set, only models compatible optimised for code generation
                          will be listed.
  --embeddings            If set, only models compatible with "embeddings create" calls
                          will be listed.
  --fine-tuned            If set, only fine-tuned models will be listed.
  --contains <contains>   A text value the model name must contains.
  --api-key <api-key>     The OpenAI API Key. If not provided, uses the 'OPENAI_API_KEY'
                          environment variable.
  --org-key <org-key>     The OpenAI Organisation Key. If not provided, uses the
                          'OPENAI_ORG_KEY' environment variable.
  --verbose               Output more details.
  --debug                 Output debugging information.
  --version               Show the version.
  -h, --help              Show help information.
```

Each command has a similar list of details about available options. Common ones are:

- `--api-key`: Allows you to provide the API Key directly, overriding any key stored in `OPENAI_API_KEY`.
- `--verbose`: Outputs additional details from a particular operation.
- `--debug`: Outputs the HTTPS request/response log where appropriate, and other problem-solving details depending on the context.

Most arguments relate directly to options documented by [OpenAI's API](https://beta.openai.com/docs/introduction), so read there to get more details on particular operations.