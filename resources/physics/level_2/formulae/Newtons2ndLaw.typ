// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: white, width: 100%, inset: 8pt, body))
      }
    )
}



#let article(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  margin: (x: 1.25in, y: 1.25in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: "linux libertine",
  fontsize: 11pt,
  title-size: 1.5em,
  subtitle-size: 1.25em,
  heading-family: "linux libertine",
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  set page(
    paper: paper,
    margin: margin,
    numbering: "1",
  )
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering)
  if title != none {
    align(center)[#block(inset: 2em)[
      #set par(leading: heading-line-height)
      #if (heading-family != none or heading-weight != "bold" or heading-style != "normal"
           or heading-color != black or heading-decoration == "underline"
           or heading-background-color != none) {
        set text(font: heading-family, weight: heading-weight, style: heading-style, fill: heading-color)
        text(size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(size: subtitle-size)[#subtitle]
        }
      } else {
        text(weight: "bold", size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(weight: "bold", size: subtitle-size)[#subtitle]
        }
      }
    ]]
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[#abstract-title] #h(1em) #abstract
    ]
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#set table(
  inset: 6pt,
  stroke: none
)

#show: doc => article(
  title: [1. $F = m a$],
  authors: (
    ( name: [Alex Weatherall],
      affiliation: [],
      email: [] ),
    ),
  date: [2024-12-30],
  margin: (x: 1cm,y: 1cm,),
  paper: "a4",
  toc_title: [Table of contents],
  toc_depth: 3,
  cols: 1,
  doc,
)

= Introduction
<introduction>
When students first learn about Newton’s Second Law they tend to see it written as a formula $F = m a$ or more fully:

\$\$ \\textup{Force} = \\textup{mass} \\times \\textup{acceleration}\$\$

#block[
/ Force (F): #block[
is measured in #emph[newtons] (#emph[N];)
]

/ mass (m): #block[
is measured in #emph[kilograms] (#emph[kg];)
]

/ acceleration (a): #block[
is measured in #emph[metres per second] (#emph[m s#super[\-1];];)
]

]
Let’s unpack this formula so that we have got a good understanding of what is being described with these letters. I probably won’t go into this amount of detail for all formulae we cover, however this one is key, both for solving many problems and also for demonstrating some common ideas you need to be clear on when working with formula and linking them to physics concepts.

= Where does this formula come from?
<where-does-this-formula-come-from>
All the mathematical formula we use have been developed from a Law or theory (they mean pretty much the same thing) that a physicist (or more usually a group of physicists) has developed. Sometimes the ideas are expressed directly in a mathematical form from theoretical work, in other cases, the formula develops from experimental data that shows a quantitative relationship, and sometimes a mixture of the two. Sometimes new mathematical ideas develop out of the need to explain physical laws, and occasionally, new discoveries in maths result in new physical theories.

Isaac Newton developed his #link("../../../..\\concepts/NewtonLawsOfMotion")[three laws of motion] as he worked on the #link("https://simple.wikipedia.org/wiki/Philosophi%C3%A6_Naturalis_Principia_Mathematica")[Principia Mathematica] published in 1687.

#block[
#figure([
#box(image("Newtons2ndLaw_files\\mediabag\\Newtons_laws_in_lati.jpg"))
], caption: figure.caption(
position: bottom, 
[
Newton’s laws of motion
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


You can find more information about the different translations of Newton’s Law’s here at #link("https://telescoper.blog/2019/11/13/newtons-laws-in-translation/")[telescoper’s blog]

]
He wrote in Latin, the language of scholars at the time, and expressed his second law like this:

#quote(block: true)[
#emph[Mutationem motus proportionalem esse vi motrici impressæ, & fieri secundum lineam rectam qua vis illa imprimitur.]
]

which translates to:

#quote(block: true)[
The change of motion of an object is proportional to the force impressed; and is made in the direction of the straight line in which the force is impressed.
]

He continues to explain:

#quote(block: true)[
If a force generates a motion, a double force will generate double the motion, a triple force triple the motion, whether that force be impressed altogether and at once, or gradually and successively. And this motion (being always directed the same way with the generating force), if the body moved before, is added to or subtracted from the former motion, according as they directly conspire with or are directly contrary to each other; or obliquely joined, when they are oblique, so as to produce a new motion compounded from the determination of both.
]

Newton is using the word motion to mean the thing we now call #emph[momentum] - which describes a moving object. The momentum of the object depends on both the object’s mass and the object’s velocity or speed. The formula for momentum is $p = m v$. You can read more about this #link("./momentum.html")[here];.

Newton’s Second Law describes the #emph[change in motion] - we’ll call it a #emph[change in momentum];. This implies that an object’s momentum can have different values over time, and Newton’s law says that those differences are caused by the force on the object. An obvious example of this is an object that isn’t moving (and so it’s momentum is zero), when this object is given a push, the object is in motion, so it now has a velocity or speed. This difference from a zero momentum, to the momentum the object has when it is moving is refered to as its change in momentum.

More precise treatments or more complex scenarios require the use of Calculus (differentiation and integration) and we don’t cover these in Level 2 or Level 3 Physics, but you will be expected to do so when studying undergraduate Physics or Engineering courses.

In mathematics the when we describe change we can think about large changes (the difference between the start and end and get an average result), or use Calculus to account for very small changes and get a more accurate result). Both methods use the term #emph[delta] to mean change and use the Greek letter delta to represent it - the capital letter delta is $Delta$ and is used for large changes, the lower letter delta is $delta$ and is used when modelling small changes. In our classes we will be sticking to problems which consider large changes for simple scenarios.

To represent the large change of a value - let’s call it $X$ - mathematically, we refer to $Delta X$.

This is calculated like this $Delta X = X_(a f t e r) - X_(b e f o r e)$. You will also see these described as the initial and final values, they mean similar things. I like after and before as they shorten to #emph[a] and #emph[b];, and then the equation is always expressed in the correct order: A - B

So if the value of $X_(b e f o r e) = 16$ and the value of $X_(a f t e r) = 4$ then

$Delta X = X_(a f t e r) - X_(b e f o r e) = 4 - 16 = - 12$.

To practice this you can use this worksheet.

This can be simplified to force is proportional to mass $times$ acceleration. $F = m a$
