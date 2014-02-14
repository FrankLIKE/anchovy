/*
Copyright (c) 2013 Andrey Penechko

Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license the "Software" to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/

module anchovy.gui;

public
{
	import std.conv: to;
	import std.stdio;

	import dlib.math.vector;
	import dlib.math.utils;

	import anchovy.core.input;
	import anchovy.core.math;
	import anchovy.core.types;

	import anchovy.graphics;

	import anchovy.graphics.interfaces.irenderer;
	import anchovy.gui.interfaces.iguiskinparser;
	import anchovy.gui.interfaces.iguirenderer;

	import anchovy.gui.layouts.absolutelayout;
	import anchovy.gui.layouts.linearlayout;

	import anchovy.gui.guicontext;

	import anchovy.gui.events;
	import anchovy.gui.eventpropagators;

	import anchovy.gui.guiskin;
	import anchovy.gui.widget;
	import anchovy.gui.guirenderer;

	import anchovy.gui.jsonguiskinparser;

	import anchovy.gui.textline;
	import anchovy.gui.timermanager;

	import anchovy.gui.templates.widgettemplate;
	import anchovy.gui.templates.templateparser;
	import anchovy.gui.templates.templatemanager;
}