# Support for GTS morphisms and amalgamations

This repository hosts a set of Eclipse plugins enabling the convenient definition of GTS morphisms as well as the amalgamation of GTSs based on such morphisms.

## 1. Installation

We currently do not yet have an update site or fully functional feature. As a result, the plugins can only be used in development mode, following the steps below:

1. Install Eclipse, making sure to install EMF, Xtext, and Henshin. You may also wish to include an installation of EMFatic for easier editing of Ecore metamodels.
2. Clone the Henshin-Xtext adapters from [github:szschaler/henshin_xtext_adapter](https://github.com/szschaler/henshin_xtext_adapter) and import the plugin projects therein into your workspace. Alternatively, install the plugins into your Eclipse.
3. Clone the repository and import all projects except for the example project into your workspace.
4. Right-click on the [GenerateXDsmlCompose.mwe2](src/uk/ac/kcl/inf/GenerateXDsmlCompose.mwe2) file and choose `Run As/MWE2 workflow` to ensure all implementation files are correctly generated (this may be helpful to do also when pulling a new version of the repository). If Eclipse is showing errors in the projects, ignore them and run the generation anyway. After the generation and the rebuild of the workspace, all errors except for one on [N2.ecore](https://github.com/gts-morpher/gts_morpher/blob/master/uk.ac.kcl.inf.gts_morpher.tests/src/uk/ac/kcl/inf/gts_morpher/tests/composer/N2.ecore) should have disappeared. The remaining error is expected.
5. Choose `Run/Launch Runtime Eclipse` to start a fresh Eclipse with the plugins installed.
6. Create a new project (or import the example projects in the repository) and add a file with extension `.gts`. In this file, you will be able to specify your GTS morphisms.

## 2. Specifying GTS morphisms

GTSs and GTS morphisms are expressed in `.gts` files. These are text files using the syntax below (syntax completion is available throughout the Eclipse editor).

### 2.1. Basic GTS syntax

A GTS consists of a type graph (an Ecore metamodel) and an optional Henshin module with Henshin graph-transformation rules (note that Henshin units are not currently supported by the tool). You can specify a GTS using a GTS literal as below:

```
gts name {
  metamodel: "XXX"
  behaviour: "YYY"
}
```

Here, `name` can be an arbitrary, optional name for the GTS that may later be used to reference the GTS. The `metamodel` clause references an Ecore package (which must be found in a `.ecore` file on the classpath of the containing project) defining the metamodel (or typegraph) of the GTS. The `behaviour` clause references a Henshin module (which must be found in a `.henshin` file on the classpath of the containing project) the rules of which are considered to be the rules of the GTS. We currently only support Henshin (although we have plans to support other graph-transformation engines in the future) and do not support Henshin units. It is acceptable to leave out the `behaviour` clause.

Some alternative forms of specifying GTSs exist; these all differ primarily by what is specified between the curly braces. We will discuss GTS families and GTS amalgamation further down in this documentation.

Any GTS specification may be annotated with two modifiers: 

1. `export` in front of the `gts` keyword indicates that the `.ecore` (and optionally the `.henshin`) file of the GTS should be generated into the `src-gen` folder of the containing project. This currently works only for amalgamated GTSs, but we expect to also support family-based GTSs in the future.
2. `interface_of` GTSs are formed from the original metamodel and rules by only considering a sub-GTS typable over the metamodel elements explicitly annotated with `@Interface`. This is particularly useful for GTS amalgamation as described below.

Finally, a GTS specification can reference another named GTS. This is particularly useful when referencing a pre-defined GTS from a mapping specification (see below). The example below shows how:

```
gts MyGTS {
  metamodel: "A"
  behaviour: "B"
}

gts MyReferencingGTS interface_of {
  MyGTS
}
```

Here, `MyReferencingGTS` is the same as `MyGTS` except that it only uses elements annotated `@Interface` in the metamodel.

### 2.2. Basic morphism syntax

A GTS morphism is specified as a mapping between two GTSs, using a `map` clause:


```
map {
  from {
    metamodel: "YYY"
    behaviour: "YYY"
  }
  
  to {
    metamodel: "XXX"
    behaviour: "XXX"
  }
  
  type_mapping {
    class YYY => XXX
    reference YYY => XXX
    ...
  }
  
  behaviour_mapping {
    rule XXX to YYY {
      object yyy => xxx
      link yyy => xxx
      ...
    }
    ...
  }
}
```

Here, `from` and `to` each specify a GTS. The block in curly braces after `from` and `to` is actually a GTS specification (see above) with the gts keyword left out. If you want to name a GTS in such an in-line position, you can simply add the `gts` keyword and the name between `from`/`to` and `{`. If your GTSs do not have rules the `behaviour_mapping` clause should also be left out and the file only specifies a clan-morphism between the metamodels.

The mandatory `type_mapping` section describes the type-graph morphism part of the GTS morphism by providing a clan morphism between the two metamodels. This is achieved through a list of mapping statements that map either a `class` or a `reference`.

Similarly, the optional `behaviour_mapping` section describes rule mappings. Each rule mapping is started using the keyword `rule` followed by the name of the rule in the source GTS, the keyword `to`, and the name of the rule in the target GTS. Note that in the papers, the order rule names are mapped from target to source, but as this is only a technical formality, we decided that it would be more appropriate to use the more intuitive direction for the specification of GTS morphisms.

Each rule mapping again contains a list of mappings for objects and links in the LHS and RHS of the rule. NACs or PACs are currently not yet supported and neither are attributes, or other forms of constraints. Each mapping is again in the direction source to target. Only named objects can be mapped; therefore it is recommended that all objects in the GTS's rules be named. Objects and links that occur in the kernel of the rule only need to be mapped once. Link names are synthesised following this pattern: `[<source_object_name>-><target_object_name>:<reference_name>]`.

Extensive validation is performed for any mapping specification, including to check whether it represents a (potential) GTS morphism. Eclipse error and warning markers provide information and hints about the results of these checks.

### 2.2. Morphism auto-completion and unique auto-completion

The system will create error markers if type or behaviour mappings are not complete. As it can be quite tedious to type out all parts of the mapping, it is possible to ask the system to automatically complete a partial mapping. To do so, simply add the keyword `auto-complete` at the start of the specification:

```
auto-complete map { 
  ... 
}
```

As long as the mappings specified do not break the conditions for a GTS morphism, the system will attempt to complete the morphism automatically. Every time the file is saved, Eclipse's automated build mechanism will trigger a generation of all possible auto-completions into separate files in the `/src-gen` folder at the root of the containing project.

It is possible to claim that only a unique auto-completion to a morphism exists. This is done by adding the `unique` keyword like so:

```
auto-complete unique map { 
  ... 
}
```

The editor will add a warning marker to the `unique` keyword to show that this claim has not been checked yet. To check unique completability, explicitly request a validation by running the first `Validate` item from the editor's context menu. If auto-completion is not unique, an error marker will be added to the file. This provides quick-fix suggestions for mappings to add to sufficiently constrain the possible auto-completions. Suggestions are provided in order of potential impact; the top suggestion should offer the quickest path to unique auto-completion.

To see the results of auto-completion, right-click on your `.gts` file and select "Generate auto-completions". The auto-completions will be saved in files in the `src-gen/` folder of your project.

### 2.3 Mapping with virtual rules

When a rule in the source GTS cannot be mapped to any rule in the target GTS, it can be mapped to a virtual rule. To indicate that a rule should be mapped to a virtual rule, write a rule mapping of the following form:

```
  rule init to virtual
```

Note that `virtual` is a language keyword, rules named `"virtual"` are not supported. From such a rule mapping, the tool will generate a virtual rule with the same structure as the source rule and use that in the mapping. Note that to-virtual rule mappings cannot specify any element mappings; these are all implicit. This is so because the rule is dynamically generated only when needed. At the same time, there is only one valid mapping between source rule and virtual rule, so there is no need to specify it explicitly. 

Mapping to arbitrary virtual rues may affect behaviour-preservation properties of the morphism. To help with this, it is possible to constrain virtual rules to be identity rules; that is their left- and right-hand sides must be identical. Only identity rules can be mapped to virtual identity rules, of course, and the tool will check this. To specify a rule mapping to a virtual identity rule use the following form of rule mappings (where `init` is the name of a rule in the source GTS):

```
  rule init to virtual identity
```

Note that the word `identity` is a keyword in the morphism language. It is therefore not possible to map rules named `"identity"`. 

Where possible, auto-completion will consider completing by introducing to-virtual or even to-identity rule mappings. This behaviour can be restricted by claiming auto-completion is possible using only to-identity rule mappings or without using to-virtual mappings at all. To do so, use one of the following forms:

```
auto-complete to-identity-only map { ... }
```

to claim that only to-identity mappings might need to be introduced and 

```
auto-complete without-to-virtual map { ... }
```

to claim that no to-virtual mappings will need to be introduced to complete the morphism.

Conversely, you can also establish rule mappings from virtual empty source rules. Note that there is no need to consider identity source rules or any other more complex source rules: morphisms of the graphs constituting a rule will be from the source rule to the target rule, so for empty source rules such morphisms will trivially exist. 

To define a rule mapping from an empty source rule write:

```
  rule empty to do
```

where `do` is the name of a rule in the target GTS. `"empty"` is a keyword in the language and cannot be the name of a rule. 

You can ask auto-completion to consider introducing from-empty rule mappings automatically. Note that this is very likely to reduce the chances of producing *unique* auto-completions as from-empty mappings can be trivially introduced and can be trivially complemented with to-virtual mappings to ensure all rules in both GTSs have a mapping. In order to produce somewhat more intuitive behaviour, the tool will (1) not try to introduce from-empty mappings if a mapping with an actual source rule can be found, and (2) only try to introduce from-empty rule mappings if explicitly instructed to do so. To allow from-empty mappings to be included, use the following syntax:

```
auto-complete allow-from-empty map { ... }
``` 

## 3. GTS families

You can specify that the source or target of a GTS morphism should be taken from a GTS family by providing the definition of the family and the sequence of transformers to apply to the family's root GTS when picking the GTS you actually want. Our FASE paper [2] has more information on GTS families.

To specify a GTS family, replace the GTS specification with one that follows this format:

```
{
  family: {
    metamodel: "XXX"
	behaviour: "YYY"
    transformers: "ZZZ"
  }

  using [
    unitName(param1, param2, ...),
    unitName2(param1, param2, ...)
  ]
}
```

Here, `metamodel` and `behaviour` describe the root GTS of the family as usual. `transformers` references a Henshin module (this must be typed over Ecore and Henshin) with the transformer rules of the GTS family. Finally, the `using` clause indicates the sequence of transformer applications, including their actual parameters, to be used in deriving the correct GTS from inside the family. Currently, two types of parameters are supported: qualified names can be used to refer to classes, references, rules, or graph elements in the current GTS and string literals in double quotes can be used to provide string parameters. Other types of parameters are currently not supported, but may be added in future versions of the tool. Scoping isn't implemented in a fully dynamic manner at the moment, so there is no code-completion support for qualified-name parameters yet.

GTS family specifications as above can be used anywhere a GTS is expected to be provided.

## 4. GTS amalgamation

Once a valid morphism has been described (either as a complete map or by using ___unique___ auto-completion), GTS amalgamation can be performed (as per [1]). Where the source GTS is declared using `interface_of`, amalgamation will assume an inclusion to be defined by the `@Interface` annotations. It is currently not checked whether this is also an extension, so use at your own peril. `interface_of` for the target GTS is currently not supported when amalgamating GTSs.

To specify GTS amalgamation, use a special form of GTS specification:

```
gts name {
  weave: {
    map1: interface_of(A)
    map2: AB
  }
}
```

Here, `A` is a reference to an existing named GTS. `AB` is a reference to a named mapping (name mappings by adding the name just after the `map` keyword). So far, GTS amalgamation is only supported where one of the maps is an `interface_of` mapping and the other one is a named mapping. No further checks of the morphisms are undertaken and no guarantees are given wrt semantics preservation of the amalgamation step.

The `weave` clause can be extended with parameters specifying the rules to use when generating names for the amalgamated model elements. By default, weaving will preserve the names of all model elements that contributed to a given woven element. If these names are all identical, the new model element will have the same name. Otherwise, all names will be joined together using `_` as the separator. Names of model elements that are not mapped from the kernel GTS will be prefixed with `source__` or `target__`, respectively, to indicate their provenance.

The following parameters can be used to change this behaviour. These parameters are given as a comma-separated list in parentheses after the `weave` keyword and before the `:`.

- `preferMap1TargetNames` / `preferMap2TargetNames` can be used to indicate that only the names from the respective mapping should be preserved.
- `preferKernelNames` can be used to indicate that the names from the kernel GTS should be preserved.
- `dontLabelNonKernelElements` can be used to indicate that names of elements not from the kernel GTS should be left unchanged.

If any naming option leads to names that are not unique within their scope, the weaver will fall back to the default naming strategy for these elements.

For any amalgamated GTS that is labeled `export`, the automatic builder will generate a corresponding `.ecore` and (possibly) `.henshin` file in the `src-gen/` folder.

## Bibliography

[1] Francisco Durán, Antonio Moreno-Delgado, Fernando Orejas, and Steffen Zschaler: Amalgamation of Domain Specific Languages with Behaviour. Journal of Logical and Algebraic Methods in Programming, 86(1): 208--235, Jan. 2017.
[[pdf]](http://www.steffen-zschaler.de/download.php?type=pdf&id=106) [[http]](http://www.steffen-zschaler.de/download.php?type=http&id=106) 

[2] Steffen Zschaler and Francisco Duran: GTS Families for the Flexible Composition of Graph Transformation Systems. 20th International Conference on Fundamental Approaches to Software Engineering (FASE'17), 2017.
[[pdf ((c) Springer)]](http://www.steffen-zschaler.de/download.php?type=pdf&id=116) [[slides]](https://www.slideshare.net/SteffenZschaler/gts-families-for-the-flexible-composition-of-graph-transformation-systems) [[http]](http://www.steffen-zschaler.de/download.php?type=http&id=116)
