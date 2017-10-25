function r (a) {
  if (window.location.href.search ("debug") > 0 ) {
    document.write ("<b><font color=red>");
  } // if
  document.write (a[Math.floor ((Math.random () * 10)) % a.length]);
  if (window.location.href.search ("debug") > 0 ) {
    document.write ("</font></b>");
  } // if
} // r

var immediately   = ["immediately", "at short notice", "away", "directly", "double-time", "forthwith", "hereupon", "in a New York minute", "in a flash", "in a jiffy", "in nothing flat", "instantaneously", "instanter", "instantly", "like now", "now", "now or never", "on the dot", "on the double", "on the spot", "promptly", "pronto", "rapidly", "right now", "shortly", "soon", "soon afterward", "straight away", "straight off", "summarily", "thereupon", "this instant", "this minute", "tout de suite", "unhesitatingly", "urgently", "without delay", "without hesitation"];
var remove        = ["remove", "abolish", "abstract", "amputate", "carry away", "carry off", "cart off", "clear away", "cut out", "delete", "depose", "detach", "dethrone", "dig out", "discard", "discharge", "dislodge", "dismiss", "displace", "disturb", "do away with", "doff", "efface", "eject", "eliminate", "erase", "evacuate", "expel", "expunge", "extract", "get rid of", "junk*", "oust", "pull out", "purge", "raise", "relegate", "rip out", "separate", "shed", "ship", "skim", "strike out", "take down", "take out", "tear out", "throw out", "transfer", "transport", "unload", "unseat", "uproot", "wipe out", "withdraw"];
var respect       = ["respect", "account", "adoration", "appreciation", "approbation", "awe", "consideration", "courtesy", "deference", "dignity", "esteem", "estimation", "favor", "fear", "homage", "honor", "obeisance", "ovation", "recognition", "regard", "repute", "reverence", "testimonial", "tribute", "veneration", "worship"]
var escalated     = ["escalated", "amplify", "ascend", "broaden", "climb", "enlarge", "expand", "extend", "grow", "heighten", "intensify", "magnify", "make worse", "mount", "raise", "rise", "scale", "step up", "widen"];
var satisfied     = ["satisfied", "appeased", "certain", "compensated", "contented", "convinced", "filled", "fulfilled", "gratified", "happy", "paid", "positive", "quenched", "requited", "sated", "satiated", "supplied"];
var accuracy      = ["accuracy", "accurateness", "carefulness", "certainty", "closeness", "definiteness", "definitiveness", "definitude", "efficiency", "exactitude", "exactness", "faultlessness", "incisiveness", "mastery", "meticulousness", "preciseness", "sharpness", "skill", "skillfulness", "strictness", "sureness", "truthfulness", "veracity", "verity"];
var uncomfortable = ["uncomfortable", "afflictive", "agonizing", "annoying", "awkward", "bitter", "cramped", "difficult", "disagreeable", "distressing", "dolorous", "excruciating", "galling", "grievous", "hard", "harsh", "ill-fitting", "incommodious", "irritating", "thorny", "torturing", "troublesome", "vexatious", "wearisome"];
var issues        = ["issues", "affair", "argument", "concern", "contention", "controversy", "matter", "matter of contention", "point", "point of departure", "problem", "puzzle", "question", "subject", "topic"];
var Personally    = ["Personally", "Alone", "By oneself", "Directly", "For one's part", "For oneself", "In one's own view", "In person", "In the flesh", "Individualistically", "Individually", "Narrowly", "On one's own", "Privately", "Solely", "Specially", "Subjectively"];
var compromising  = ["compromising", "adjust", "agree", "arbitrate", "compose", "compound", "concede", "conciliate", "find happy medium", "find middle ground", "go fifty-fifty", "make a deal", "make concession", "meet halfway", "negotiate", "play ball with", "settle", "split the difference", "strike balance", "trade off"];
var consider      = ["consider", "acknowledge", "allow for", "assent to", "chew over", "cogitate", "concede", "consult", "contemplate", "deal with", "deliberate", "dream of", "envisage", "examine", "excogitate", "favor", "flirt with", "grant", "inspect", "keep in mind", "look at", "meditate", "mull over", "muse", "perpend", "ponder", "provide for", "reason", "reckon with", "recognize", "reflect", "regard", "revolve", "ruminate", "scan", "scrutinize", "see", "see about", "speculate", "study", "subscribe to", "take into account", "take under advisement", "take up", "think out", "think over", "toss around"];
var solutions     = ["solutions", "Band-Aid", "clarification", "elucidation", "explanation", "explication", "key", "pay dirt", "quick fix", "result", "solving", "the ticket", "unfolding", "unraveling", "unravelment"];
var directly      = ["directly", "as a crow flies", "beeline", "dead", "direct", "due", "exactly", "plump", "precisely", "right", "slam bang", "slap", "smack", "smack dab", "straight", "straightly", "undeviatingly", "unswervingly", "without deviation"];
var negatively    = ["negatively", "abnormally", "adversely", "antagonistically", "antithetically", "asymmetrically", "conflictingly", "contradictorily", "contrarily", "contrastingly", "contrastively", "discordantly", "disparately", "dissimilarly", "distinctively", "divergently", "diversely", "hostilely", "in a different manner", "incompatibly", "incongruously", "individually", "negatively ", "nonconformably", "on the contrary", "on the other hand", "oppositely", "poles apart", "separately", "uniquely", "unorthodoxly", "unusually", "variously", "vice versa"];
var entitled      = ["entitled", "baptize", "call", "characterize", "christen", "denominate", "designate", "dub", "nickname", "style", "subtitle", "term", "title"];
var available     = ["available", "accessible", "achievable", "applicable", "at hand", "at one's disposal", "attainable", "come-at-able", "convenient", "derivable from", "feasible", "free", "getatable", "handy", "obtainable", "on deck", "on hand", "on tap", "open to", "possible", "prepared", "procurable", "purchasable", "reachable", "ready willing and able", "realizable", "securable", "serviceable", "up for grabs", "usable", "vacant"];
var team          = ["team", "aggregation", "band", "body", "bunch", "club", "company", "contingent", "duo", "faction", "foursome", "gang", "lineup", "organization", "outfit", "pair", "partners", "party", "rig", "sect", "set", "side", "span", "squad", "stable", "string", "tandem", "trio", "troop", "troupe", "unit", "workers", "yoke"];
var conditional   = ["conditional", "codicillary", "contingent", "depending on", "fortuitous", "granted on certain terms", "guarded", "iffy", "incidental", "inconclusive", "limited", "modified", "not absolute", "obscure", "provisional", "provisory", "qualified", "relative", "reliant", "relying on", "restricted", "restrictive", "subject to", "tentative", "uncertain", "with grain of salt", "with reservations", "with strings attached"];
var represents    = ["represents", "act as", "act as broker", "act for", "act in place of", "appear as", "assume the role of", "be", "be agent for", "be attorney for", "be proxy for", "betoken", "body", "buy for", "copy", "correspond to", "do business for", "emblematize", "embody", "enact", "epitomize", "equal", "equate", "exemplify", "exhibit", "express", "factor", "hold office", "imitate", "impersonate", "mean", "perform", "personify", "play the part", "produce", "put on", "reproduce", "sell for", "serve", "serve as", "show", "speak for", "stage", "stand for", "steward", "substitute", "typify"];
var implement     = ["implement", "apparatus", "appliance", "contraption", "contrivance", "device", "equipment", "gadget", "instrument", "machine", "utensil"];
var annoying      = ["annoying", "aggravating", "bothersome", "disturbing", "irritating", "troublesome", "vexatious"];
var complex       = ["complex", "circuitous", "complicated", "composite", "compound", "compounded", "confused", "conglomerate", "convoluted", "elaborate", "entangled", "heterogeneous", "knotty", "labyrinthine", "manifold", "mingled", "miscellaneous", "mixed", "mixed-up", "mosaic", "motley", "multifarious", "multiform", "multiple", "multiplex", "tangled", "tortuous", "variegated"];
var frustrated    = ["frustrated", "balked", "crabbed", "cramped", "crimped", "defeated", "discontented", "discouraged", "disheartened", "embittered", "foiled", "fouled up", "hung up on", "irked", "resentful", "stonewalled", "stymied", "through the mill", "ungratified", "unsated", "unslaked", "up the wall"];
var designed      = ["designed", "accomplish", "achieve", "arrange", "block out", "blueprint", "cast", "chart", "construct", "contrive", "create", "delineate", "describe", "devise", "diagram", "dope out", "draft", "draw", "effect", "execute", "fashion", "form", "frame", "fulfill", "invent", "lay out", "perform", "produce", "project", "set out", "sketch", "sketch out", "trace", "work out"];
var management    = ["management", "administration", "authority", "board", "bosses", "brass", "directorate", "directors", "employers", "execs", "executive", "executive suite", "executives", "front office", "head", "mainframe", "management", "micro management", "person upstairs", "top brass", "upstairs"];
var method        = ["method", "adjustment", "approach", "arrangement", "channels", "course", "custom", "design", "disposal", "disposition", "fashion", "form", "formula", "habit", "line", "manner", "mechanism", "method", "mode", "modus", "modus operandi", "nuts and bolts", "plan", "practice", "proceeding", "process", "program", "receipt", "recipe", "red tape", "ritual", "rote", "routine", "rubric", "rule", "rut", "schema", "scheme", "shortcut", "style", "system", "tack", "tactics", "technic", "technique", "tenor", "the book", "usage", "way", "ways and means", "wise", "wrinkle"];
var interface     = ["interface", "admix", "alloy", "ally", "coalesce", "combine", "come together", "compound", "consolidate", "fuse", "hook up with", "incorporate", "integrate", "interface ", "intermix", "join together", "meld", "merge", "mingle", "network", "pool", "team up", "tie in", "tie up", "unite"];