# Support for GTS morphisms and amalgamations

This repository hosts a set of Eclipse plugins enabling the convenient definition of GTS morphisms as well as the amalgamation of GTSs based on such morphisms.

## 1. Installation

We currently do not yet have an update site or fully functional feature. As a result, the plugins can only be used in development mode, following the steps below:

1. Install Eclipse, making sure to install EMF, Xtext, and Henshin. You may also wish to include an installation of EMFatic for easier editing of Ecore metamodels.
2. Clone the repository and import all projects except for the example project into a fresh Eclipse workspace.
3. Choose `Run/Launch Runtime Eclipse` to start a fresh Eclipse with the plugins installed.
4. Create a new project (we will also soon provide some example projects in the repository) and add a file with extension `.lang_compose`. In this file, you will be able to specify your GTS morphisms.

## 2. Specifying GTS morphisms

### 2.1. Basic morphism syntax

GTS morphisms are expressed in `.lang_compose` files. These are text files using the following syntax (syntax completion is available throughout the Eclipse editor):

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

Here, `from` and `to` each specify a GTS by reference to external models. The `metamodel` clause references an Ecore package (which must be found in a `.ecore` file on the classpath of the containing project) defining the metamodel (or typegraph) of the GTS. The `behaviour` clause references a Henshin module (which must be found in a `.henshin` file on the classpath of the containing project) the rules of which are considered to be the rules of the GTS. We currently only support Henshin (although we have plans to support other graph-transformation engines in the future) and do not support Henshin units. It is acceptable to leave out the `behaviour` clauses, in which case the `behaviour_mapping` clause should also be left out and the file only specifies a clan-morphism between the metamodels.

The mandatory `type_mapping` section describes the type-graph morphism part of the GTS morphism by providing a clan morphism between the two metamodels. This is achieved through a list of mapping statements that map either a `class` or a `reference`.

Similarly, the optional `behaviour_mapping` section describes rule mappings. Each rule mapping is started using the keyword `rule` followed by the name of the rule in the target GTS, the keyword `to`, and the name of the rule in the source GTS. Note the order of rule names; this is in accordance with the definition of GTS morphisms, mapping rule names in the direction opposite to the direction of the morphism.

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

### 2.3. `interface_of` morphisms

When specifying the source or target GTS, the keyword `interface_of` can be added to the specification:

```
map {
  from interface_of {
    metamodel: "YYY"
    behaviour: "YYY"
  }
  
  ...
}
```

This will check the GTS described and only consider a sub-GTS typable over the metamodel elements explicitly annotated `@Interface`. This is particularly useful for GTS amalgamation as described below.

## 3. GTS amalgamation

Once a valid morphism has been described (either as a complete map or by using ___unique___ auto-completion), GTS amalgamation can be performed. Where the source GTS is declared using `interface_of`, amalgamation will assume an inclusion to be defined by the `@Interface` annotations. It is currently not checked whether this is also an extension, so use at your own peril. `interface_of` for the target GTS is currently not supported when amalgamating GTSs.

To trigger amalgamation, right-click on the `.lang_compose` file and select the `Weave xDSMLs` menu option. Assuming there are no errors, this will produce a `tg.ecore` and a `rules.henshin` (assuming there is a behaviour mapping) file in a sub-folder of `/src-gen` named after the `.lang_compose` file.

So far, no further checks of the morphisms are undertaken and no guarantees are given wrt semantics preservation of the amalgamation step.
