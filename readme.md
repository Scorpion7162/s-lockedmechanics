<div id="top">

<div align="center">

# S-LOCKEDMECHANICS

<em>Lock JG Mechanic shops behind vehicle class, vehicle model and job/gang requirements</em>

<img src="https://img.shields.io/github/last-commit/Scorpion7162/s-lockedmechanics?style=flat&logo=git&logoColor=white&color=0080ff" alt="last-commit">
<img src="https://img.shields.io/github/languages/top/Scorpion7162/s-lockedmechanics?style=flat&color=0080ff" alt="repo-top-language">
<img src="https://img.shields.io/badge/Lua-2C2D72.svg?style=flat&logo=Lua&logoColor=white" alt="Lua">

</div>
<br>

---

## Table of Contents

- [Overview](#overview)
- [Requirements](#requirements)
- [How it works](#how-it-works)
- [Installation](#installation)
- [Configuration](#configuration)
  - [config/cl.lua](#configcllua-client-facing)
  - [config/sv.lua](#configsvlua-server-only)
  - [Vehicle rules](#vehicle-rules)
  - [Vehicle classes](#vehicle-classes)
  - [Group locks](#group-locks)
- [Upgrading from v1](#upgrading-from-v1)
- [Security notes](#security-notes)
- [Testing](#testing)
- [Acknowledgements](#acknowledgements)

---

## Overview

JG Mechanic gates a shop by location and job. This resource adds a second gate in front of it,
so a single server can run several mechanic shops that each accept a different set of vehicles.

- **Multiple shops.** As many as you like, each with its own rules and its own access points.
- **Per-shop vehicle rules.** Ban or allow by vehicle class, by vehicle model, or both.
- **Per-shop group locks.** Restrict a shop to one or more jobs/gangs, with an optional
  minimum grade.
- **Multiple locations per shop.** One shop, several doors, one set of rules.
- **Per-shop interaction.** `ox_target`, `qb-target`, or an ox_lib zone with an `[E]` prompt.
- **Per-shop messages.** Override any rejection message for flavour.
- **Server-authoritative.** Every check runs on the server, which opens the JG menu itself
  once they pass. The mechanic id lives only in server-side config.

---

## Requirements

- [ox_lib](https://github.com/CommunityOx/ox_lib)
- [jg-mechanic](https://jgscripts.com/scripts/mechanic)
- OneSync enabled, server build 7290 or newer
- Optional: `ox_target` or `qb-target`, depending on the `interaction` you pick

---

## How it works

JG Mechanic opens its menu with a client event:

```lua
TriggerEvent("jg-mechanic:client:open-customisation-menu", mechanicId, mechanicLabel)
```

Anyone who knows `mechanicId` can fire that event and skip straight into the menu. So the
recommended setup is:

1. In `jg-mechanic/config/config.lua`, give the mechanic a long unguessable key and put its
   coordinates somewhere players cannot reach, so JG's own zone never triggers.
2. Put that same key in this resource's `config/sv.lua` as `mechId`.
3. Put the real, reachable coordinates in this resource's `config/cl.lua`.

The client asks the server for access. The server checks the group, the distance and the
vehicle, and if everything passes it opens the JG menu for that player itself. The `mechId`
lives only in `config/sv.lua`, so a player who dumps the client files finds shop keys and
coordinates they can already see in game, and nothing else.

```
player interacts
      |
      v
client  --(shopKey, vehicleClass)-->  server
                                        |  shop exists?  rate limit?  in a vehicle?
                                        |  close enough?  right group?  right vehicle?
                                        v
                                      server  --TriggerClientEvent-->  jg-mechanic
```

---

## Installation

1. Drop the resource into your `resources` folder.
2. `ensure s-lockedmechanics` in your `server.cfg`, after `ox_lib` and `jg-mechanic`.
3. Edit `config/cl.lua` and `config/sv.lua`. **Shop keys must match between the two files** -
   the server prints a warning at startup if they do not.

---

## Configuration

Config is split across two files by who is allowed to see the data.

| File | Loaded by | Put here |
| --- | --- | --- |
| `config/cl.lua` | client **and** server | coordinates, prompt text, interaction type |
| `config/sv.lua` | server only | mechanic ids, group locks, vehicle rules, messages |

`config/sv.lua` is not listed in `files{}` and is in no script list, so a client cannot download
it. Anything you want kept from players goes there.

### `config/cl.lua` (client-facing)

```lua
return {
    debug = false,          -- draw the interaction zones
    notify = 'ox_lib',      -- ox_lib | qb | esx | mythic | okok

    shops = {
        bennys = {
            interaction = 'zones',        -- zones | ox_target | qb-target
            label = 'Access Mechanic',
            interactDistance = 3.0,
            locations = {
                vec3(-211.0, -1324.0, 30.9),
            },
        },
    },
}
```

### `config/sv.lua` (server only)

```lua
return {
    framework = 'auto',     -- auto | qbx | qb | esx | standalone

    locale = {
        noPermission    = "You don't have permission to use this mechanic",
        classNotAllowed = "We don't work on that kind of vehicle here",
        classBanned     = "We don't work on that kind of vehicle here",
        modelBanned     = "We don't work on that model here",
        notInVehicle    = 'You need to be in a vehicle',
        tooFar          = 'You are too far from the mechanic',
        cooldown        = 'Please wait before trying again',
        invalidVehicle  = 'Invalid vehicle',
    },

    classOverrides = {},    -- see "Security notes"

    shops = {
        bennys = {
            mechId = 'yourhiddenjgmechanickey',
            mechLabel = 'Bennys',
            accessDistance = 5.0,   -- server tolerance, keep >= interactDistance
            cooldown = 2000,        -- ms between attempts, per player

            groups = {},            -- {} or nil = open to everyone

            allowedClasses = {},
            bannedClasses  = { 'motorcycle' },
            allowedModels  = {},
            bannedModels   = {},

            locale = {},            -- optional per-shop message overrides
        },
    },
}
```

### Vehicle rules

Each shop has four optional lists. Leave a list empty for no restriction. Rules are evaluated
top to bottom and the first match wins:

| # | Check | Result |
| --- | --- | --- |
| 1 | model is in `bannedModels` | denied |
| 2 | model is in `allowedModels` | **allowed**, class rules skipped |
| 3 | no class rules configured | allowed |
| 4 | class could not be trusted | denied |
| 5 | `allowedClasses` is set and the class is not in it | denied |
| 6 | class is in `bannedClasses` | denied |
| 7 | otherwise | allowed |

Because of rule 2, `allowedModels` is an **exemption** list rather than a whitelist. It carves
specific models out of a class ban. To whitelist, use `allowedClasses`.

```lua
-- everything except motorcycles, but the Bati is fine
bannedClasses = { 'motorcycle' },
allowedModels = { 'bati' },

-- sports and supercars only, but never the Adder
allowedClasses = { 'sports', 'sports classics', 'super' },
bannedModels   = { 'adder' },
```

Classes accept a name (`'motorcycle'`) or an id (`8`). Models accept a name (`'bati'`) or a
hash (`` `bati` ``). Unknown class names are reported at startup rather than silently ignored.

### Vehicle classes

| id | name | | id | name | | id | name |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 0 | compacts | | 8 | motorcycles | | 16 | planes |
| 1 | sedans | | 9 | offroad | | 17 | service |
| 2 | suvs | | 10 | industrial | | 18 | emergency |
| 3 | coupes | | 11 | utility | | 19 | military |
| 4 | muscle | | 12 | vans | | 20 | commercial |
| 5 | sports classics | | 13 | cycles | | 21 | trains |
| 6 | sports | | 14 | boats | | 22 | open wheel |
| 7 | super | | 15 | helicopters | | | |

> **Note for v1 users:** v1's class table had **5 and 6 the wrong way round** and was missing 22
> entirely. If you listed `'sports'` in v1 you were actually matching Sports Classics. Re-check
> your lists after upgrading.
>
> There is also no `'bike'` alias any more. It reads as motorcycles but meant class 13 in v1,
> so it now warns at startup. Write `'motorcycle'` (class 8) or `'cycles'` (class 13).

### Group locks

```lua
groups = {
    mechanic = 0,   -- any grade
    ballas   = 2,   -- grade 2 or higher
}
```

Matched against the player's **job or gang**. Grade `0` means any grade. An empty table or `nil`
means the shop is open to everyone.

| Framework | Matched against |
| --- | --- |
| qbx, qb | job **and** gang |
| esx | job only |
| standalone | no job system, so group locks cannot be enforced and everyone is allowed |

---

## Upgrading from v1

v2 is a breaking config change. `shared/Config.lua` and `shared/utils.lua` are gone; delete them
if you are updating in place rather than replacing the folder.

| v1 key | v2 home |
| --- | --- |
| `Config.Debug` | `config/cl.lua` -> `debug` |
| `Config.Framework` | `config/sv.lua` -> `framework` |
| `Config.Notify` | `config/cl.lua` -> `notify` (this was never actually read in v1) |
| `Config.Interaction` | `config/cl.lua` -> per shop `interaction` |
| `Config.Location` | `config/cl.lua` -> per shop `locations` (now a list) |
| `Config.Distance` | split into `interactDistance` (cl) and `accessDistance` (sv) |
| `Config.MechId` | `config/sv.lua` -> per shop `mechId` |
| `Config.MechLabel` | `config/sv.lua` -> per shop `mechLabel` |
| `Config.CooldownTime` | `config/sv.lua` -> per shop `cooldown` |
| `Config.GroupLocked` | removed; an empty `groups` table means unrestricted |
| `Config.GroupName` | `config/sv.lua` -> per shop `groups = { name = minGrade }` |
| `Config.UseClass` | removed; class and model rules now work together |
| `Config.LockedClass` | `allowedClasses` to keep v1's behaviour, `bannedClasses` for what the name implied |
| `Config.VehicleModelHash` | `bannedModels`, or `allowedClasses` plus `bannedModels`. **Not** `allowedModels`, see below |

Both v1 keys were named like ban lists but implemented as **allow** lists, so read this before
copying values across.

`Config.LockedClass` maps cleanly: it was a class whitelist, and `allowedClasses` is a class
whitelist. Use `bannedClasses` instead if v1 was doing the opposite of what you wanted.

`Config.VehicleModelHash` does **not** map cleanly. In v1 it was a strict model whitelist: set
it, and every model not on the list was refused. v2 has no equivalent, because `allowedModels`
is an exemption list that only ever allows and never denies. Moving
`VehicleModelHash = {`adder`}` straight to `allowedModels = { 'adder' }` would silently open the
shop to **every vehicle in the game**. Express the restriction with `allowedClasses` to narrow
the field and `bannedModels` to remove specific models, or open an issue if you need a true
model whitelist back.

`Config.Distance` was also declared twice in v1, so the second value (10.0) silently won and
zones were built far larger than the first value suggested. Set `interactDistance` to the radius
you actually want.

---

## Security notes

**What is protected.** Mechanic ids, group names, grades, cooldowns and vehicle rules live in
`config/sv.lua` and are never shipped to clients. Every check runs on the server, deriving the
player from `source` rather than anything the client sends. An unknown shop key is rejected
without a notification, and still costs the sender a cooldown, so the callback cannot be spammed
or used to probe for valid keys.

On success the server calls `TriggerClientEvent` for the JG menu rather than returning the id,
so the client never has to hold or forward it. Be aware this is not a guarantee the id can never
be observed: it is still an event argument arriving on that player's machine, so a client with
an event hook can read it. What the design guarantees is that it is only ever sent to a player
who has already passed every check, and that it is never present in a file clients download.

**Model rules are absolute.** `GetEntityModel` is a server native, so `allowedModels` and
`bannedModels` cannot be spoofed.

**Class rules have one limitation.** `GetVehicleClass` is a client-only native, so the class is
reported by the client. The server cross-checks it against `GetVehicleType`, which is
server-trusted, and rejects anything inconsistent, a motorcycle cannot claim to be a supercar,
and a boat cannot claim to be a helicopter. What the server cannot detect is a lie **within** the
same vehicle type, such as a muscle car claiming to be a supercar.

If a specific model matters, pin it server-side and the client's claim is ignored entirely:

```lua
classOverrides = {
    [`futo`]  = 4,   -- always treated as muscle
    [`adder`] = 7,   -- always treated as super
}
```

Or use `bannedModels` / `allowedModels`, which are always authoritative.

---

## Testing

Verified before release with:

- `luac -p` over every Lua file.
- A behavioural harness that loads the real `server/*.lua` against stubbed FiveM natives and
  drives the access callback through 51 assertions, run against the shipped config: the full
  rule matrix, the `allowedModels` exemption, `classOverrides` beating a lying client, cross-type
  class forgery, multi-location matching, cooldown expiry, per-shop locale overrides, rule
  isolation between shops, forged payload types, and group/grade checks across qbx, qb, esx and
  standalone.
- A broken-config run confirming the startup validator reports every seeded fault.

The harness is kept out of the resource so server owners are not shipped a test runner.

If you are changing rules on a live server, the checks worth repeating in game are: a banned
class, a banned model, a model exemption from a banned class, a player below `minGrade`, being
on foot, being out of range, and each `interaction` mode you use.

---

## Acknowledgements

- `James (and gryff, they're one person) @ JG`, `Linden @ Ox`, `Zoo/Antond/ESK0 @ Community Ox`

---

This resource is not affiliated with JG Scripts. Please open a GitHub issue here rather than
contacting JG about it.

Licensed under the GNU General Public License v3.0.

<div align="left"><a href="#top">Return to top</a></div>
