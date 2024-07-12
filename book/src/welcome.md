## How To Read This Book 

Welcome to Logic for Systems! Here are some quick hints that will help you use this book effectively.

---

### Organization 

The book is organized into a series of short sections, each of which are grouped into chapters: 
* **Chapter 1 (Beyond Testing)** briefly motivates the content in this book and sets the stage with a new technique for testing your software. 
* **Chapter 2 (Modeling Static Scenarios)** provides an introduction to modeling systems in Forge by focusing on systems that don't change over time. 
* **Chapter 3 (Discrete Event Systems)** shows a common way to model the state of a system changing over time. 
* **Chapter 4 (Modeling Relationships)** enriches the modeling language to support arbitrary relations between objects in the world.
* **Chapter 5 (Temporal Specification)** covers temporal operators, which are commonly used in industrial modeling and specification, and how to use them. 
* **Chapter 6 (Case Studies)** touches on some larger applications of lightweight formal methods. Some of these will involve large models written in Forge, and others will lean more heavily on industrial systems.
* **Forge Documentation**

Each chapter contains a variety of examples: data structures, puzzles, algorithms, hardware concepts, etc. We hope that the diversity of domains covered means that everyone will see an example that resonates with them. Full language and tool documentation come _after_ the main body of the book. 



---

### Navigating the Book Site

With JavaScript enabled, the table of contents (to the left, by default) will allow you to select a specific section of this book. Likewise, the search bar (enabled via the "Toggle Searchbar" icon) should allow you to search for arbitrary alphanumeric phrases in the full text; unfortunately, non alphanumeric operators are not supported by search at present.

```admonish hint title="Table of Contents, Theme, and Search"
The three buttons for popping out the table of contents, changing the color theme, and searching are in the upper-left corner of this page, by default. If you do not see them, please ensure that JavaScript is enabled.

<center>
If the table of contents isn't open, click this button:
<label id="sidebar-toggle-alternate" class="icon-button" for="sidebar-toggle-anchor" title="Toggle Table of Contents" aria-label="Toggle Table of Contents (Alternate Button)" aria-controls="sidebar">
                            <i class="fa fa-bars"></i>
                        </label>

The table of contents for the Forge documentation is expandable. Once it is open, click the ❱ icons to expand individual sections and subsections to browse more easily! 

To change the color theme of the page, click this button:
<button id="theme-toggle" class="icon-button" type="button" title="Change theme" aria-label="Change theme (Alternate Button)" aria-haspopup="true" aria-expanded="false" aria-controls="theme-list">
                            <i class="fa fa-paint-brush"></i>
                        </button>

To search, click this button:
<button id="search-toggle" class="icon-button" type="button" title="Search. (Shortkey: s)" aria-label="Toggle Searchbar (Alternate Button)" aria-expanded="false" aria-keyshortcuts="S" aria-controls="searchbar">
                            <i class="fa fa-search"></i>
                        </button>
</center>
```

---

### Callout Boxes

Callout boxes can give valuable warnings, helpful hints, and other supplemental information. They are color- and symbol-coded depending on the type of information. For example:

~~~admonish tip title="This is a helpful tip."
Make sure to stay hydrated; it will help you learn.
~~~

~~~admonish warning title="This is a warning!"
Look both ways before you cross the street!
~~~

~~~admonish note title="This is a side note."
This book is written using the `mdbook` package. 
~~~

If you see a callout labeled "CSCI 1710", it means that it's specifically for students in Brown University's CSCI 1710 course, Logic for Systems.

---

### Exercises

Every now and then, you'll find question prompts, followed by a clickable header that looks like this: 

<details>
<summary>Think, then click!</summary>

**SPOILER TEXT**

</details> 

If you click the arrow, it will expand to show hidden text, often revealing an answer or some other piece of information that is meant to be read _after_ you've thought about the question. When you see these exercises, **don't skip past them**, and **don't just read the hidden text**. 

