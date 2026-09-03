"""Canonical old-file -> WordPress-path map. Imported by extract.py and (via a
generated file) by seed.sh."""

# slug -> (export filename, wp path, parent slug or None)
PAGES = {
    "home":        ("index.html",                          "/",                              None),
    "about-us":    ("about-us.html",                        "/about-us",                      None),
    "faq-about-the-insectarium": ("faq-about-the-insectarium.html", "/faq-about-the-insectarium", None),
    "faq-about-bugs": ("faq-about-bugs.html",               "/faq-about-bugs",                None),
    "calendar":    ("calendar.html",                        "/calendar",                      None),
    "admission":   ("admission.html",                       "/admission",                     None),
    "hourslocation": ("hourslocation.html",                 "/hourslocation",                 None),
    "summer-camp": ("summer-camp.html",                     "/summer-camp",                   None),
    "memberships": ("memberships.html",                     "/memberships",                   None),
    "public-events": ("public-events.html",                 "/public-events",                 None),
    "private-events": ("private-events.html",               "/private-events",                None),
    "off-site-events": ("off-site-events.html",             "/off-site-events",               None),
    "photo-shoots": ("photo-shoots.html",                   "/photo-shoots",                  None),
    "bug-club":    ("bug-club.html",                        "/bug-club",                      None),
    "community":   ("community.html",                       "/community",                     None),
    "shop":        ("shop.html",                            "/shop",                          None),
    "services":    ("services.html",                        "/services",                      None),
    "care-sheets": ("care-sheets.html",                     "/care-sheets",                   None),
    "jumping-spiders": ("jumping-spiders.html",             "/care-sheets/jumping-spiders",   "care-sheets"),
    "ghost-mantis": ("ghost-mantis.html",                   "/care-sheets/ghost-mantis",      "care-sheets"),
    "isopods":     ("isopods.html",                         "/care-sheets/isopods",           "care-sheets"),
    "donate":      ("donate.html",                          "/donate",                        None),
    "internships": ("internships.html",                     "/internships",                   None),
    "mma":         ("mma.html",                             "/mma",                           None),
    "live-bugs":   ("live-bugs.html",                       "/live-bugs",                     None),
    "tarantulas":  ("tarantulas.html",                      "/live-bugs/tarantulas",          "live-bugs"),
    "scorpions":   ("scorpions.html",                       "/live-bugs/scorpions",           "live-bugs"),
    "true-spiders": ("true-spiders.html",                   "/live-bugs/true-spiders",        "live-bugs"),
    "other-arachnids": ("other-arachnids.html",             "/live-bugs/other-arachnids",     "live-bugs"),
}

BUILD_ORDER = [
    "home", "about-us", "faq-about-the-insectarium", "faq-about-bugs", "calendar",
    "admission", "hourslocation", "summer-camp", "memberships", "public-events",
    "private-events", "off-site-events", "photo-shoots", "bug-club", "community",
    "shop", "services", "care-sheets", "jumping-spiders", "ghost-mantis", "isopods",
    "donate", "internships", "mma", "live-bugs", "tarantulas", "scorpions",
    "true-spiders", "other-arachnids",
]

# extra redirect-only sources (old file -> wp path)
REDIRECT_ONLY = {
    "donate1.html": "/donate",
    "info.html": "/about-us",
    "visit.html": "/calendar",
    "get-involved.html": "/bug-club",
    "other.html": "/shop",
    "private-events-and-field-trips.html": "/private-events",
    "home.html": "/",
    "home1.html": "/",
}

def html_to_path(name):
    """foo.html (any of the known files) -> wp path, or None if unknown."""
    name = name.strip().lstrip("/").split("?")[0].split("#")[0]
    for slug, (fn, path, _parent) in PAGES.items():
        if fn == name:
            return path
    return REDIRECT_ONLY.get(name)
