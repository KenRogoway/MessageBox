---------------------------------------------------------------------------------------
-- General purpose MessageBox class
--
-- Date: October 22, 2011
--
-- Version: 1.0
--
-- File name: cMessageBox.lua
--
-- Requires ui

-- newMessageBox( params )

-- Parameters:
-- modal			(optional, defaults to true)
-- msgBoxType		(optional, defaults to "MB_Okay") Can be any of the following:
--					"MB_Okay", "MB_OkayCancel", "MB_YesNo", "MB_YesNoCancel"
-- background		(optional, if no background image is specified then display.newRect() will be used)
-- onPress			(optional)
-- onRelease		(required)
-- rectCornerRadius	(optional, only used if no background is specified)
-- rectStroke		(optional, only used if no background is specified)
-- rectFillColor	(optional, only used if no background is specified)
-- rectStrokeColor	(optional, only used if no background is specified)
-- width			(optional, defaults to 1/2 of the display.contentWidth)
-- height			(optional, defaults to 1/2 of the display.contentHeight)
-- borderSizeX		(optional, defaults to kMsgBoxDefault_BorderSizeX)
-- borderSizeY		(optional, defaults to kMsgBoxDefault_BorderSizeY)
-- captionText		(optional)
-- captionSize		(optional, defaults to kMsgBoxDefault_CaptionSize)
-- captionColor		(optional, defaults to kMsgBoxDefault_CaptionColor)
-- messageText		(optional)
-- messageSize		(optional, defaults to kMsgBoxDefault_MessageSize)
-- messageColor		(optional, defaults to kMsgBoxDefault_MessageColor)
-- messageJustify	(optional, defaults to display.CenterReferencePoint)
-- buttonImages		(optional, if no button image array is specified then buttons will be created using newRect())

-- Sample code is MIT licensed, see http://developer.anscamobile.com/code/license
-- Copyright (C) 2011 Homebrew Software. All Rights Reserved.

---------------------------------------------------------------------------------------

module(..., package.seeall)

-- These are here because I used source art that was for 800x600
-- so all of my coordinates are based on that resolution.
kMsgBoxScaleX = display.contentWidth/800
kMsgBoxScaleY = display.contentHeight/600

-- ***************************************
-- Message Box Button Types
-- Used to index into buttonImages.  If
-- you used custom button images make sure
-- they are in this order in your array
-- ***************************************
local kMsgBoxButton_Okay 	= 1
local kMsgBoxButton_Cancel	= 2
local kMsgBoxButton_Yes		= 3
local kMsgBoxButton_No		= 4
local kMsgBoxButton_Help	= 5

local buttonNames =
{
    "Okay",
    "Cancel",
    "Yes",
    "No",
    "Help",
}

local buttonReturnValues =
{
    "MB_Okay",
    "MB_Cancel",
    "MB_Yes",
    "MB_No",
    "MB_Help",
}

-- *************************************************************
-- Message Box Default values.  You can change these if you
-- want a different default look for your messages, or you can
-- pass parameters in to override the defaults.
-- *************************************************************
local kMsgBoxDefault_BorderSizeX = math.floor(24*kMsgBoxScaleX)
local kMsgBoxDefault_BorderSizeY = math.floor(24*kMsgBoxScaleY)

local kMsgBoxDefault_LineSpacing = math.floor(8*kMsgBoxScaleY)

local kMsgBoxDefault_DisplayRectCornerRadius = 16
local kMsgBoxDefault_DisplayRectStroke = 4
local kMsgBoxDefault_DisplayRectFillColor = { 128, 128, 128, 255 }
local kMsgBoxDefault_DisplayRectStrokeColor = { 0, 0, 0, 255 }
local kMsgBoxDefault_TitleTextFont = native.systemFontBold
local kMsgBoxDefault_MessageTextFont = native.systemFont

local kMsgBoxDefault_ButtonRectCornerRadius = 8
local kMsgBoxDefault_ButtonRectStroke = 4
local kMsgBoxDefault_ButtonRectFillColor = { 64, 64, 64, 64 }
local kMsgBoxDefault_ButtonRectStrokeColor = { 0, 0, 0, 255 }
local kMsgBoxDefault_ButtonTextColor = { 0, 0, 0, 255 }
local kMsgBoxDefault_ButtonTextSize = math.floor(24*kMsgBoxScaleY)
local kMsgBoxDefault_ButtonTextFont = native.systemFont

local kMsgBoxDefault_CaptionTextSize = math.floor(36*kMsgBoxScaleY)
local kMsgBoxDefault_CaptionTextColor = { 0, 0, 0, 255 }

local kMsgBoxDefault_MessageTextSize = math.floor(32*kMsgBoxScaleY)
local kMsgBoxDefault_MessageTextColor = { 0, 0, 0, 255 }
local kMsgBoxDefault_MessageJustify = display.CenterReferencePoint
	
-- From http://lua-users.org/wiki/SplitJoin
-- Compatibility: Lua-5.0
function Split(str, delim, maxNb)
    -- Eliminate bad cases...
    if string.find(str, delim) == nil then
        return { str }
    end
    if maxNb == nil or maxNb < 1 then
        maxNb = 0    -- No limit
    end
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gfind(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end
    -- Handle the last field
    if nb ~= maxNb then
        result[nb + 1] = string.sub(str, lastPos)
    end
    return result
end

-- Helper function for newButton utility function below
-- Taken from ui.lua and modified for our text buttons
local function newTextButtonHandler( self, event )

	local result = true
    
	local default = self.text
	local over = self.overText
	
	-- General "onEvent" function overrides onPress and onRelease, if present
	local onEvent = self._onEvent
	
	local onPress = self._onPress
	local onRelease = self._onRelease

	local buttonEvent = {}
	if (self._id) then
		buttonEvent.id = self._id
	end

	local phase = event.phase
	if "began" == phase then
		if over then 
			default.isVisible = false
			over.isVisible = true
		end

		if onEvent then
			buttonEvent.phase = "press"
			result = onEvent( buttonEvent )
		elseif onPress then
			result = onPress( event )
		end

		-- Subsequent touch events will target button even if they are outside the stageBounds of button
		display.getCurrentStage():setFocus( self, event.id )
		self.isFocus = true
		
	elseif self.isFocus then
		local bounds = self.stageBounds
		local x,y = event.x,event.y
		local isWithinBounds = 
			bounds.xMin <= x and bounds.xMax >= x and bounds.yMin <= y and bounds.yMax >= y

		if "moved" == phase then
			if over then
				-- The rollover image should only be visible while the finger is within button's stageBounds
				default.isVisible = not isWithinBounds
				over.isVisible = isWithinBounds
			end
			
		elseif "ended" == phase or "cancelled" == phase then 
			if over then 
				default.isVisible = true
				over.isVisible = false
			end
			
			if "ended" == phase then
				-- Only consider this a "click" if the user lifts their finger inside button's stageBounds
				if isWithinBounds then
					if onEvent then
						buttonEvent.phase = "release"
						result = onEvent( buttonEvent )
					elseif onRelease then
						result = onRelease( event )
					end
				end
			end
			
			-- Allow touch events to be sent normally to the objects they "hit"
			display.getCurrentStage():setFocus( self, nil )
			self.isFocus = false
		end
	end

	return result
end

-- This will create a generic text button that does not need a button image
-- Ideally ui.lua should handle this for us.  This function takes a lot of
-- the same parameters as the newMessageBox() function
function newTextButton( params )
	local button, imageBack, defaultX , defaultY , size, font, textColor, textOverColor, offset
    local rectStroke
    local rectFillColor = {}
    local rectStrokeColor = {}
    local rectCornerRadius
	
    button = display.newGroup()
    
    if ( params.rectStroke ) then
        rectStroke = params.rectStroke
    else
        rectStroke = kMsgBoxDefault_ButtonRectStroke
    end
    
    if ( params.rectFillColor ) then
        rectFillColor = params.rectFillColor
    else
        rectFillColor = kMsgBoxDefault_ButtonRectFillColor
    end
    
    if ( params.rectStrokeColor ) then
        rectStrokeColor = params.rectStrokeColor
    else
        rectStrokeColor = kMsgBoxDefault_ButtonRectStrokeColor
    end
		
    if ( params.rectCornerRadius ) then
        rectCornerRadius = params.rectCornerRadius
    else
        rectCornerRadius = kMsgBoxDefault_ButtonRectCornerRadius
    end
    
    if ( rectCornerRadius > 0 ) then
        imageBack = display.newRoundedRect( 0, 0, params.defaultX, params.defaultY, rectCornerRadius )
    else
        imageBack = display.newRect( 0, 0, params.defaultX, params.defaultY )
    end
    
    imageBack:setFillColor( rectFillColor[1], rectFillColor[2], rectFillColor[3], rectFillColor[4] )
	imageBack.strokeWidth = rectStroke
    imageBack:setStrokeColor( rectStrokeColor[1], rectStrokeColor[2], rectStrokeColor[3], rectStrokeColor[4] )
    
    button:insert( imageBack, true )
	
	-- Public methods
	function button:setText( newText )
	
		local labelText = self.text
		if ( labelText ) then
			--labelText:removeSelf()
			display.remove( labelText )
			labelText = nil
			self.text = nil
		end

		local labelShadow = self.shadow
		if ( labelShadow ) then
			--labelShadow:removeSelf()
			display.remove( labelShadow )
			labelShadow = nil
			self.shadow = nil
		end

		local labelHighlight = self.highlight
		if ( labelHighlight ) then
			--labelHighlight:removeSelf()
			display.remove( labelHighlight )
			labelHighlight = nil
			self.highlight = nil
		end
		
		local labelOverText = self.overText
		if ( labelOverText ) then
			--labelHighlight:removeSelf()
			display.remove( labelOverText )
			labelOverText = nil
			self.overText = nil
		end
		
		if ( params.size and type(params.size) == "number" ) then size=params.size else size=20 end
		if ( params.font ) then font=params.font else font=native.systemFontBold end
		if ( params.textColor ) then textColor=params.textColor else textColor={ 255, 255, 255, 255 } end
		if ( params.textOverColor ) then textOverColor=params.textOverColor else textOverColor={ 255, 255, 0, 255 } end
		
		size = size * 2
		
		-- Optional vertical correction for fonts with unusual baselines (I'm looking at you, Zapfino)
		if ( params.offset and type(params.offset) == "number" ) then offset=params.offset else offset = 0 end
		
		if ( params.emboss ) then
			-- Make the label text look "embossed" (also adjusts effect for textColor brightness)
			local textBrightness = ( textColor[1] + textColor[2] + textColor[3] ) / 3
			
			labelHighlight = display.newText( newText, 0, 0, font, size )
			if ( textBrightness > 127) then
				labelHighlight:setTextColor( 255, 255, 255, 20 )
			else
				labelHighlight:setTextColor( 255, 255, 255, 140 )
			end
			button:insert( labelHighlight, true )
			labelHighlight.x = labelHighlight.x + 1.5; labelHighlight.y = labelHighlight.y + 1.5 + offset
			self.highlight = labelHighlight

			labelShadow = display.newText( newText, 0, 0, font, size )
			if ( textBrightness > 127) then
				labelShadow:setTextColor( 0, 0, 0, 128 )
			else
				labelShadow:setTextColor( 0, 0, 0, 20 )
			end
			button:insert( labelShadow, true )
			labelShadow.x = labelShadow.x - 1; labelShadow.y = labelShadow.y - 1 + offset
			self.shadow = labelShadow
			
			labelHighlight.xScale = .5; labelHighlight.yScale = .5
			labelShadow.xScale = .5; labelShadow.yScale = .5
		end
		
		labelText = display.newText( newText, 0, 0, font, size )
		labelText:setTextColor( textColor[1], textColor[2], textColor[3], textColor[4] )
		button:insert( labelText, true )
		labelText.y = labelText.y + offset
		self.text = labelText
		labelText.xScale = .5; labelText.yScale = .5
        
		labelOverText = display.newText( newText, 0, 0, font, size )
		labelOverText:setTextColor( textOverColor[1], textOverColor[2], textOverColor[3], textOverColor[4] )
		button:insert( labelOverText, true )
		labelOverText.y = labelOverText.y + offset
		self.overText = labelOverText
		labelOverText.xScale = .5; labelOverText.yScale = .5
        labelOverText.isVisible = false
		
	end
	
	if params.text then
		button:setText( params.text )
	end
	
	if ( params.onPress and ( type(params.onPress) == "function" ) ) then
		button._onPress = params.onPress
	end
	if ( params.onRelease and ( type(params.onRelease) == "function" ) ) then
		button._onRelease = params.onRelease
	end
	
	if (params.onEvent and ( type(params.onEvent) == "function" ) ) then
		button._onEvent = params.onEvent
	end
	
	-- set button to active (meaning, can be pushed)
	button.isActive = true
	
	-- Set button as a table listener by setting a table method and adding the button as its own table listener for "touch" events
	button.touch = newTextButtonHandler
	button:addEventListener( "touch", button )

	if params.x then
		button.x = params.x
	end
	
	if params.y then
		button.y = params.y
	end
	
	if params.id then
		button._id = params.id
	end

	return button
end

-- *************************************************************
-- Function to create a new message box.  Read the various
-- options above for information on the params value
-- *************************************************************
function newMessageBox( params )
	local dialog
	local ui = ui
	local dlgType
	local isModal, modalRect
	local borderSizeX, borderSizeY
	local captionText, captionColor, captionSize
	local messageText, messageColor, messageSize, messageJustify
    local buttonImages, buttonTextSize
	local dlgX, dlgY, width, height
	
	dialog = display.newGroup()
	
	-- For now we only support centering the dialog on the screen
    -- A future version will allow Message Boxes to be placed anywhere
	dlgX = display.contentCenterX
	dlgY = display.contentCenterY
	
    -- This is used to make sure none of the tap or touch events
    -- get through to what is behind the message box
	local function gobbleTapListener(event)
        --print( "event type", event.name )
		return true
	end

	if ( params.modal ) then
		isModal = params.modal
	else
		isModal = true
	end
	
	if ( isModal == true ) then
		-- Create a hidden rectangle that covers the screen so we can gobble input
		modalRect = display.newRect( 0, 0, display.contentWidth, display.contentHeight )
		modalRect:setFillColor( 0, 0, 0, 0 )
		dialog:insert( modalRect )
		modalRect:addEventListener( "tap", gobbleTapListener )
		modalRect:addEventListener( "touch", gobbleTapListener )
	end

	-- Get the Message Box type (Okay, Yes/No, etc)
	if ( params.msgBoxType ) then
		dlgType = params.msgBoxType
	else
		dlgType = "MB_Okay"
	end
    
    if ( params.buttonImages ) then
        buttonImages = params.buttonImages
    end
	
	if ( params.width ) then
		width = params.width
	else
		width = math.floor( display.viewableContentWidth / 2.0)
	end
	
	if ( params.height ) then
		height = params.height
	else
		height = math.floor( display.viewableContentHeight / 2.0)
	end
	
	if ( params.messageColor ) then
		messageColor = params.messageColor
	else
		messageColor = kMsgBoxDefault_MessageTextColor
	end
	
	if ( params.messageJustify ) then
		messageJustify = params.messageJustify
	else
		messageJustify = kMsgBoxDefault_MessageJustify
	end
    
	-- Get the border size in the X direction.  Used to
	-- ensure space between text and the edge of the image
	if ( params.borderSizeX ) then
		borderSizeX = params.borderSizeX
	else
		borderSizeX = kMsgBoxDefault_BorderSizeX
	end
	
	-- Get the border size in the Y direction.  Used to
	-- ensure space between text and the edge of the image
	if ( params.borderSizeY ) then
		borderSizeY = params.borderSizeY
	else
		borderSizeY = kMsgBoxDefault_BorderSizeY
	end
	
	if ( params.captionText ) then
		captionText = params.captionText
	else
		captionText = " "
	end

	-- Get the size of our caption text
	if ( params.captionSize ) then
		captionSize = params.captionSize
	else
		captionSize = kMsgBoxDefault_CaptionTextSize
	end
	
	-- Get the caption color
	if ( params.captionColor ) then
		captionColor = params.captionColor
	else
		captionColor = kMsgBoxDefault_CaptionTextColor
	end
	
	if ( params.messageSize ) then
		messageSize = params.messageSize
	else
		messageSize = kMsgBoxDefault_MessageTextSize
	end
    
    if ( params.buttonTextSize ) then
        buttonTextSize = params.buttonTextSize
    else
        buttonTextSize = kMsgBoxDefault_ButtonTextSize
    end
	
	local imgBack
	
	if ( params.background ) then
		imgBack = display.newImageRect( params.background, width, height )
		dialog:insert( imgBack, true )
		imgBack:addEventListener( "tap", gobbleTapListener )
		imgBack:addEventListener( "touch", gobbleTapListener )
		imgBack.x = dlgX
		imgBack.y = dlgY
	else
		local rectStroke
		local rectFillColor = {}
		local rectStrokeColor = {}
		local rectCornerRadius
		
		if ( params.rectStroke ) then
			rectStroke = params.rectStroke
		else
			rectStroke = kMsgBoxDefault_DisplayRectStroke
		end
		
		if ( params.rectFillColor ) then
			rectFillColor = params.rectFillColor
		else
			rectFillColor = kMsgBoxDefault_DisplayRectFillColor
		end
		
		if ( params.rectStrokeColor ) then
			rectStrokeColor = params.rectStrokeColor
		else
			rectStrokeColor = kMsgBoxDefault_DisplayRectStrokeColor
		end
		
		if ( params.rectCornerRadius ) then
			rectCornerRadius = params.rectCornerRadius
		else
			rectCornerRadius = kMsgBoxDefault_DisplayRectCornerRadius
		end
		
		if ( rectCornerRadius > 0 ) then
			imgBack = display.newRoundedRect( 0, 0, width, height, rectCornerRadius )
		else
			imgBack = display.newRect( 0, 0, width, height )
		end
		
		--print( "rectFillColor = ", rectFillColor[1], rectFillColor[2], rectFillColor[3], rectFillColor[4] )
		
		imgBack.strokeWidth = rectStroke
		imgBack:setFillColor( rectFillColor[1], rectFillColor[2], rectFillColor[3], rectFillColor[4] )
		imgBack:setStrokeColor( rectStrokeColor[1], rectStrokeColor[2], rectStrokeColor[3], rectStrokeColor[4] )
		dialog:insert( imgBack, true )
		imgBack:addEventListener( "tap", gobbleTapListener )
		imgBack.x = dlgX
		imgBack.y = dlgY
	end
	
	local captionLabel = ui.newLabel{
		bounds = { 0, 0, width, height },
		text = captionText,
		font = kMsgBoxDefault_TitleTextFont,
		textColor = captionColor,
		size = captionSize,
		align = "center"
	}
	dialog:insert( captionLabel )
	captionLabel:setReferencePoint(display.TopCenterReferencePoint)
	captionLabel.x = dlgX
	captionLabel.y = dlgY + borderSizeY - math.floor(height/2.0)

	if ( params.messageText ) then
		local bMoreData = true
		local messageLabels = {}
		local count = 0
		local textArray = Split( params.messageText, " " )
		local nTextIndex
		local i, j
		
		--print( "text Elements = ", #textArray )
        --print( "msgColor =", messageColor[1], messageColor[2], messageColor[3] )
		
		local msgWidth, msgHeight
		
		-- These are to figure out the size of the message text
		msgWidth = 0
		msgHeight = 0
		
		nTextIndex = 1
		
		while bMoreData do
			local msgText = textArray[nTextIndex]
			local lastText = ""
			local nStartIndex = nTextIndex
			
			count = count + 1
			
			messageLabels[ count ] = ui.newLabel{
				bounds = { 0, 0, width, messageSize+4 },
				text = msgText,
				font = kMsgBoxDefault_MessageTextFont,
				textColor = messageColor,
				size = messageSize,
				align = "center"
			}
			
			-- This loop adds each word and checks the "content" width
			-- so we know when we have enough text for the line
			while( bMoreData and ( messageLabels[ count ].contentWidth < (width-2*borderSizeX) ) ) do
				lastText = msgText
				if ( nTextIndex < #textArray ) then
					nTextIndex = nTextIndex + 1
					msgText = msgText.." "..textArray[nTextIndex]
					messageLabels[ count ]:setText( msgText )
				else
					bMoreData = false
				end
			end
			
			messageLabels[ count ]:setText( lastText )
			if ( messageLabels[ count ].contentWidth > msgWidth ) then
				msgWidth = messageLabels[ count ].contentWidth
			end
			dialog:insert( messageLabels[ count ] )
			
			msgHeight = msgHeight + messageLabels[ count ].contentHeight
			if ( bMoreData == true ) then
				msgHeight = msgHeight + kMsgBoxDefault_LineSpacing
			end
		end
				
		local xPos, yPos, newJustify
		local dlgLeft, dlgTop
		
		dlgLeft = dlgX - math.floor(width/2)
		dlgTop = dlgY - math.floor(height/2)
		
		-- Calculate our starting point.  Everything ends up being
		-- relative to the "top" and then either left, center or right.
		-- This is so we can just increment our Y values
		if ( messageJustify == display.CenterReferencePoint ) then
			newJustify = display.TopCenterReferencePoint
			xPos = dlgLeft + math.floor(width/2)
			yPos = dlgY - math.floor( msgHeight/2 )
		elseif ( messageJustify == display.TopLeftReferencePoint ) then
			newJustify = display.TopLeftReferencePoint
			xPos = dlgLeft + borderSizeX
			yPos = dlgTop + borderSizeY + 2*captionLabel.contentHeight
		elseif ( messageJustify == display.TopCenterReferencePoint ) then
			newJustify = display.TopCenterReferencePoint
			xPos = dlgX
			yPos = dlgTop + borderSizeY + 2*captionLabel.contentHeight
		elseif ( messageJustify == display.TopRightReferencePoint ) then
			newJustify = display.TopRightReferencePoint
			xPos = dlgLeft + width - borderSizeX
			yPos = dlgTop + borderSizeY + 2*captionLabel.contentHeight
		elseif ( messageJustify == display.CenterRightReferencePoint ) then
			newJustify = display.TopRightReferencePoint
			xPos = dlgLeft + width - borderSizeY
			yPos = dlgY - math.floor( msgHeight/2 )
		elseif ( messageJustify == display.BottomRightReferencePoint ) then
			newJustify = display.TopRightReferencePoint
			xPos = dlgLeft + width - borderSizeX
			yPos = dlgTop + height - borderSizeY - msgHeight
		elseif ( messageJustify == display.BottomCenterReferencePoint ) then
			newJustify = display.TopCenterReferencePoint
			xPos = dlgLeft + math.floor(width/2)
			yPos = dlgTop + height - borderSizeY - msgHeight
		elseif ( messageJustify == display.BottomLeftReferencePoint ) then
			newJustify = display.TopLeftReferencePoint
			xPos = dlgLeft + borderSizeX
			yPos = dlgTop + height - borderSizeY - msgHeight
		elseif ( messageJustify == display.CenterLeftReferencePoint ) then
			newJustify = display.TopLeftReferencePoint
			xPos = dlgLeft + borderSizeX
			yPos = dlgY - math.floor( msgHeight/2 )
		end

		for i=1,count do
			messageLabels[ i ]:setReferencePoint(newJustify)
			messageLabels[ i ].x = xPos
			messageLabels[ i ].y = yPos
			yPos = yPos + messageLabels[ i ].contentHeight + kMsgBoxDefault_LineSpacing
		end
		
	end

	local dlgOnPress, dlgOnRelease, dlgOnEvent
	
	if ( params.onPress and ( type(params.onPress) == "function" ) ) then
		dlgOnPress = params.onPress
	else
		dlgOnPress = nil
	end
	if ( params.onRelease and ( type(params.onRelease) == "function" ) ) then
		dlgOnRelease = params.onRelease
	else
		dlgOnRelease = nil
	end
	
	if (params.onEvent and ( type(params.onEvent) == "function" ) ) then
		dlgOnEvent = params.onEvent
	else
		dlgOnEvent = nil
	end
    
	function makeButton( nWhichButton, dlgWidth, buttonTextSize )
		local button
        
        if ( nWhichButton > 0 and nWhichButton <= #buttonReturnValues ) then
            local bMakeTextButton = true
            if ( buttonImages ) then
                if ( buttonImages[nWhichButton].up and buttonImages[nWhichButton].down ) then
                    bMakeTextButton = false
                end
            end
            
            if ( bMakeTextButton == true ) then
                button = newTextButton{
                    defaultX = math.floor( dlgWidth/5 ),
                    defaultY = math.floor( buttonTextSize*1.6 ),
                    onPress = dlgOnPress,
                    onRelease = dlgOnRelease,
                    onEvent = dlgOnEvent,
                    text = buttonNames[nWhichButton],
                    size = buttonTextSize,
                    font = buttonTextFont,
                    id = buttonReturnValues[nWhichButton],
                    }
            else
                button = ui.newButton{
                    defaultSrc = buttonImages[nWhichButton].up,
                    defaultX = buttonImages[nWhichButton].w,
                    defaultY = buttonImages[nWhichButton].h,
                    overSrc = buttonImages[nWhichButton].down,
                    overX = buttonImages[nWhichButton].w,
                    overY = buttonImages[nWhichButton].h,
                    onPress = dlgOnPress,
                    onRelease = dlgOnRelease,
                    onEvent = dlgOnEvent,
                    id = buttonReturnValues[nWhichButton],
                    }
            end
        end

		return button
	end
	
	if ( dlgType == "MB_Okay" ) then
		local okayBtn = makeButton( kMsgBoxButton_Okay, width, buttonTextSize )
		
		dialog:insert( okayBtn )
		okayBtn:setReferencePoint( display.BottomCenterReferencePoint )
		okayBtn.x = display.contentCenterX
		okayBtn.y = display.contentCenterY + math.floor(height/2.0) - borderSizeY
	elseif ( dlgType == "MB_OkayCancel" ) then
		local okayBtn = makeButton( kMsgBoxButton_Okay, width, buttonTextSize )
		local cancelBtn = makeButton( kMsgBoxButton_Cancel, width, buttonTextSize )
		
		dialog:insert( okayBtn )
		okayBtn:setReferencePoint( display.BottomLeftReferencePoint )
		okayBtn.x = dlgX - math.floor(width/2.0) + 3*borderSizeX
		okayBtn.y = dlgY + math.floor(height/2.0) - borderSizeY
		
		dialog:insert( cancelBtn )
		cancelBtn:setReferencePoint( display.BottomRightReferencePoint )
		cancelBtn.x = dlgX + math.floor(width/2.0) - 3*borderSizeX
		cancelBtn.y = dlgY + math.floor(height/2.0) - borderSizeY
	elseif ( dlgType == "MB_YesNo" ) then
		local yesBtn = makeButton( kMsgBoxButton_Yes, width, buttonTextSize )
		local noBtn = makeButton( kMsgBoxButton_No, width, buttonTextSize )
		
		dialog:insert( yesBtn )
		yesBtn:setReferencePoint( display.BottomLeftReferencePoint )
		yesBtn.x = dlgX - math.floor(width/2.0) + 3*borderSizeX
		yesBtn.y = dlgY + math.floor(height/2.0) - borderSizeY
		
		dialog:insert( noBtn )
		noBtn:setReferencePoint( display.BottomRightReferencePoint )
		noBtn.x = dlgX + math.floor(width/2.0) - 3*borderSizeX
		noBtn.y = dlgY + math.floor(height/2.0) - borderSizeY
	elseif ( dlgType == "MB_YesNoCancel" ) then
		local yesBtn = makeButton( kMsgBoxButton_Yes, width, buttonTextSize )
		local noBtn = makeButton( kMsgBoxButton_No, width, buttonTextSize )
		local cancelBtn = makeButton( kMsgBoxButton_Cancel, width, buttonTextSize )
		
		dialog:insert( yesBtn )
		yesBtn:setReferencePoint( display.BottomLeftReferencePoint )
		yesBtn.x = dlgX - math.floor(width/2.0) + 2*borderSizeX
		yesBtn.y = dlgY + math.floor(height/2.0) - borderSizeY
		
		dialog:insert( noBtn )
		noBtn:setReferencePoint( display.BottomCenterReferencePoint )
		noBtn.x = dlgX
		noBtn.y = dlgY + math.floor(height/2.0) - borderSizeY
        
		dialog:insert( cancelBtn )
		cancelBtn:setReferencePoint( display.BottomRightReferencePoint )
		cancelBtn.x = dlgX + math.floor(width/2.0) - 2*borderSizeX
		cancelBtn.y = dlgY + math.floor(height/2.0) - borderSizeY
	end
	
	return dialog
end