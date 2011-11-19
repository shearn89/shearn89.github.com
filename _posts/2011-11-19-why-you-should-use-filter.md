---
layout: post
title: Why you should use filter()
---

November 19, 2011, 18:16

# Why you should use filter() #

So, I'm currently doing the last bit of Text Technologies coursework, and am profiling my code to make it run quicker. The slowest bit was the cleaning of self-linked vertices from the graph that we have to analyze.

I started by doing this in a (fairly horrible) `for` loop:

{% highlight python %}
def cleanSelfMails(graph):
        print "> Removing a->a type links."
        count = 1
        length = len(graph)
        for (i,entry) in enumerate(graph):
                print "\r%s/%s (%.3f%%)" % (i,length,(float(i)/length)*100),
                sys.stdout.flush()
                if entry[1] == entry[2]:
                        count += 1
                        graph.remove(entry)
        print "\n> done."
        return graph
{% endhighlight %}

Now, I realise that this actually goes through the list again every time it encounters a self-linked vertex, as `graph.remove(entry)` has to search through `graph` to find the entry that matches. This is horrible.

It also took approximately 985 CPU seconds to run (even on the student.compute server). It should be noted that while working on this coursework I wrote this method, ran it once, and saved the cleaned-up graph to a file. Then I simply loaded that at runtime, which saved a shedload of time. However, I'll have to submit the code on Monday, and I think it's messy to have to submit data sources, so I'm refactoring...

So, I thought about how to use the much more efficient list comprehension and inbuilt map functions in python, and ended up thinking about the good old days of 1st year, and Haskell's lambda calculus. I ended up with this:

{% highlight python %}
def cleanSelfMails(graph):
	print "> Removing a->a type links."
	count = 1
	length = len(graph)
	graph = filter(lambda entry: entry[1] != entry[2], graph)
	print "> done."
	return graph
{% endhighlight %}

Which, according to my profiling, takes 23 CPU seconds. Yep, **23**. Incredible. I even ran it twice to check. Still came out at **22**.

So, if you ever think about doing something horrible like a double/triple loop for a massive list, don't. Use filter instead.
