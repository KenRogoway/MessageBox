
---------------------------------------------------------------------------------------
-- Date: October 12, 2011
--
-- Version: 1.0
--
-- File name: cSceneTest.lua
--
-- Code type: Example Code
--
-- Author: Ken Rogoway
--
-- Update History:
--
-- Comments: The space images used are from NASA and are in the public domain.
-- 			 The horse image sheets are from the horse demo provided by Ansca.
--
-- Sample code is MIT licensed:
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--
-- Copyright (C) 2011 Ken Rogoway. All Rights Reserved.
---------------------------------------------------------------------------------------

module(..., package.seeall)

cMessageBox = require( "cMessageBox" )

-- These are some button images the cMessageBox uses.  You can replace these with
-- your own button images, or choose to use default (newRect() based) buttons.
local myButtonImages =
{
    { id="MB_Okay",     up= "Images/ButtonOkayUp.png", 	    down= "Images/ButtonOkayDown.png",	w=math.floor(160*gWS.nScaleX), h=math.floor(64*gWS.nScaleY) },
    { id="MB_Cancel",   up= "Images/ButtonCancelUp.png", 	down= "Images/ButtonCancelDown.png", w=math.floor(160*gWS.nScaleX), h=math.floor(64*gWS.nScaleY) },
    { id="MB_Yes",      up= "Images/ButtonYesUp.png", 	    down= "Images/ButtonYesDown.png",	w=math.floor(160*gWS.nScaleX), h=math.floor(64*gWS.nScaleY) },
    { id="MB_No",       up= "Images/ButtonNoUp.png", 		down= "Images/ButtonNoDown.png",	w=math.floor(160*gWS.nScaleX), h=math.floor(64*gWS.nScaleY) },
    { id="MB_Help",     up= "Images/ButtonHelpUp.png", 	    down= "Images/ButtonHelpDown.png", w=math.floor(160*gWS.nScaleX), h=math.floor(64*gWS.nScaleY) },
}

-- Main function - MUST return a display.newGroup()
function new()
	local gameGroup = display.newGroup()
	local gameImage
	local btnOkayDlg, btnOkayCancelDlg, btnYesNoDlg, btnYesNoCancelDlg, btnBitmapDlg
	local testMsgBox
	
    -- This is where you would detect what button was
    -- pressed and do whatever action you want.
	local onMessageBoxDone = function( event )
		if event.phase == "release" then
			print( "Message Box button id", tostring( event.id ) )
			testMsgBox.isVisible = false
			display.remove( testMsgBox )
			testMsgBox = nil
		end
		return true
	end
	
	gameImage = display.newImageRect( gWS.pImageDir.."earth_eclipse.png", display.contentWidth, display.contentHeight )
	gameGroup:insert( gameImage )
	gameImage.x = display.contentCenterX
	gameImage.y = display.contentCenterY
	
	local onLaunchMessageBox = function( event )
		if event.phase == "release" then
            local whatType
            -- What type of message box do we want to show?
			if ( event.id == "OkayMsgBox" ) then
                whatType = "MB_Okay"
            elseif ( event.id == "OkayCancelMsgBox" ) then
                whatType = "MB_OkayCancel"
            elseif ( event.id == "YesNoMsgBox" ) then
                whatType = "MB_YesNo"
            elseif ( event.id == "YesNoCancelMsgBox" ) then
                whatType = "MB_YesNoCancel"
            end
            
            testMsgBox = cMessageBox.newMessageBox{
                msgBoxType = whatType,
                --buttonImages = myButtonImages,
                width = math.floor( 640*gWS.nScaleX + 0.5 ),
                height= math.floor( 480*gWS.nScaleY + 0.5 ),
                captionText = "Example "..event.id,
                messageText = "This is a sample of a message box using the defaults.  You can have as much text as you want and it will wrap the text. If you want the text justified a different way set the messageJustify param in your call to newMsgBox().",
                messageJustify = display.CenterReferencePoint,
                onEvent = onMessageBoxDone,
                messageColor = { 0, 0, 0, 255 }
                }
            
            gameGroup:insert( testMsgBox )
		end
		return true
	end
	
	btnOkayDlg = ui.newButton{
		defaultSrc = gWS.pImageDir.."Btn_OkayMsgBox_Up.png",
		defaultX = math.floor(256*gWS.nScaleX),
		defaultY = math.floor(48*gWS.nScaleY),
		overSrc = gWS.pImageDir.."Btn_OkayMsgBox_Down.png",
		overX = math.floor(256*gWS.nScaleX),
		overY = math.floor(48*gWS.nScaleY),
		onEvent = onLaunchMessageBox,
		id = "OkayMsgBox"
	}

	btnOkayDlg:setReferencePoint( display.CenterReferencePoint )
	btnOkayDlg.x = display.contentCenterX
	btnOkayDlg.y = math.floor(100*gWS.nScaleY + 0.5)
	
	gameGroup:insert( btnOkayDlg )

	btnOkayCancelDlg = ui.newButton{
		defaultSrc = gWS.pImageDir.."Btn_OkayCancelMsgBox_Up.png",
		defaultX = math.floor(256*gWS.nScaleX),
		defaultY = math.floor(48*gWS.nScaleY),
		overSrc = gWS.pImageDir.."Btn_OkayCancelMsgBox_Down.png",
		overX = math.floor(256*gWS.nScaleX),
		overY = math.floor(48*gWS.nScaleY),
		onEvent = onLaunchMessageBox,
		id = "OkayCancelMsgBox"
	}

	btnOkayCancelDlg:setReferencePoint( display.CenterReferencePoint )
	btnOkayCancelDlg.x = display.contentCenterX
	btnOkayCancelDlg.y = math.floor(160*gWS.nScaleY + 0.5)
	
	gameGroup:insert( btnOkayCancelDlg )

	btnYesNoDlg = ui.newButton{
		defaultSrc = gWS.pImageDir.."Btn_YesNoMsgBox_Up.png",
		defaultX = math.floor(256*gWS.nScaleX),
		defaultY = math.floor(48*gWS.nScaleY),
		overSrc = gWS.pImageDir.."Btn_YesNoMsgBox_Down.png",
		overX = math.floor(256*gWS.nScaleX),
		overY = math.floor(48*gWS.nScaleY),
		onEvent = onLaunchMessageBox,
		id = "YesNoMsgBox"
	}

	btnYesNoDlg:setReferencePoint( display.CenterReferencePoint )
	btnYesNoDlg.x = display.contentCenterX
	btnYesNoDlg.y = math.floor(220*gWS.nScaleY + 0.5)
	
	gameGroup:insert( btnYesNoDlg )

	btnYesNoCancelDlg = ui.newButton{
		defaultSrc = gWS.pImageDir.."Btn_YesNoCancelMsgBox_Up.png",
		defaultX = math.floor(256*gWS.nScaleX),
		defaultY = math.floor(48*gWS.nScaleY),
		overSrc = gWS.pImageDir.."Btn_YesNoCancelMsgBox_Down.png",
		overX = math.floor(256*gWS.nScaleX),
		overY = math.floor(48*gWS.nScaleY),
		onEvent = onLaunchMessageBox,
		id = "YesNoCancelMsgBox"
	}

	btnYesNoCancelDlg:setReferencePoint( display.CenterReferencePoint )
	btnYesNoCancelDlg.x = display.contentCenterX
	btnYesNoCancelDlg.y = math.floor(280*gWS.nScaleY + 0.5)
	
	gameGroup:insert( btnYesNoCancelDlg )

	local onBitmapDialogTouch = function( event )
		if event.phase == "release" and btnBitmapDlg.isActive then			
			print( "Bitmap Dialog Button Pressed" )
			
			testMsgBox = cMessageBox.newMessageBox{
				msgBoxType="MB_OkayCancel",
				background = gWS.pImageDir.."BitmapDialog.png",
                buttonImages = myButtonImages,
				width = math.floor( 700*gWS.nScaleX + 0.5 ),
				height= math.floor( 500*gWS.nScaleY + 0.5 ),
				borderSizeX=math.floor(36*gWS.nScaleX),
				borderSizeY=math.floor(36*gWS.nScaleY),
				captionText = "Bitmap Message Box",
				messageText = "This is a sample of a message box using a bitmap background.  You can have as much text as you want and it will wrap the text.",
				onEvent = onMessageBoxDone,
				messageColor = { 16, 16, 16, 255 }
				}
			
			gameGroup:insert( testMsgBox )
		end
		--return true
	end
	
	btnBitmapDlg = ui.newButton{
		defaultSrc = gWS.pImageDir.."Btn_BitmapDialog_Up.png",
		defaultX = math.floor(192*gWS.nScaleX),
		defaultY = math.floor(48*gWS.nScaleY),
		overSrc = gWS.pImageDir.."Btn_BitmapDialog_Down.png",
		overX = math.floor(192*gWS.nScaleX),
		overY = math.floor(48*gWS.nScaleY),
		onEvent = onBitmapDialogTouch,
		id = "BitmapDialogButton",
		text = "",
		font = "Helvetica",
		textColor = { 255, 255, 255, 255 },
		size = 8,
		emboss = false
	}

	btnBitmapDlg:setReferencePoint( display.CenterReferencePoint )
	btnBitmapDlg.x = display.contentCenterX
	btnBitmapDlg.y = math.floor(400*gWS.nScaleY + 0.5)
	
	gameGroup:insert( btnBitmapDlg )

	clean = function()
		
		if gameImage then
			display.remove( gameImage )
			gameImage = nil
		end
		
		if btnDefaultDlg then
			display.remove( btnDefaultDlg )
			btnDefaultDlg = nil
		end
		
		if btnBitmapDlg then
			display.remove( btnBitmapDlg )
			btnBitmapDlg = nil
		end
		
	end
	
	-- MUST return a display.newGroup()
	return gameGroup
end
