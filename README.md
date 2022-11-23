# HyperChip-8

HyperChip-8 is a modified Chip-8 Interpreter, Assembler and a Compiler.

It's purpose is to emulated Chip-8 as a *Computer* and not a *Game Console*.
For this reason, some of the games from Chip-8 do not work. The main difference
is that registers: _Program Counter_, _Stack Pointer_ and _(I)_ are stored in V registers.
For this reason games that use VA - VF Registers crash or run infinitely, until RAM end.

## Getting Started

You need Love2D which is free! And a code editor of your choice.

### Prerequisites

Requirements for HyperChip-8 to run: 
- [Love2D](https://love2d.org)

### Installing

To run the source code, just download the repository. Once done, open a terminal
in the project folder:

  Windows: love.exe .
  
  MacOS: love .
  
  Linux: love .

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code
of conduct, and the process for submitting pull requests to us.

## Authors

  - **Laurynas Suopys** - *Project Creator* -
    [lauriszz123](https://github.com/lauriszz123)

See also the list of
[contributors](https://github.com/lauriszz123/HyperChip-8/contributors)
who participated in this project.

## License

This project is licensed under the [CC0 1.0 Universal](LICENSE.md)
Creative Commons License - see the [LICENSE.md](LICENSE.md) file for
details
