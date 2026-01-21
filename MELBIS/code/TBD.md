# Questions about MELBIS

- MELBIS v1 published on [COMSES](https://www.comses.net/codebases/b4a18765-2f65-4010-b19f-b32dbc23d8a6/releases/1.0.0/) is clearly different from the model presented in the [article](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0219188); should we use this one instead? it seems more refined.
- Set `choice1` (and others): the default set of patches (_i.e._ when condition is not verified) seem larger than the one when condition is true. I would have expected the set to be null (_i.e._ no patch macthing the `choice1` criteria)
- Settlement of immigrants is very strongly linked to predefined environmental context, _i.e._ number of ethnic residents defined by Census 2011. No update based on new immigrants settling on patch. This makes the model to converge very quickly.
- `satisifed?` flag does not seem to be used in code (except to plot % of satisfaction)
- Some thresholds are hard-coded, where do they come from?
    - `satisfied?` -> `count turtles-here <= 15`
    - `choice5` move -> `count turtles-here <= 2`
- Very little difference, if any, between set of `choice1` to `choice5`
- Ratio of residents vs. immigrants (67%/33%): justification ?
- How many actual households each agent represent? (-> `pFactor`)