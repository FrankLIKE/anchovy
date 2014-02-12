/*
Copyright (c) 2013-2014 Andrey Penechko

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

module anchovy.gui.templateparser;

import sdlang;

import anchovy.gui.widgettemplate;

import anchovy.gui.all;

class TemplateParser
{
	WidgetTemplate[] parse(string source, string filename = "")
	{
		WidgetTemplate[] templates;

		Tag root;
	
		try
		{
			root = parseSource(source, filename);
		}
		catch(SDLangParseException e)
		{
			stderr.writeln(e.msg);
			return null;
		}

		foreach(templ; root.maybe.namespaces["template"].tags)
		{
			parseTemplate(templ);
		}

		return templates;
	}

	WidgetTemplate parseTemplate(Tag templateTag)
	{
		WidgetTemplate templ = new WidgetTemplate;
		Tag propertiesTag;
		Tag treeTag;

		void parsePropertiesSection(Tag section)
		{
			writeln("properties");
			writeln(section.toDebugString);
		}

		SubwidgetTemplate parseTreeSection(Tag section)
		{
			auto subwidget = new SubwidgetTemplate;

			// Adding subwidgets.
			foreach(sub; section.tags)
			{
				auto subsub = parseTreeSection(sub);
				subwidget.subwidgets ~= subsub;

				if (auto nameProperty = "name" in subsub.properties)
				{
					templ.subwidgetsmap[nameProperty.coerce!string] = subsub;
				}
			}

			// Adding widget properties.
			foreach(prop; section.attributes)
			{
				subwidget.properties[prop.name] = cast(Variant)prop.value;
			}

			// Adding widget flags.
			foreach(value; section.values)
			{
				subwidget.properties[value.coerce!string] = Variant(true);
			}

			subwidget.properties["type"] = section.name;

			return subwidget;
		}

		foreach(section; templateTag.tags)
		{
			switch(section.name)
			{
				case "properties":
					propertiesTag = section;
					break;
				case "tree":
					treeTag = section;
					break;
				default:
					writeln("unknown template section found: ", section.name);
			}
		}

		templ.tree = parseTreeSection(treeTag);
		templ.tree.properties["type"] = templateTag.name;

		return templ;
	}
}