
# Our Value Proposition

Everybody has endless demands on their time. If you're a student, you might be deciding which classes to take. There's never enough time to take them all, so you need to prioritize based on expected value. If you're a professional, you're deciding how to best use your limited "free" time to learn new skills and stay current. Either way, you're probably wondering: **What good is this book?** (And if you aren't asking that, you ought to be.)

You need many different skills for a successful career. This book won't teach you how to work with other people, or manage your tasks, or give and receive feedback. It won't teach you to program either; there are plenty of other books for that. Instead, this book will teach you:
* how to think more richly about what really matters about a system; 
* how to better express what you want from it;
* how to more thoroughly evaluate what a system actually does give you; and
* how to use constraints and constraint solvers in your work.
It will also give you a set of baseline skills that will aid you in using any further "formal" methods you might encounter in your work, such as [advanced type systems](https://rust-book.cs.brown.edu), [static verification](https://dafny.org), [theorem proving](https://lean-lang.org), and more. 

Here's why each of these skills is professionally valuable. 

## Modeling: What really matters?

There's a useful maxim by George Box: **"All models are wrong, but some are useful"**. The only completely accurate model of a system is that system itself, including all of its real external context. This is impractical; instead, a modeler needs to make choices about what really matters to them: what do you keep, and what do you disregard? Done well, a model gets at the essence of a system. Done poorly, a model yields nothing useful or, worse, gives a false sense of security. 

~~~admonish note title="George Box (1978)"
I suspect that people were saying "All models are wrong" long before Box did! But it's worth reading [this quote of his from 1978](https://doi.org/10.1016%2FB978-0-12-438150-6.50018-2), and thinking about the implications.

> Now it would be very remarkable if any system existing in the real world could be exactly represented by any simple model. However, cunningly chosen parsimonious models often do provide remarkably useful approximations. For example, the law $PV = nRT$ relating pressure $P$, volume $V$ and temperature $T$ of an "ideal" gas via a constant $R$ is not exactly true for any real gas, but it frequently provides a useful approximation and furthermore its structure is informative since it springs from a physical view of the behavior of gas molecules. For such a model there is no need to ask the question "Is the model true?". If "truth" is to be the "whole truth" the answer must be "No". **The only question of interest is "Is the model illuminating and useful?".** 

(Bolding mine.) **TODO: check quote text, Wiki link does not lead to a readable paper.**
~~~

### Professional Example: Data Models in Programming

You might already have benefitted from a good model (or suffered from a poor one) in your programming work. Whenever you write data definitions or class declarations in a program, [you're modeling](https://en.wikipedia.org/wiki/Data_model). The ground truth of the data is rarely identical to its representation. You decide on a particular way that it should be stored, transformed, and accessed. You say how one piece of data relates to another. 

Your data-modeling choices affect more than just execution speed: if a pizza order can't have a delivery address that is separate from the user's billing address, important user needs will be neglected. On the other hand, it is probably OK to leave the choice of cardboard box out of the user-facing order. An order has a delivery time, which probably comes with a time zone. You could model the time zone as an integer offset from UTC, but this is a [very bad idea](https://en.wikipedia.org/wiki/Time_zone). And, since there are 24 hours in a day, the real world imposes range limits: a timezone that's a million hours ahead of UTC is probably a buggy value, even though to value `1000000` is much smaller than even a signed 32-bit `int` can represent. 

<!-- The _level_ of abstraction matters, too. Suppose that your app scans handwritten orders. Then handwriting becomes pixels, which are converted into an instance of your data model, which is implemented as bytes, which are stored in hardware flip-flops and so on. What matters is whether the abstraction level suits your needs, and your users'.  -->

<!-- In security, a _threat model_ says what will be considered and what won't be. -->

<!-- ~~~admonish tip title="Memory Management" 
I learned to program in the 1990s, when practitioners were at odds over automated vs. manual memory management. It was often claimed that a programmer needed to _really understand_ what was happening at the hardware level, and manually control memory allocation for deallocation for the sake of performance. Most of us don't think that anymore, _unless we need to_! Level of abstraction matters. 
~~~ -->

<!-- ### Professional Example: Robotics 

When programming a 

 Grid world in AI is something richer. Want to hunt the wumpus? Can the wumpus hide in the pit? Probably not by the rules of the game, which are themselves a model. In the real world, perhaps it could. Box had something to say about this, too: 

 > Since all models are wrong the scientist must be alert to what is importantly wrong. It is inappropriate to be concerned about safety from mice when there are tigers abroad.  -->


## Specification: What do you want?


[ISO standard for date and time](https://en.wikipedia.org/wiki/ISO_8601)

## Testing and Verification: Did you get what you wanted?

Having thought through all that, it seems reasonable that the code should check these criteria, and produce a reasonable error if the timezone isn't valid.

fuzzing...

## What's "Formalism"

The word "formal" has accumulated some unfortunate implications: pedantry, stuffiness, ivory-tower abstraction, etc. 

We aren't used to thinking of programming, but it is. A programming language is a formal artifact: it has a precise meaning, usually defined in a specification. Some factors are often "implementation dependent", but that too is (if documented!) a formal thing. 
