--[[
===================================================================================
MIT License

Copyright (c) 2023 Essential Video Editing (www.youtube.com/@EssentialVideoEditing)

Permission is hereby granted, free of charge, to any person obtaining a copy of 
this software and associated documentation files (the “Software”), to deal in the 
Software without restriction, including without limitation the rights to use, copy, 
modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, 
and to permit persons to whom the Software is furnished to do so, subject to the 
following conditions:

The above copyright notice and this permission notice shall be included in all 
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION 
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

===================================================================================
This script auto generates Essential Active Captions from a subtitle track. 

Follow these steps to run this script:

1.Copy script file "Essential Active Caption - Copy Subtitles.lua" to folder:
  Windows:
  	C:\Users\{username}\AppData\Roaming
	\Blackmagic Design\DaVinci Resolve\Support\Fusion\Scripts\Utility
  Mac OS: 
 	Macintosh HD/Users/{username}/Library/Application Support
	/Blackmagic Design/DaVinci Resolve/Fusion/Scripts/Utility

2.In DaVinci Resolve, open the timeline with the subtitle track.
3.Add Essential Active Caption to the timeline.
4.Adjust the caption styles and animation effects.
5.Drag the caption clip to current Media Pool Bin. 
6.Run the script from the main menu to import titles in .srt file. 
  Workspace->Scripts->Essential Active Caption - Copy Subtitles
7.In the dialog window, enter index of the subtitle track, click OK.
8.Active captions will be created automatically in a new track.

===================================================================================
YouTube: https://www.youtube.com/@EssentialVideoEditing
BuyMeACoffe: https://www.buymeacoffee.com/essentialvideo
PayPal: https://www.paypal.com/paypalme/essentialvideo

Thank you for your support, enjoy!
===================================================================================
--]]

local subtitleTrack = 1

local ui = app.UIManager
local dispatcher = bmd.UIDispatcher(app.UIManager)

local projectManager = resolve:GetProjectManager()
local project = projectManager:GetCurrentProject()
local mediaPool=project:GetMediaPool()


local function create_window()
    local window_flags = nil

	if ffi.os == "Windows" then
		window_flags = 	
		{
			Window = true,
			CustomizeWindowHint = true,
			WindowCloseButtonHint = true,
		}
	elseif ffi.os == "Linux" then
		window_flags = 
		{
			Window = true,
		}
	elseif ffi.os == "OSX" then
		window_flags = 
		{
			Dialog = true,
		}
	end

    local window = dispatcher:AddDialog(
    {
        ID = "CopySubtitleDialog",
        WindowTitle = "Essential Active Caption - Copy Subtitles",
        WindowFlags = window_flags,
        WindowModality = "ApplicationModal",
        Events = { Close = true, KeyPress = true },

		ui:VGroup
		{
			Weight = 1,
			MinimumSize = { 430, 90 },
			MaximumSize = { 430, 90 },

			ui:VGap(1),

			ui:HGroup
			{
				ui:Label { Text = "Subtitle Track:", MinimumSize={90,0}, MaximumSize={90,200} },  
				ui:LineEdit { ID = "subtitleTrack", Text = subtitleTrack .. '' }, 
			},

			ui:VGap(10),
			
			ui:HGroup
			{
				ui:HGap(0,1),

				ui:Button
				{
					ID = "CancelButton",
					Text = "Cancel",
					AutoDefault = false,
				},
				ui:Button
				{
					ID = "OKButton",
					Text = "OK",
					Default = true,
				},
			},
		},
    })

    window_items = window:GetItems()

    window.On.OKButton.Clicked = function(ev)
		subtitleTrack = tonumber(window_items.subtitleTrack.Text)
        dispatcher:ExitLoop(true)
    end

	window.On.CancelButton.Clicked = function(ev)
		dispatcher:ExitLoop(false)
	end
	
    window.On.CopySubtitleDialog.Close = function(ev)
        window_items.CancelButton:Click()
    end

    return window
end


local function alertMessage(msg)
    local window_flags = nil

	if ffi.os == "Windows" then
		window_flags = 	
		{
			Window = true,
			CustomizeWindowHint = true,
			WindowCloseButtonHint = true,
		}
	elseif ffi.os == "Linux" then
		window_flags = 
		{
			Window = true,
		}
	elseif ffi.os == "OSX" then
		window_flags = 
		{
			Dialog = true,
		}
	end

    local window = dispatcher:AddDialog(
    {
        ID = "AlertDialog",
        WindowTitle = "Error",
        WindowFlags = window_flags,
        WindowModality = "ApplicationModal",
        Events = { Close = true, KeyPress = true },

		ui:VGroup
		{
			Weight = 1,
			MinimumSize = { 450, 120 },
			MaximumSize = { 450, 120 },

			ui:VGap(10),
			ui:Label { 
				Alignment = {AlignHCenter = true},
				Text = msg,
				StyleSheet = [[
					QLabel
					{
						color: rgb(255, 255, 0);
						font-size: 13px;
						font-weight: bold;
					}
				]],
			}, 
			ui:VGap(10),
			ui:HGroup {
				ui:HGap(0,1),
				ui:Button
				{
					Weight = 0,
					MinimumSize = { 100, 0 },
					MaximumSize = { 100, 1000 },
					ID = "OKButton",
					Text = "OK",
					Default = true,
				},
				ui:HGap(0,1),
			}
		},
    })

    window.On.OKButton.Clicked = function(ev)
        dispatcher:ExitLoop(true)
    end

	window.On.AlertDialog.Close = function(ev)
        window_items.CancelButton:Click()
    end

	window:Show()
	dispatcher:RunLoop()
	window:Hide()
end

local function ResetCaptionWords( comp, caption )
	Options = comp:FindTool('Options')
	Options.CaptionInput = caption
	Options.CacheMode = 1

	comp:Execute(Options.ResetScript[TIME_UNDEFINED])

	return Options.ResetSuccess[TIME_UNDEFINED]==1
end

local function GetSubtitles()
	local _timeline = project:GetCurrentTimeline()
	local _subtitles = {}
	local _subtitleClips = _timeline:GetItemsInTrack('subtitle', subtitleTrack)

	for _, clip in ipairs(_subtitleClips) do
		local _subtitle = {}
		_subtitle["text"] = clip:GetName():gsub("\u{2028}", "\r")
		_subtitle["start"] = clip:GetStart()
		_subtitle["end"] = clip:GetEnd()
		_subtitle["duration"] = clip:GetDuration()
		table.insert(_subtitles, _subtitle)
	end

	return _subtitles
end

local function Main()
	local _timeline = project:GetCurrentTimeline()

	if not _timeline then
		alertMessage ('Please open a timeline with subtitle tracks')
	else
		local _template 

		if _timeline:GetTrackCount("subtitle") == 0 then
			alertMessage('Current timeline does not have subtitle tracks')
			return
		end

		for _, clip in ipairs(mediaPool:GetCurrentFolder():GetClipList()) do
			if clip:GetClipProperty("Clip Name") == 'Essential Active Caption' then
				_template=clip
				break
			end
		end

		if not _template then
			alertMessage('Current Media Pool Bin does not have Essential Active Caption clip.\r\nPlease add an Essential Active Caption clip to your timeline,\r\nand drag it to the current medial pool bin')
			return
		end

		local _window = create_window()
		_window:Show()
		local _ok = dispatcher:RunLoop()
		_window:Hide()

		if (_ok) then
			_timeline:AddTrack("video")
			local _trackCount = _timeline:GetTrackCount("video")

			for _, sub in ipairs(GetSubtitles()) do
				local _clip = {}
				_clip["mediaPoolItem"] = _template
				_clip["startFrame"] = 0
				_clip["endFrame"] = sub['duration']-1
				_clip["trackIndex"] = _trackCount
				_clip["recordFrame"] = sub['start']

				local _item = mediaPool:AppendToTimeline({_clip})[1]
				for r=1,5 do
					app:Sleep(0.01)
					local _success = ResetCaptionWords(_item:GetFusionCompByIndex(1),sub['text'])
					if _success then break end
				end
			end
		end
	end
end


Main()