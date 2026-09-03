# Deviations from the live site

Every change made while replicating `pdxinsectarium.org` that is not a
byte-for-byte copy of the export is logged here.

| # | Page / area | Change | Reason |
|---|---|---|---|
| 1 | Header | Logo image is a stand-in from `insectarium-web/assets/images/logo.png` | Real Weebly header logo (`insectarium-logo-1.png`) not in export, apex domain blocked. Owner to supply exact file. |
| 2 | Footer | Search form rewired from /apps/search?q= to WP search (?s=) | Weebly search endpoint does not exist on WordPress. |
| 3 | Internal links (about-us, hourslocation, faq-about-the-insectarium, services, home) | 3 unmapped old page variants mapped redirect-only in slugmap.py: `faq.html` -> `/faq-about-the-insectarium`, `private-eventsparties.html` -> `/private-events`, `public-events1.html` -> `/public-events` | Old Weebly page variants with no dedicated page in the export; links now resolve to the current equivalent pages instead of dead .html URLs. |
| 4 | mma | "More info coming soon!" sentence in the Mini Museum Alliance body copy reviewed and kept verbatim | Genuine live body copy from the Weebly site, not a stand-in placeholder inserted by us. |
| 5 | shop | Storefront replaced with the export's intro copy + FareHarbor gift-card embeds + a prominent "Visit our shop" button linking to `@@SHOP_STORE_URL@@` (TODO for owner) | Weebly Store is a client-rendered app; its storefront markup is not in the static export. |
| 6 | donate | `donate.html` chosen as canonical `/donate`; `donate1.html` kept redirect-only | `donate.html` is the fuller/current copy (extra donation-options / Amazon Wish List box, "PayPal / Venmo / Cash App" section); `donate1.html` is an older duplicate missing that box and with slightly older wording ("The Portland Insectarium is not a nonprofit"). |
| 7 | live-bugs | Nested slugmap structure retained: Tarantulas / Scorpions / True Spiders / Other Arachnids stay as sub-pages of `/live-bugs` | The export's Live Bugs page lists them as child categories under an "Arachnids" section, confirming the hierarchy. |
