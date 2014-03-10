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

module anchovy.gui.widget;

import std.traits;
import anchovy.gui;
public import anchovy.utils.flexibleobject;

enum defaultAnchor = Sides.LEFT | Sides.TOP;

/// Used to specify Widget.anchor.
enum Sides
{
	LEFT = 1,
	RIGHT = 2,
	TOP = 4,
	BOTTOM = 8,
}

//version = Debug_widget;

/// Container for common properties
class Widget : FlexibleObject
{
public:

	this()
	{
		properties["type"] = new ValueProperty(this, "widget");
		properties["anchor"] = anchor = new ValueProperty(this, defaultAnchor);
		properties["children"] = children = new ValueProperty(this, cast(Widget[])[]);
		properties["parent"] = parent = new ValueProperty(this, null);

		properties["position"] = position = new ValueProperty(this, ivec2(0,0));
		properties["staticPosition"] = staticPosition = new ValueProperty(this, ivec2(0,0));

		properties["minSize"] = minSize = new ValueProperty(this, ivec2(0,0));
		properties["size"] = size = new ValueProperty(this, ivec2(0,0));
		properties["prefSize"] = prefferedSize = new ValueProperty(this, ivec2(0,0));
		properties["staticRect"] = staticRect = new ValueProperty(this, Rect(0,0,0,0));

		properties["state"] = state = new ValueProperty(this, "normal");
		properties["style"] = style = new ValueProperty(this, "");
		properties["geometry"] = geometry = new ValueProperty(this, (TexRectArray[string]).init);

		properties["isVisible"] = isVisible = new ValueProperty(this, true);
		properties["isFocusable"] = isFocusable = new ValueProperty(this, false);
		properties["isEnabled"] = isEnabled = new ValueProperty(this, true);
		properties["isHovered"] = isHovered = new ValueProperty(this, false);
		properties["context"] = context = new ValueProperty(this, null);

		auto onParentChanged = (FlexibleObject obj, Variant newParent){
			(cast(Widget)obj).invalidateLayout;
		};

		auto onPositionChanged = (FlexibleObject obj, Variant newPosition){
			(cast(Widget)obj).invalidateLayout;
		};

		property("parent").valueChanged.connect(onParentChanged);
		property("position").valueChanged.connect(onPositionChanged);

		auto onStaticPositionChanged = (FlexibleObject obj, Variant newStaticPosition){
			obj["staticRect"] = Rect(newStaticPosition.get!ivec2, obj.getPropertyAs!("size", ivec2));
		};

		auto onSizeChanged = (FlexibleObject obj, Variant newSize){
			obj["staticRect"] = Rect(obj.getPropertyAs!("staticPosition", ivec2), newSize.get!ivec2);

			obj.setProperty!("geometry", TexRectArray[string])(null);

			(cast(Widget)obj).invalidateLayout;
		};
		
		property("staticPosition").valueChanged.connect(onStaticPositionChanged);
		property("size").valueChanged.connect(onSizeChanged);

		addEventHandler(&handleDraw);
		addEventHandler(&handleUpdatePosition);
		addEventHandler(&handleExpand);
		addEventHandler(&handleMinimize);
	}

	bool handleExpand(Widget widget, ExpandLayoutEvent event)
	{
		if (auto layout = widget.peekPropertyAs!("layout", ILayout))
		{
			layout.expand(widget);
		}

		return true;
	}

	bool handleMinimize(Widget widget, MinimizeLayoutEvent event)
	{
		if (auto layout = widget.peekPropertyAs!("layout", ILayout))
		{
			layout.minimize(widget);
		}

		return true;
	}

	bool handleUpdatePosition(Widget widget, UpdatePositionEvent event)
	{
		if (auto parent = widget.peekPropertyAs!("parent", Widget))
		{
			if (*parent !is null)
			{
				ivec2 parentPos = (*parent).getPropertyAs!("staticPosition", ivec2);
				ivec2 childPos = widget.getPropertyAs!("position", ivec2);
				ivec2 newStaticPosition = parentPos + childPos; // Workaround bug with direct summ.
				widget["staticPosition"] = newStaticPosition;
				widget["staticRect"] = Rect(newStaticPosition, widget.getPropertyAs!("size", ivec2));
			}
		}

		return true;
	}

	bool handleDraw(Widget widget, DrawEvent event)
	{
		bool clipContent = widget.hasProperty!("clipContent");

		if (event.sinking)
		{
			Rect staticRect = widget.getPropertyAs!("staticRect", Rect);

			if (clipContent)
			{
				event.guiRenderer.pushClientArea(staticRect);
			}

			if (widget.getPropertyAs!("isVisible", bool))
				event.guiRenderer.drawControlBack(widget, staticRect);
		}
		else if (clipContent)
			event.guiRenderer.popClientArea;

		return true;
	}


	ValueProperty anchor;

	ValueProperty children;
	ValueProperty parent;
	ValueProperty context;

	ValueProperty position;
	ValueProperty staticPosition;

	ValueProperty minSize;
	ValueProperty size;
	ValueProperty prefferedSize;
	ValueProperty staticRect;

	ValueProperty state;
	ValueProperty style;
	ValueProperty geometry;

	ValueProperty isFocusable;
	ValueProperty isEnabled;
	ValueProperty isHovered;
	ValueProperty isVisible;
	
	void addEventHandler(T)(T handler)
	{
		static assert(isDelegate!T, "handler must be a delegate, not " ~ T.stringof);
		alias widgetType = ParameterTypeTuple!T[0];
		alias eventType = ParameterTypeTuple!T[1];
		static assert(!is(eventType == Event), "handler's parameter must not be Event class but inherited one");
		static assert(is(eventType : Event), "handler's parameter must be inherited from Event class");
		static assert(is(widgetType : Widget), "handler must accept Widget as first parameter");
		static assert(ParameterTypeTuple!T.length == 2, "handler must have only two parameters, Widget's and Event's descendant");
		_eventHandlers[typeid(eventType)] ~= cast(bool delegate(Widget, Event))handler;
	}

	void removeEventHandlers(T)()
	{
		_eventHandlers[typeid(T)] = null;
	}

	/// Returns true if event was handled
	/// This handler will be called by Gui class twice, before and after visiting its children.
	/// In first case sinking flag will be true;
	bool handleEvent(Event e)
	{
		bool result = false;
		if (auto handlers = typeid(e) in _eventHandlers)
		{
			foreach(h; *handlers)
			{
				result |= h(this, e);
			}
		}
		return result;
	}
	
	/// Event handlers.
	bool delegate(Widget, Event)[][TypeInfo] _eventHandlers;
}

void addChild(Widget root, Widget child)
in
{
	assert(root);
	assert(child);
}
body
{
	Widget* container;
	container = root.peekPropertyAs!("container", Widget);

	if (container is null) container = &root;
	assert(*container);

	Widget parent = *container;

	parent.setProperty!"children"(parent["children"] ~ child);
	child.setProperty!"parent"(parent);
}

/// Says to global layout manager that this widget needs layout update.
void invalidateLayout(Widget widget)
{
	widget.getPropertyAs!("context", GuiContext).invalidateWidgetLayout(widget);
}