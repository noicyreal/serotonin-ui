# Notifications

[Guide](../README.md) · [API](API.md) · [ESP](ESP.md)

Square dark cards, thin borders, muted text, a colored status marker, and a slim lifetime indicator. Notifications animate into a corner stack, pause their timer on hover, and include a close button.

## Show a notification

```lua
local window = UI.new({
    Features = {Notifications = true},
    Notifications = {Position = "BottomRight", Width = 310, MaxVisible = 3, Duration = 5},
})
local notice, problem = window:Notify({
    Title = "Settings saved", Text = "Your configuration is ready.",
    Type = "Success", Duration = 5,
    OnClose = function(reason) print("Closed:", reason) end,
})
```

The notification GUI is lazy-created and remains visible when the menu is hidden. Destroying the window removes it.

## Window defaults

| Setting | Default | Valid values |
| --- | --- | --- |
| Features.Notifications | true | false disables creation/display. |
| Notifications.Position | BottomRight | BottomRight or TopRight. |
| Notifications.Width | 310 | 220–480 design pixels. |
| Notifications.MaxVisible | 3 | Integer 1–5. |
| Notifications.Duration | 5 | Nonnegative seconds; zero is persistent. |

The stack scales down on small screens. Cards are 86 pixels tall with 10-pixel gaps. Use a short title and roughly two lines of message text; longer text truncates to keep cards compact.

## Per-notification options

| Option | Default | Meaning |
| --- | --- | --- |
| Title | Notification | Heading. |
| Text | empty | Message. |
| Type | Info | Info, Success, Warning or Error; case-sensitive. |
| Duration | window default | Visible lifetime, excluding hover/entry animation; zero persists. |
| OnClose(reason) | nil | Runs once after ordinary dismissal/expiry. |

Types use blue info, green success, amber warning and red error accents with small status symbols. No sounds or external images are loaded.

## Update or dismiss

```lua
local notice = window:Notify({Title = "Working", Text = "Preparing settings…", Duration = 0})
-- When your operation completes:
if notice then
    notice:Update({Title = "Ready", Text = "Settings prepared.", Type = "Success", Duration = 4})
end
-- Or dismiss explicitly:
if notice then notice:Dismiss() end
```

Update merges/validates fields and returns true. Supplying Duration resets elapsed lifetime. Updating a closing/closed notice returns false. Dismiss is idempotent. `notice.Closed` becomes true after closure or owner destruction; `notice.Instance` exists once a queued card is displayed.

OnClose receives Timeout for expiry, Dismissed for button/default dismissal, or your custom reason from `Dismiss("MyReason")`. Owner destruction closes all handles immediately without running per-notification OnClose callbacks; use `window:OnDestroy` for owner cleanup.

## Queue and disabled behavior

At most MaxVisible cards display at once. Others wait in insertion order; their timers start on display. There is a cap of **32 total active/queued notices per window**. Full queues return `nil, "Notification queue is full (32)"`. Disabled notifications return `nil, "Notifications are disabled"`. Check handles before calling their methods.

One render connection runs while the window has pending notices and disconnects when drained. Persistent notices occupy a slot until dismissed; finish or dismiss them when the underlying operation ends.
