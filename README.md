<img height=40 src='http://my5C.umassmed.edu/images/3DG.png' title='3D-Genome' />
&nbsp;&nbsp;
<img height=30 src='http://my5C.umassmed.edu/images/dekkerlabbioinformatics.gif' />
&nbsp;&nbsp;
<img height=30 src='http://my5C.umassmed.edu/images/umasslogo.gif' />

# crane-nature-2015

Publisher: NPG; 
Journal: Nature; 
Article Type: Biology letter
DOI: 10.1038/nature14450

<b>Condensin-driven remodelling of X chromosome topology during dosage compensation</b>
<br><br>
<b>Emily Crane</b>1, <b>Qian Bian</b>1, <b>Rachel Patton McCord</b>2, <b>Bryan R. Lajoie</b>2, Bayly S. Wheeler1, Edward J. Ralston1, Satoru Uzawa1, Job Dekker2 & Barbara J. Meyer1 

Code associated with paper.

```
scripts/
    matrix2insulation.pl - Calculate insulation vector from matrix (tsv) file (matrix.gz)
```
## Installation
    
    Download the project.
    ```
    wget -O crane-nature-2015.zip https://github.com/blajoie/crane-nature-2015/archive/master.zip
    ```
    Or clone the git project
    ```
    [ssh] - git clone git@github.com:blajoie/crane-nature-2015.git
    [https] - git clone https://github.com/blajoie/crane-nature-2015.git
    ```

    Unzip the master:
    ```
    unzip crane-nature-2015.zip
    cd crane-nature-2015/
    ```
    
    To install the module:
    ```
    perl Build.PL
    ./Build
    ./Build install
    ```
    
    After installing the module, you should be free to run the matrix2insulation.pl script:
    ```
    $ perl scripts/matrix2insulation.pl
    ```

## Usage

```

See wiki for format spec.
https://github.com/blajoie/crane-nature-2015/wiki

$ perl scripts/matrix2insulation.pl

Tool:           matrix2insulation.pl
Version:        1.0.0
Summary:        calculate insulation index (TADs) of supplied matrix

Usage: perl matrix2insulation.pl [OPTIONS] -i <inputMatrix>

Required:

        -i         []         input matrix file

Options:

        -b         []         size (bp) of the insulation square

        -v         []         FLAG, verbose mode

        -ids       []         insulation delta span (size (bp) of insulation delta window)

        -im        []         insulation mode (how to aggregrate signal within insulation square), mean,sum,median

        -nt        [0.1]      noise threshold, minimum depth of valley

        -bmoe      [3]        boundary margin of error (specified in number of BINS), added to each side of the boundary

Notes:
        This script calculates the insulation index of a given matrix to identify TAD boundaries.
        Matrix can be TXT or gzipped TXT.
        See git wiki for details.

        Code associated with Crane, Bian, McCord, Lajoie et al. Nature 2015
        Publisher: NPG; Journal: Nature; Article Type: Biology letter DOI: 10.1038/nature14450
        Condensin-driven remodelling of X chromosome topology during dosage compensation 
        Emily Crane, Qian Bian, Rachel Patton McCord, Bryan R. Lajoie, Bayly S. Wheeler, Edward J. Ralston, Satoru Uzawa, Job Dekker & Barbara J. Meyer

Contact:
        Dekker Lab
        Bryan R. Lajoie
        http://my5C.umassmed.edu
        my5C.help@umassmed.edu
        https://github.com/blajoie/crane-nature-2015

```

## Published Parameters

To re-create chrX data from paper (same options for autosomes):
```
    perl scripts/matrix2insulation.pl -i test/input/SRy93-DpnII__10kb__chrX.matrix.gz -is 500000 -ids 200000 -im mean -bmoe 3 -nt 0.1 -v
    perl scripts/matrix2insulation.pl -i test/input/N2-DpnII__10kb__chrX.matrix.gz -is 500000 -ids 200000 -im mean -bmoe 3 -nt 0.1 -v
```

## Bugs and Feedback

For bugs, questions and discussions please use the [Github Issues](https://github.com/blajoie/c-world-encode/issues).

## LICENSE

Licensed under the Apache License, Version 2.0 (the 'License');
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an 'AS IS' BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
