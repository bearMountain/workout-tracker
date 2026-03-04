I've recently gotten into weightlifting. Now I want to build an iOS native app to guide my workouts and track my progress. In Mentzer's style lifting you do low volume and high intensity and it's really important to track progress - even one rep improvement is important to track.

App should have section that has my two workout days - A day and B day.
It should list the goal weight and reps.
The user records what day they actually worked out, what their real numbers were, and how they felt.
Near the workouts, there should also be an area that has informative content - maybe notes that I've taken, maybe links to youtube videos or insta posts.

There should be some sort of calendar feature to know when your next exercise should be, but this can be very minimal b/c the scheduling is so simple - basically 1 workout every 7 days. E.g. "A" workout on a Saturday, then "B" workout on the next Saturday. But sometimes, you might be a day late and do the "B" workout on Sunday and it should be clear to you that your next workout should now be on the next Sunday.

Mike Mentzer's Heavy Duty High-Intensity Training (HIT) — a minimalist, science-backed approach to building muscle and strength with maximum efficiency and recovery. Workouts consist of just 2–3 ultra-intense compound exercises per session (e.g., squats/deadlifts, pulldowns, dips), performed as a single set to absolute muscular failure after warm-ups, with sessions spaced 7–10+ days apart to allow full systemic recovery and supercompensation. This low-volume, high-effort method prioritizes quality over quantity, progressive overload, and ample rest, making it ideal for naturals who want serious gains without endless gym time, overtraining, or joint wear — perfect for busy lifters seeking sustainable, logic-driven progress.

Design - I like:
- dark ui theme
- minimalist design
- flat design
- simple, consistent UI

Users:
- currently there is only 1 user - me. so we don't need to make it generic for many user's needs.

Architecture:
- Vercel for api - postgress for db