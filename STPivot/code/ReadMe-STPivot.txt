To deploy STPivot in your Pentaho BI Server, all you need to do is:

1. Extract downloaded stpivot*.zip into Pentaho's biserver-ce folder. You will probably need to rewrite some files.

2. Edit Pentaho's web.xml ("tomcat/webapps/pentaho/WEB-INF/web.xml") to add lines containned in "tomcat/webapps/pentaho/WEB-INF/add-to-web.xml"

3. Restart Pentaho BI Server

4. Test if it works by going to: "http://localhost:8080/pentaho/STPivot?solution=stpivot-demos&path=&action=demo_clickables.analysisview.xaction&userid=joe&password=password"

In order to use STpivot instead of default Pivot viewer, you need to change the viewer in the Pivot component (in the .xaction), or construct an URL like in step 4.

You can actually replace the original Pivot with STPivot, changing all references to "/jsp/Pivot*.jsp" in Pentaho's web.xml to "stpivot/STPivot*.jsp".
Nevertheless they can coexist and be used by setting the viewer option (in PivotComponent) to Pivot or STPivot.

Please, visit the project home (http://code.google.com/p/stpivot/) to give your feedback and contributions.

ROADMAP
. Release a new branch independent from Pentaho, so other projects using JPivot can also benefit from STPivot.
. Upgrade charting engine, perhaps using some new javaScript library such as HighCharts.
. Build a new PivotComponentView for Pentaho, to enhance definition of clickables and XML/A mode
. Rewrite the whole frontend, using dojo as the foundation for user interface.
. Replace jpivot tags and libraries for those provided by Olap4j, alog with the possibility to interact with a wider range of OLAP providers.
. Improve stats summary when selecting table cells
. Enhance the exporting features (allow users to indicate the name of file, include the slicer in result, ...)
. Review I18N of the entire UI

KNOWN ISSUES
. Multiple links over one member doesn't work as expected in Explorer or Chrome (the dialog gets open to far away from cursor). 

CHANGE LOG

From stpivot(beta version) to stpivot(v1.0):
. "Save" and "Save as" options enabled
. Enhanced MDX Editor (now using CodeMirror)
. Easy to use multi-cell selection, in order to obtain quickly the Sum, Avg, Min & Max
. Navigator buttons allways on top-right side (as suggested by Andrea Pasotti)
. Updated & Tested to work with Pentaho biserver-ce from version 3.6.0 to 3.9.0, and code cleansed to reduce differents blocks compared with original Pivot.jsp (from Pentaho)
. Posibility to externally change the MDX query (ie: when in an iFrame) and refresh the viewer without reloading the entire page.
. New formula editor functionality to add/edit CalculatedMembers and NameSets.
. New workaround to link members (using <jp:clickable> tags) in a parameterized fashion
. Posibility to access cubes in XMLA mode.
. Sample code added to demonstrate new features

From original Pivot to stpivot(beta version)
. Ajax interface
. Use of jQuery to handle user interactions
. Highlighted MDX syntax in the editor (based on CodePress)
. Easier edition of charts (resizing with mouse, icons for options)
. New set of icons