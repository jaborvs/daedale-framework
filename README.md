<a name="readme-top"></a>

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![MIT License][license-shield]][license-url]

# The DÆDALE Framework
DÆDALE is a novel framework for generating interactive puzzle tutorials in [PuzzleScript](https://www.puzzlescript.net). It integrates two core components:

- **PAPYRVS**: An extension to PuzzleScript that enables designers to model tutorial goal chains using verb-enriched playtraces and rewrite rules.
- **DÆDALE**: A procedural level generator and integrated development environment (IDE) built on Rascal, used to generate and test tutorial levels based on the models defined in PAPYRVS.

This project aims to assist game designers in automating the creation of high-quality puzzle tutorials that support structured learning through trial and error.

## Features

- **DSL for Tutorial Modeling.** PAPYRVS allows designers to:
  - Extend PuzzleScript with structured sections: `Configuration`, `Patterns`, `Modules`, and `Drafts`
  - Define reusable interaction patterns and rewrite rules
  - Encode tutorial goal chains using verb-enriched playtraces

- **Procedural Generation Engine.** DÆDALE generates solvable levels that:
  - Embed learning goals through player actions
  - Are guided by verb-enriched playtraces
  - Project playtraces into tilemaps using string-based rewriting

- **Integrated IDE.** The framework includes a GUI that allows designers to:
  - Visual code editing for both PuzzleScript and PAPYRVS
  - Built-in level generation and playtesting
  - Real-time feedback via a console panel

<!-- ABOUT THE PROJECT -->
## Technology Stack

DÆDALE has been built using the following programming languages:

[![Rascal][Rascal.org]][Rascal-url]
[![Python][Python.org]][Python-url]

## License
Distributed under the MIT License. See [`LICENSE.txt`](license-url) for more information.

## Acknowledgments
DÆDALE was conceived and developed within the scope of my Master's thesis pursued within the 
MSc program in Software Engineering at the University of Amsterdam. 
I want to thank my thesis supervisor, Riemer van Rozen, for 
his invaluable guidance and support throughout the entire duration of the project. 
Furthermore, I wish to acknowledge the contributions of previous collaborators to the 
project repository, namely Clement Julia, the creator of ScriptButler, and Dennis Vet, 
the creator of TutoMate.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

[contributors-shield]: https://img.shields.io/github/contributors/jaborvs/daedale-framework.svg?style=for-the-badge
[contributors-url]: https://github.com/jaborvs/daedale-framework/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/jaborvs/daedale-framework.svg?style=for-the-badge
[forks-url]: https://github.com/jaborvs/daedale-framework/network/members
[stars-shield]: https://img.shields.io/github/stars/jaborvs/daedale-framework.svg?style=for-the-badge
[stars-url]: https://github.com/jaborvs/daedale-framework/stargazers
[issues-shield]: https://img.shields.io/github/issues/jaborvs/daedale-framework.svg?style=for-the-badge
[issues-url]: https://github.com/jaborvs/daedale-framework/issues
[license-shield]: https://img.shields.io/github/license/jaborvs/daedale-framework.svg?style=for-the-badge
[license-url]: https://github.com/jaborvs/daedale-framework/blob/main/LICENSE.txt
[product-screenshot]: images/screenshot.png
[Python.org]: https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54
[Python-url]: https://www.python.org/
[Rascal.org]: https://img.shields.io/badge/Rascal-85A1AE?style=for-the-badge&logo=Rascal&logoColor=85A1AE
[Rascal-url]: https://www.rascal-mpl.org/