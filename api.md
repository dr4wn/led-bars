
﻿<h1 align="center">👥led-bars-api-documentaion</h1>

## ✍️ Overview
This is the **official** FixtureAPI documentation for the dr4wn LED Bar fixtures. For specific sections, refer to the table of contents below.

### Table of Contents
- FAQ
	- [*How do I enable the FixtureAPI?*](#how-do-i-enable-the-fixtureapi)
	- [*How do I create a new button?*](#how-do-i-create-a-new-button)
	- [*How do I know which callback is which?*](#how-do-i-know-which-callback-is-which)
- [*FixtureAPI*](#fixtureapi)
	- [*Creating a callback*](#creating-a-callback)
	- [*Demo*](#demo)
- [*API Usage*](#api-usage)
	- [*Dimmer*](#dimmer)
	- [*Effects*](#effects)
		- [*Reference Names*](#reference-names)
		- [*Effect Names*](#effect-names)
	- [*Color*](#color)
	- [*Position*](#position)
	- [*BPM*](#bpm)
	- [*Phase*](#phase)
	- [*Fade*](#fade)
	- [*Spot*](#spot)
	- [*Reset*](#reset)
- [*Bugs or additions*](#bugs-or-additions)
- [*Credits*](#credits)
- [*License*](#license) 
<br><sub>some links may be broken, we're sorry!</sub>

## 💭 FAQ

### How do I enable the FixtureAPI?
In order to enable the API, path to `product > configuration > configuation.lua` and look for the `usingApi` variable. From there, change the value to `true`.

View the [path example](./content/path-to-configuration.gif) and the [change example](./content/change-api-status.gif) if you are having trouble finding your way.

### How do I create a new button?
In the `configuration.lua` file, scroll until you find `customButtons`. There will be three examples provided for you, aswell as an example containing all the editable properties we have provided you. Keep in mind, all of the stylistic properties such as `textColor`, `strokeColor`, etc are optional, and the properties such as `name`, `onClick`, and `link` have required fields.

View the [creation example](./content/create-new-button.gif) if you are having trouble creating a new textbutton.

```lua
{
	name = "name",
	link = "cueLink",
	onClick = {"MouseButton1Click"},
	textColor = Color3.new(1, 1, 1),
	strokeColor = Color3.new(1, 1, 1),
	textTransparency = 0,
	strokeTransparency = 0,
},
```
<sub>This is an example of a custom button.</sub>

### How do I know which callback is which?
In this product, callbacks are **index** based, meaning whatever mouse callback is provided will create an invisible bond with the callback that is on the server.

Example:
```lua
-- stripped down button
onClick = {
	[1] = "MouseButton1Down",
	[2] = "MouseButton1Up"
}
-- server callback
{
	function()
		print("callback for MouseButton1Down")
	end,
	function()
		print("callback for MouseButton1Up")
	end
}
```
<sub>Comparison of onClick{} vs .connectCallback() registration.</sub>


If there is no matching callback *(e.g. out of bounds)*, then an error will be thrown. This error is non-instrusive and will only be thrown if the missing callback is ran.


## FixtureAPI
A FixtureAPI allows representation of direct interfacing with the product itself through a script provided to the user.

### Creating a callback
identifier: `string` | `number` <sub><span style="color:orange">required</span></sub> <sub><span style="color:green">free</span></sub><br>
callbacks: `table` <sub><span style="color:orange">required</span></sub> <sub><span style="color:green">strict</span></sub><br>

```lua
ApiObject.connectCallback(identifier, callbacks { ... })
```
<sub>Barebones example of linking a button to callbacks.</sub>

### Demo
```lua
local initialTime = os.time()

local FixtureAPI = require(...)
repeat task.wait() until FixtureAPI.enabled

local initializationTime = os.time() - initialTime
print(`Initialized! Took {initializationTime}s.`)

FixtureAPI.connectCallback("Cue", {
	function()
		FixtureAPI.setEvent("dimmer", { func = "Power", mouseButton = "MouseButton1Click", lightOn = true })
	end
})
```

# API Usage
<details>

## Dimmer
<details>  
<summary>Dimmer Button Table</summary>
    
| func          | mouseButton      | lightOn  |
| ------------- | ---------------- | -------- |
| **Power**     | MouseButton1Down | true     |
|               | MouseButton2Down | false    |
|               | MouseButton1Up   | false    |
|               |                  |          |
| **Fade In**   | MouseButton1Down | true     |
|               |                  |          |
| **Fade Out**  | MouseButton1Down | false    |
|               |                  |          |
| **Pulse A/B** | MouseButton1Down | false    |
|               | MouseButton2Down | false    |
|               |                  |          |
| **Fade A/B**  | MouseButton1Down | true     |
|               | MouseButton2Down | true     |
|               | MouseButton1Up   | false    |
|               | MouseButton2Up   | false    |
|               |                  |          |
| **Hold A/B**  | MouseButton1Down | true     |
|               | MouseButton2Down | true     |
|               | MouseButton1Up   | false    |
|               | MouseButton2Up   | false    |
|               |                  |          |
| **Hold L/R**  | MouseButton2Down | true     |
|               | MouseButton1Down | true     |
|               | MouseButton1Up   | false    |
|               | MouseButton2Up   | false    |

Please refer to the example below for further clarification. <br> 
---
Refer to the chart to implement different functionality. In order to see what mouse button click does what, interface with the panel directly before choosing your `mouseButton` field.
```lua
ApiObject.setEvent("dimmer", { func = "Power", mouseButton = "MouseButton1Down", lightOn = true })
```

</details>

## Effects
Due to the nature of how the carousel was programmed, interfacing with effects is not as simple as one may imagine, and you will need to refer to a table in order to correctly write the name down.

In the effects pool, there is an incremental value in the top right of every effect button. This number does not represent the number of the effect, but rather the number *minus* three, so you will have to account that into any effect you are trying to toggle.

Additionally, there is an alphabetical value at the beginning of every effect, starting at a & ending at z.

### Reference Names
```lua
"a_Random Strobe", "b_Random Fade", "c_Strobe", "d_Effect_1" "e_Effect_2", "f_Effect_3", "g_Effect_4", "h_Effect_5", "i_Effect_6", "j_Effect_7", "k_Effect_8", "l_Effect_9", "m_Effect_10", "n_Effect_11", "o_Effect_12", "p_Effect_13", "q_Effect_14", "r_Effect_15", "s_Effect_16", "t_Effect_17", "u_Effect_18", "v_Effect_19", "w_Effect_20", "x_Effect_21", "y_Effect_22", "z_Effect_23" 
```
<sub>Pathing directly to the button within the panel is an option, but this option makes it easier. This only applies to "buttonReference."</sub>

### Effect Names
```lua
"Random Strobe", "Random Fade", "Strobe" "Effect_1", "Effect_2", "Effect_3", "Effect_4", "Effect_5", "Effect_6", "Effect_7", "Effect_8", "Effect_9", "Effect_10", "Effect_11", "Effect_12", "Effect_13", "Effect_14", "Effect_15", "Effect_16", "Effect_17", "Effect_18", "Effect_19", "Effect_20", "Effect_21", "Effect_22", "Effect_23" 
```
<sub>All "Effect_x" names carry the same naming mechanism. This only applies to "effectName."</sub>

**Example Below**:
```lua
ApiObject.setEvent("effect", {
	effects = {
		{
			effectName = "Random Strobe",
			buttonReference = "a_Random Strobe",
			on = true
		},
		{
			effectName = "Effect_1",
			buttonReference = "d_Effect_1",
			on = true
		},
	}
})
```

## Color
**IMPORTANT** Syntax is very different and very meticulous due to the nature of how __bad__ things can go if they are not replicated correctly. In order to do even/odd patterns you will need to send separate commands.

colorMode: `string` <sub><span style="color:orange">required</span></sub> <sub><span style="color:green">strict</span></sub><br>
color: `Color3` <sub><span style="color:orange">required</span></sub> <sub><span style="color:green">strict</span></sub><br>

Available modes to set for `colorMode` are `all`, `even`, and `odd`.

```lua
ApiObject.setEvent("color", { colorMode = "all", Color3.new(1, 1, 1)})
```

To create an even/odd color, follow this mechanism:
```lua
ApiObject.setEvent("color", { colorMode = "even", Color3.new(1, 0, 1)})
ApiObject.setEvent("color", { colorMode = "odd", Color3.new(0, 1, 0)})
```

## Position
Allows for the manipulation of various bpm  values. Available bpm values that can be controlled are `dimmer`, `movement`, & `color`.

positionIndex `number` <sub><span style="color:orange">required</span></sub> <sub><span style="color:green">strict</span></sub><br>


```lua
ApiObject.setEvent("position", positionIndex)
```

## ColorFX
Allows for the manipulation of several effects within the `color` category.

color `Color3` <sub><span style="color:orange">required</span></sub> <sub><span style="color:green">strict</span></sub><br>


```lua
ApiObject.setEvent("colorfx", color)
```

## BPM
Allows for the manipulation of various bpm  values. Available bpm values that can be controlled are `dimmer`, `movement`, & `color`.

valueName: `string` <sub><span style="color:orange">required</span></sub> <sub><span style="color:green">strict</span></sub><br>
value: `number` <sub><span style="color:orange">required</span></sub> <sub><span style="color:green">strict</span></sub>

```lua
ApiObject.setEvent("bpm", { valueName = name, value = value })
```

## Phase
Allows for the manipulation of various phase values. Available phase values that can be controlled are `dimmer`, `movement`, & `color`.

phaseName: `string` <sub><span style="color:orange">required</span></sub> <sub><span style="color:green">strict</span></sub><br>
value: `number` <sub><span style="color:orange">required</span></sub> <sub><span style="color:green">strict</span></sub>

```lua
ApiObject.setEvent("phase", { phaseName = name, value = value })
```

## Fade
This function allows you to modify the fade time of the fixture, controlling the speed at which transitions between different states occur.

value: `number` <sub><span style="color:orange">required</span></sub> <sub><span style="color:green">strict</span></sub>

```lua
ApiObject.setEvent("fade", { value = value })
```

## Spot
This feature provides the ability to enable or disable the spotlight functionality within the fixture.

spotValue: `boolean` <sub><span style="color:orange">required</span></sub> <sub><span style="color:green">strict</span></sub>

```lua
ApiObject.setEvent("spot", spotValue)
```

## Reset
This resets the entire fixture, restoring it to its default state.

```lua
ApiObject.setEvent("reset")
```
</details>

## 
# 👾Bugs or Additions
 
 If there are any pressing matters / additions, please report them to the [issues page](https://github.com/dr4wn/fixture-api-docs/issues). Please be realistic with yourself regarding priority *(is this really needed?, will it take long?, can i do this through another method in the product?, etc.)* & we'll make sure to get back to you as soon as possible. 
 
 
# ✍️Credits
 
 [drawn](https://github.com/dr4wn) - Programming, interface, document writing, product development, etc.<br>
 [FinnyFrang](https://roblox.com/profile/1) - Product models & visualiaztion
 
