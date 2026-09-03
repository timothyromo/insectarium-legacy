# Legacy Site Content Reference — pulled from live pdxinsectarium.org

Compiled for the `insectarium-legacy` lift-and-shift build. Status marked per page: FULL (complete content captured), PARTIAL (some content only, needs a fresh live check), or NOT YET PULLED.

## ⚠️ Unresolved: Navigation inconsistency — verify live before building

Multiple direct fetches of the same URLs returned two different nav structures. My own direct fetches (About Us, Admission, Calendar, Services — done via `web_fetch`, not search snippets) consistently returned **Version A** below. But search-index snippets for the *same URLs* repeatedly returned **Version B**. This could mean the site was recently updated and search hasn't fully re-crawled, or something else entirely. Don't trust either version blindly — load 2-3 pages fresh in an actual browser and confirm which nav is currently live before building the nav structure.

**Version A (from my direct fetches):**
- Home
- Info: About us / FAQ about the insectarium / FAQ about bugs
- Visit: Calendar / Admission / Hours/Location / Summer Camp / Memberships
- Public Events
- Private Events and Field Trips: Events at the Insectarium / Off-site events / Photo shoots
- Get involved: Bug Club / Community
- Other: Shop / Services / Care Sheets (Jumping Spiders / Ghost Mantis / Isopods)

**Version B (from search-index snippets, same URLs):**
- Same as above, EXCEPT:
- Get involved: Bug Club / **Internships** / Community
- Other: Shop / **Donate** / Services / Care Sheets (...)

If Version B is actually current, there are two more pages to pull: **Internships** and **Donate** (URLs not yet confirmed — likely `/internships.html` and `/donate.html`, verify).

---

## Home — PARTIAL
Nav confirmed (Version A, live). Full homepage content not re-pulled here since it's already the basis of the *upgraded* build in `insectarium-web`; for the legacy replica, use the OLD Weebly homepage content/layout, not the new one. Worth a fresh direct look at pdxinsectarium.org root before building this page specifically, since it's the one place where "old vs new" matters most.

Known homepage element: an accessibility survey callout ("If you have visited us before, please fill out our accessibility survey!") — include this.

---

## About Us — FULL
URL: https://www.pdxinsectarium.org/about-us.html

> Portland Insectarium is a zoo and museum dedicated to insects, arachnids, and other arthropods. See and touch live and preserved bugs, engage in interactive activities, explore a curated selection of toys, games, and books. Connect with experts and fellow enthusiasts and join a vibrant community of bug lovers. We celebrate education, creativity, and curiosity!
>
> The Portland Insectarium was conceived in 2016 by Jessica Szabo and Molly Radany while taking a museum curation class at Portland State University after a discussion about the city's lack of a natural history museum. It is now co-owned by Jessica Szabo and Red Armstrong since 2025.
>
> We started doing public events in 2018 as a mobile/pop up insect zoo, museum, and educational experience. We hosted tea parties with live bugs, drink & draws at an art gallery, and visited classrooms and libraries all around Portland. We were unable to do events during COVID lockdown and so went on indefinite hold.
>
> After a 2 year break, in December 2021 we opened our first physical location next door to ExperimentPDX (http://www.experimentpdx.com) in the Buckman neighborhood. In September of 2022 we relocated to Sellwood and joined Milieu Collective (http://www.milieupdx.com) until the building was sold in March 2024. We now have our own space at 5429 N Moore Ave!

**Residents table:**
| Column 1 | Column 2 |
|---|---|
| 15+ tarantulas, 6 species of scorpions, exotic isopods, phasmids, millipedes, various mantises, darkling beetles, assassin bugs, other beetles, jumping spiders, vinegaroon, other spiders, 7 species of cockroaches and more! | Touchable bugs rotate — included with admission: hissing cockroaches, Dubia cockroaches, various darkling beetles, and superworms (beetle larvae). For an additional $5 per bug (staff discretion): mantis and stick/leaf insect for holding. Tarantula handling only during scheduled tarantula handling events or private parties/tours. |

**Contact Us block:**
> Please have patience as it may take several days for a response.
> [email protected]
> (833) 510-8419 — leave a voicemail, we will respond via text (no call backs unless scheduled via text or email).
> Check out our FAQ to see if your question is answered there.
> Instagram: instagram.com/pdxinsectarium
> Facebook: facebook.com/portlandinsectarium
> Discord: discord.com/invite/YBsSffBw
> Mailing list: pdxinsectarium.kit.com/74fb3ad6f8

**Team bios:**
> Jessica Szabo (founder/co-owner/educator, she/they) — Jessica is an arachnologist, photographer, illustrator, and science educator. They studied spider morphology, taxonomy, and ecology at Portland State University.
> Red Armstrong (co-owner/educator, they/he) — [bio text was cut off in the fetch, verify full text live]

**Press mentions (link list):**
- Portland Tribune
- Willamette Week
- KATU Curious Gallery
- On the Go with Joe
- KGW OMSI After Dark
- Oregonian
- Good Day Oregon
- Sellwood Bee

---

## FAQ about the insectarium — PARTIAL
URL: https://www.pdxinsectarium.org/faq-about-the-insectarium.html

Confirmed content snippet:
> What are your hours? Prices? — Please refer to the calendar for hours.
> Do you require masks? — We require masks on the second Saturday and third Thursday of each month. This is so our immunocompromised and covid-conscious guests can enjoy our space safely. We have masks available here for your convenience. If you or your child cannot wear a mask properly (mouth and nose covered), we ask that you visit on another day. On other days, masks are appreciated if you are sneezy, sniffling, or coughing (even if it's allergies).
> Is the insectarium wheelchair accessible? — [cut off, needs live pull]
> [Additional Q&A about handling fees: "When available, we charge $5 to hold mantises or leaf insects, however, they often need breaks, and when it's busy, the risk of them falling and getting stepped on is higher, so we can't guarantee they will be available at all times. Tarantulas are very sens[itive...]" — cut off]

**Needs a full direct pull, this page has more content than what surfaced here.**

---

## FAQ about bugs — NOT YET PULLED
URL: https://www.pdxinsectarium.org/faq-about-bugs.html

---

## Calendar — FULL
URL: https://www.pdxinsectarium.org/calendar.html

> Check here (links to Public Events) for more information about upcoming events. Click the "book now" button to purchase tickets.
> Our calendar is released on the 15th of each month to our mailing list subscribers and then on our website and socials within a week of the end of the month.
> **If Google or any other site has conflicting hours or location, please trust the information here on our website.**

**Cancellation Policy:**
> No refunds for no-shows for less than 24hr notice cancelations, full refund if canceled more than 3 days before your reservation, 50% refund if canceled within 1-3 days. We can also move your appointment to another day/time if you let us know before your appointment.

**Demonstration schedule intro:**
> To prioritize the health and well-being of our animals, we will now present certain species on a scheduled basis during general admission. Repeatedly opening enclosures, lifting hides, and exposing animals to light throughout the day can be stressful and disruptive to their natural behaviors. By offering set demonstration times, we're able to ensure a better experience for both animals and visitors. Demonstrations start at the half-hour, last about 10 minutes, and will not be repeated until the next day.

**Full demo schedule (note: this is the OLD static text-list version — the upgraded build already replaced this with the dynamic Animal Demos CPT; this is reference only for the legacy replica):**
- 10:30am (weekends only): Mantis demo — observe various mantises outside of their terrariums, watch a feeding demonstration.
- 11:30am: Mystery animal demo — we will show off an animal of our choosing (or yours!).
- 12:30pm: Venomous animal tour (starting 19 Aug) — learn about the most venomous animals at our bug zoo.
- 1:30pm (weekdays): Myriapod demo — pet a giant millipede, get a closer look at a centipede.
- 1:30pm (weekends): Phasmid demo — view up close and sometimes hold our stick and leaf insects.
- 2:30pm (weekdays): Jumping spider demo — explore our jumping spider collection, observe hunting and feeding behavior.
- 2:30pm (weekends): Spider tour — see some of our other true spiders (non-tarantulas), observe hunting and feeding behavior.
- 3:30pm: Mantis demo — observe various mantises outside of their terrariums, watch a feeding demonstration.
- 4:30pm (weekdays): Scorpion demo — see live scorpions up close and watch them light up under UV light! No handling. Not available on weekends.
- 5:30pm: Tarantula feeding — learn about tarantulas and observe a feeding demonstration. No handling.
- 6:30pm (weekends only): Arachnid tour — learn about and see different arachnids, including some you may have never heard of!

**Embed:** Google Calendar iframe — `https://calendar.google.com/calendar/embed?src=info%40pdxinsectarium.org&ctz=America%2FLos_Angeles`

Two images present (`calendar-41_orig.png`, `calendar-42_orig.png`) — pull directly from Weebly uploads if needed for the replica.

---

## Admission — FULL
URL: https://www.pdxinsectarium.org/admission.html

> 5429 N Moore Ave
> We encourage you to book your tickets ahead of time. We take walk-ins when we can, but to ensure there is space for your party, please book online using the "Book Now" button. Max capacity 10 people.
> If a time slot is locked or not available, we are either fully booked or closed and not taking walk-ins. Please do not show up without a ticket in this case, we will not be able to accommodate you.

**Cancellation Policy:** same text as Calendar page above.

**Pricing tables:**

Online booking (6% service fee), 45 min:
| Type | Price |
|---|---|
| Adults | $10 |
| Kids/students/seniors/SNAP | $8 |
| Thursday | $4 |

Walk-in admission, 45 min:
| Type | Price |
|---|---|
| Adults | $12 |
| Kids/students/seniors/SNAP | $9 |
| Thursday | $6 |

> Note that there is a service fee when booking online, which is why it's cheaper than walk-ins. By purchasing a ticket online, you are guaranteed a spot, but walk-ins may be asked to wait or come back later if we are fully booked (max capacity 10 people).
> **If Google or Apple Maps or any other site has conflicting hours or location, please trust the information on our website.**
> Kids under 2: FREE. Members: FREE.
> Please refer to the calendar for hours which may vary due to events.

**FareHarbor embed URL (full, with tracking params):**
`https://fareharbor.com/embeds/book/pdxinsectarium/?full-items=yes&u=248be6ab-bcba-4823-914e-757365415048&from-ssl=yes&...&back=https%3A%2F%2Fwww.pdxinsectarium.org%2Fpublic-events.html&language=en-us`
(Simplified version also seen site-wide: `https://fareharbor.com/embeds/book/pdxinsectarium/?full-items=yes`)

---

## Hours/Location — PARTIAL (nav only, no body content captured)
URL: https://www.pdxinsectarium.org/hourslocation.html

**Needs a full direct pull.** Only nav and footer surfaced in search snippets, no actual hours/address/map content came through. This is a page worth pulling fresh and carefully, since it's also the page targeted for the content expansion (parking, transit, accessibility, landmark notes) discussed earlier in planning.

---

## Summer Camp — NOT YET PULLED (nav only confirmed)
URL: https://www.pdxinsectarium.org/summer-camp.html

---

## Memberships — PARTIAL
URL: https://www.pdxinsectarium.org/memberships.html

Known from earlier in this project: purchased as a one-time FareHarbor item (not true recurring billing), perks applied manually (member enters a member number at checkout online, or tells staff in person — "discount is not automatic").

From store/product snippet: SKU-based product, $20.00–$160.00 range depending on tier, "per item." "Show us your receipt for membership on your first visit and you'll get a membership card."

**Needs a full direct pull** of the actual membership tiers/benefits text, this snippet only shows pricing mechanics, not what's actually included at each tier.

---

## Public Events — PARTIAL
URL: https://www.pdxinsectarium.org/public-events.html

**Policy text (appears to head the page):**
> READ BEFORE PURCHASING: No refunds for no-shows for less than 24hr notice cancelations, full refund if canceled more than 3 days before event, 50% refund if canceled within 1-3 days of event. We can also move your appointment to another day/time. If you arrive more than 15 min before a ticketed event, you will be charged regular zoo admission on top of the event ticket ($10 adults, $7 kids), or you can book the general admission time slot before ahead of time.

At least one confirmed event example on this page: **"Free Library Events"** (a category of free, non-ticketed events).

**Needs a full direct pull** — this page has the actual current event listings (individual event cards, some with FareHarbor links, some "More Info," per the earlier audit), which are time-sensitive and should be pulled as close to build time as possible so they're current.

---

## Private Events and Field Trips (parent: Events at the Insectarium) — NOT YET PULLED
URL: https://www.pdxinsectarium.org/private-events.html

Known from earlier in this project: page includes a warning not to use the site's global "Book Now" button, and directs to a Square Appointments embed at the bottom of the page for Field Trip Deposit / Photo Shoot Deposit / Private Pinning Class booking (per earlier screenshot, "Powered by Square").

---

## Off-site events — NOT YET PULLED
URL: https://www.pdxinsectarium.org/off-site-events.html

---

## Photo shoots — NOT YET PULLED
URL: https://www.pdxinsectarium.org/photo-shoots.html

---

## Bug Club — NOT YET PULLED
URL: https://www.pdxinsectarium.org/bug-club.html

---

## Community — NOT YET PULLED
URL: https://www.pdxinsectarium.org/community.html

---

## Shop — PARTIAL (from earlier in this project, not re-verified this session)
URL: https://www.pdxinsectarium.org/shop.html

Known: mix of Weebly-native store items (digital downloads, a generic donation product — processed via Square on the backend per Weebly/Square integration) and FareHarbor-linked gift card items (gift admission, gift classes/events). No physical merchandise appeared to be sold through this page as of the earlier audit.

---

## Services — FULL
URL: https://www.pdxinsectarium.org/services.html

**Insect Pinning:**
> For $20 we will pin and spread a dead bug for you. For an extra $15-20 (depending on size/type) we will mount it in a shadowbox. Email for more information [email protected]. If the specimen requires gutting and stuffing (large body) or repair there may be an extra charge. We are not able to do tarantulas or spiders, we refer you to Lilah at Of Moth and Flame (ofmothandflame.com) for this service.
> You can also book a private pinning class and we will teach you how to do it and provide all supplies.

**Pet Bug Sitting:**
> Going out of town and need someone to watch your pet bugs? Bring them to the insectarium and they will be well-cared for!
>
> For 1-2 small terrariums or one medium terrarium: $2/day, $12/week, $38/month
> For 3-5 small, 1-2 medium, or one large: $3/day, $18/week, $70/month
>
> Small: ≤6x6 inches or equivalent (less than one gallon)
> Medium: 6x6 to 12x12 inches or equivalent (up to 10 gallons)
> Large: anything larger than 12 inches on any side or over 10 gallons
>
> Email for more information [email protected]

**Tarantula Adoption Program:**
> We frequently receive tarantula donations/surrenders and are quickly running out of space! Instead of declining, we created a Tarantula Adoption Program. During your visit to the insectarium, you'll have the opportunity to meet tarantulas ready for adoption. We'll also keep an updated list of adoptable tarantulas here.
>
> There will be an adoption fee based on the tarantula's size and species, as well as an interview to ensure it's the right fit for you. Since tarantulas can live 20 years or more and we're committed to finding them forever homes.
>
> If interested in adopting, email [email protected] with: is the tarantula for yourself or someone else? If for someone else, are they under 18? Have you researched how to care for a tarantula? Are you hoping to handle your tarantula? Do you have a terrarium? Have you ever had a tarantula or other pet bugs before?

**Available for adoption (as of this pull — verify current before publishing, this is livestock-status data that changes):**
- Stripe-knee tarantula (*Aphonopelma seemanni*) — sex unknown, young, ~3" leg span, $30, temperament unknown, hides in burrow a lot
- Stripe-knee tarantula (*Aphonopelma seemanni*) — sex unknown, young, ~3" leg span, $30, a little defensive, sensitive

**Tarantula Donation info:**
> If you have a tarantula to donate email [email protected] with: name of tarantula, species, male/female/unknown, temperament (can they be handled, kick hairs readily, struck/bitten in defense — no weight on decision, just informational), approximate age/how long you've had them, approximate size/leg span, where acquired (pet store, breeder, etc.), why surrendering, are you including a terrarium or supplies.

---

## Donate — NOT YET PULLED (existence unconfirmed, see nav ambiguity note above)

---

## Internships — NOT YET PULLED (existence unconfirmed, see nav ambiguity note above)

---

## Care Sheets (parent page) — NOT YET PULLED
URL: https://www.pdxinsectarium.org/care-sheets.html

## Care Sheets: Jumping Spiders — NOT YET PULLED
URL: https://www.pdxinsectarium.org/jumping-spiders.html

## Care Sheets: Ghost Mantis — NOT YET PULLED
URL: https://www.pdxinsectarium.org/ghost-mantis.html

## Care Sheets: Isopods — NOT YET PULLED
URL: https://www.pdxinsectarium.org/isopods.html

---

## ADDENDUM — pulled after Claude Code hit Cloudflare/Wayback blocks on its own end

## FAQ about bugs — PARTIAL (upgraded from NOT YET PULLED)
URL: https://www.pdxinsectarium.org/faq-about-bugs.html

> Which spiders do I have to worry about in Oregon? — Realistically none, but if you want to talk about medically significant venom, the only one we have here is the western black widow. While black widows have venom more potent than a rattlesnake, they are incredibly shy and reluctant to bite. They are not even able to bite unless pressed up close to your skin as they have very tiny fangs that can't open very wide. Bites usually happen when they are stepped on, they are inside your shoe, or in a pile of wood where people may accidentally grab or squish them.
>
> Should I buy a mantis egg case at the nursery for natural pest control in my garden? — Here are a few options: Mantis or jumping spider: live about 1-2 years, cannot keep the... [cut off, needs a full live pull, there's more Q&A content on this page than surfaced here]

## Bug Club — mostly FULL (upgraded from NOT YET PULLED)
URL: https://www.pdxinsectarium.org/bug-club.html

> We get a lot of requests to volunteer at the insectarium, but due to labor laws, we cannot. Only nonprofits are allowed to have volunteers. If you would like to be involved at the insectarium, learn skills like animal husbandry, identification, museum curation, terrarium design, and more - join our bug club!

**Perks:**
- Free passes to the museum for yourself and guests
- Free lessons to learn how to pin insects, create animal habitats, handle live bugs, and more!
- Free or discounted tickets to events held by the Insectarium
- Special "behind the scenes" access to some of the museum's animals
- [more perks likely follow — cut off]

> Make an effort to participate in one activity per [cut off — likely a membership requirement, e.g. "per month" or "per quarter" — needs live confirmation]

**Note:** this page's nav snippet did NOT show Donate/Internships as separate items, consistent with my earlier direct fetches. Slight additional data point toward Version A nav being more likely current, though still not fully confirmed — recommend still checking live before finalizing.

## Recommendation for Claude Code

Given how much of this is still marked NOT YET PULLED or PARTIAL, and given Claude Code has demonstrated direct curl/fetch access to the live install throughout this project, the fastest path from here is likely: **use this file as a starting skeleton and structure guide (confirmed nav, confirmed policy text, confirmed pricing), then fetch the remaining/partial pages directly** rather than waiting on further manual relay through chat. Flag anything that comes back different from what's documented here, especially the nav question, before finalizing the theme's header/footer.
