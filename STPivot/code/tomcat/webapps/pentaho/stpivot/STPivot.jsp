<%@ page session="true" contentType="text/html;"
  import="
  java.util.*,
  java.io.ByteArrayOutputStream,
  javax.sql.DataSource,
  org.dom4j.DocumentHelper,
  org.dom4j.Element,
  org.dom4j.Document,
  org.pentaho.platform.util.VersionHelper,
  org.pentaho.platform.util.UUIDUtil,
    org.pentaho.platform.util.StringUtil,
  org.pentaho.platform.util.web.SimpleUrlFactory,
  org.pentaho.platform.util.messages.LocaleHelper,
    org.pentaho.platform.api.data.IDatasourceService,
    org.pentaho.platform.api.engine.IPentahoSession,
    org.pentaho.platform.api.engine.ISolutionEngine,
    org.pentaho.platform.api.engine.IRuntimeContext,
    org.pentaho.platform.api.repository.ISubscriptionRepository,
  org.pentaho.platform.engine.core.output.SimpleOutputHandler,
  org.pentaho.platform.engine.core.system.PentahoSystem,
  org.pentaho.platform.engine.services.solution.SimpleParameterSetter,
  org.pentaho.platform.engine.core.solution.ActionInfo,
  org.pentaho.platform.web.http.PentahoHttpSessionHelper,
    org.pentaho.platform.web.http.WebTemplateHelper,
    org.pentaho.platform.web.http.request.HttpRequestParameterProvider,
    org.pentaho.platform.web.http.session.HttpSessionParameterProvider,
    org.pentaho.platform.web.jsp.messages.Messages,
 	org.pentaho.commons.connection.IPentahoConnection,
 	org.pentaho.platform.plugin.services.connections.mondrian.MDXConnection,
	org.pentaho.commons.connection.IPentahoResultSet,
	org.pentaho.platform.api.data.IDatasourceService,
	org.pentaho.platform.api.engine.IConnectionUserRoleMapper,
	org.pentaho.platform.engine.core.system.IPentahoLoggingConnection,
	org.pentaho.platform.engine.core.system.PentahoSessionHolder,
	org.pentaho.platform.engine.core.system.PentahoSystem,
  org.pentaho.platform.plugin.action.mondrian.PivotViewComponent,
  org.pentaho.platform.plugin.action.mondrian.AnalysisSaver,
  org.pentaho.platform.plugin.action.mondrian.MissingParameterException,
  org.pentaho.platform.repository.subscription.Subscription,
  org.pentaho.platform.repository.subscription.SubscriptionHelper,
  com.tonbeller.jpivot.table.TableComponent,
  com.tonbeller.jpivot.olap.model.OlapModel,
  com.tonbeller.jpivot.olap.model.Dimension,
  com.tonbeller.jpivot.olap.model.Result,
  com.tonbeller.jpivot.olap.model.Axis,
  com.tonbeller.jpivot.olap.model.Hierarchy,
  com.tonbeller.jpivot.olap.model.Level,
  com.tonbeller.jpivot.olap.model.Member,
  com.tonbeller.jpivot.olap.navi.MemberTree,
  com.tonbeller.jpivot.olap.navi.ExpressionParser,
  com.tonbeller.jpivot.olap.navi.MdxQuery,
  com.tonbeller.jpivot.olap.query.MDXElement,
  com.tonbeller.jpivot.olap.query.MDXLevel,
  com.tonbeller.jpivot.olap.query.MDXMember,
  com.tonbeller.jpivot.olap.model.Displayable,
  com.tonbeller.jpivot.navigator.Navigator,
  com.tonbeller.jpivot.tags.OlapModelProxy,
  com.tonbeller.jpivot.olap.model.OlapModelDecorator,
  com.tonbeller.jpivot.olap.query.MdxOlapModel,
  com.tonbeller.jpivot.mondrian.MondrianModel,
  com.tonbeller.jpivot.chart.ChartComponent,
  com.tonbeller.wcf.form.FormComponent,
  com.tonbeller.wcf.controller.MultiPartEnabledRequest,
  org.apache.log4j.MDC,
  com.tonbeller.wcf.controller.RequestContext,
  com.tonbeller.wcf.controller.RequestContextFactoryFinder,
  javax.servlet.jsp.jstl.core.Config,
  com.tonbeller.wcf.controller.Controller,
  com.tonbeller.wcf.controller.WcfController,
  org.owasp.esapi.ESAPI"
%><jsp:directive.page
  import="org.pentaho.platform.api.repository.ISolutionRepository" /><%
 // the following code replaces wcf's RequestFilter due to session based
 // synchronization logic that is no longer necessary. (PDB-369)
 MultiPartEnabledRequest mprequest = new MultiPartEnabledRequest((HttpServletRequest) request);
 HttpSession mpsession = mprequest.getSession(true);
 MDC.put("SessionID", mpsession.getId());
 String cpath = mprequest.getContextPath();
 mprequest.setAttribute("context", cpath);
 RequestContext wcfcontext = RequestContextFactoryFinder.createContext(mprequest, response, true);
 try {
   Config.set(mprequest, Config.FMT_LOCALE, wcfcontext.getLocale());
   Controller controller = WcfController.instance(session);
   controller.request(wcfcontext);
%><%@ 
   taglib uri="http://www.tonbeller.com/jpivot" prefix="jp"
%><%@ 
   taglib uri="http://www.tonbeller.com/wcf" prefix="wcf"
%><%@ 
   taglib prefix="c" uri="http://java.sun.com/jstl/core"
%><%

/*
 * Copyright 2006-2009 Pentaho Corporation.  All rights reserved. 
 * This software was developed by Pentaho Corporation and is provided under the terms 
 * of the Mozilla Public License, Version 1.1, or any later version. You may not use 
 * this file except in compliance with the license. If you need a copy of the license, 
 * please go to http://www.mozilla.org/MPL/MPL-1.1.txt. The Original Code is the Pentaho 
 * BI Platform.  The Initial Developer is Pentaho Corporation.
 *
 * Software distributed under the Mozilla Public License is distributed on an "AS IS" 
 * basis, WITHOUT WARRANTY OF ANY KIND, either express or  implied. Please refer to 
 * the license for the specific language governing your rights and limitations.
*/

  response.setCharacterEncoding(LocaleHelper.getSystemEncoding());
  PentahoSystem.systemEntryPoint();
  try {
  IPentahoSession userSession = PentahoHttpSessionHelper.getPentahoSession( request );

  String pivotId = null;
  if (request.getParameter("pivotId") != null) {
    pivotId = request.getParameter("pivotId");
  } else {
    pivotId = UUIDUtil.getUUIDAsString();
    if( pivotId == null ) {
      // TODO need to log an error here
      return;
    }
  }

  // this allows navigation renderer to have access to the pivotId, which it uses
  // in an href link back to itself.
  Map map = new HashMap();
  map.put("pivotId", pivotId);
  request.setAttribute("com.tonbeller.wcf.component.RendererParameters", map);
  
  int saveResult = 0;
  String saveMessage = "";
  String queryId = "query"+pivotId; //$NON-NLS-1$
  String mdxEditId = "mdxedit" + pivotId;
  String tableId = "table" + pivotId;
  String titleId = PivotViewComponent.TITLE+pivotId;
  String optionsId = "pivot-"+PivotViewComponent.OPTIONS+"-"+pivotId; //$NON-NLS-1$
  String chartId = "chart" + pivotId;
  String naviId = "navi" + pivotId;
  String sortFormId = "sortform" + pivotId;
  String axisFormId = "axisform" + pivotId;
  String chartFormId = "chartform" + pivotId;
  String printId = "print" + pivotId;
  String printFormId = "printform" + pivotId;
  String drillThroughTableId = queryId + ".drillthroughtable";
  String toolbarId = "toolbar" + pivotId;

  // Internal JPivot References, if available.  Note that these references change
  // after each creation tag within the JSP.
  OlapModel _olapModel = (OlapModel)session.getAttribute(queryId);
  FormComponent _mdxEdit = (FormComponent)session.getAttribute(mdxEditId);
  TableComponent _table = (TableComponent) session.getAttribute(tableId);
  ChartComponent _chart = (ChartComponent) session.getAttribute(chartId);
  Navigator _navi = (Navigator)session.getAttribute(naviId);

  boolean authenticated = userSession.getName() != null;
  String pageName = "STPivot"; //$NON-NLS-1$

  String solutionName = request.getParameter( "solution" ); //$NON-NLS-1$
  String actionPath = request.getParameter( "path" ); //$NON-NLS-1$
  String actionName = request.getParameter( "action" ); //$NON-NLS-1$

  String actionReference = (String) session.getAttribute("pivot-action-"+pivotId); //$NON-NLS-1$

  String subscribeResult = null;
  String subscribeAction = request.getParameter( "subscribe" ); //$NON-NLS-1$
  String saveAction = request.getParameter( "save-action"); //$NON-NLS-1$

  String provider = null;
  String catalog = null;
  String clickables = null;
  String dataSource = null;
  String catalogUri = null;
  String query = null;  
  String role  = null;
  String pivotTitle = (String) session.getAttribute( "pivot-"+PivotViewComponent.TITLE+"-"+pivotId ); //$NON-NLS-1$
  String actionTitle = (String) session.getAttribute( "action-"+PivotViewComponent.TITLE+"-"+pivotId );;
  ArrayList options = (ArrayList) session.getAttribute( optionsId );
  boolean chartChange = false;
  boolean showGrid = true;
  /*
  if( session.getAttribute( "save-message-01") != null ) {
    saveMessage = ((String) session.getAttribute("save-message-01"));
  }
  */
  if( session.getAttribute( "pivot-"+PivotViewComponent.SHOWGRID+"-"+pivotId ) != null ) {
    showGrid = ((Boolean) session.getAttribute("pivot-"+PivotViewComponent.SHOWGRID+"-"+pivotId)).booleanValue();
  }
  if (session.getAttribute( "pivot-"+PivotViewComponent.MODEL+"-"+pivotId ) != null ) { //$NON-NLS-1$
      catalogUri = (String)session.getAttribute( "pivot-"+PivotViewComponent.MODEL+"-"+pivotId );
  }
  
  int chartType = 1;
  if ( session.getAttribute( "pivot-"+PivotViewComponent.CHARTTYPE+"-"+pivotId ) != null ) { //$NON-NLS-1$
    chartType = ((Integer) session.getAttribute( "pivot-"+PivotViewComponent.CHARTTYPE+"-"+pivotId )).intValue(); //$NON-NLS-1$
  }
  String chartLocation = "bottom"; //$NON-NLS-1$
  if ( session.getAttribute( "pivot-"+PivotViewComponent.CHARTLOCATION+"-"+pivotId ) != null ) { //$NON-NLS-1$
    chartLocation = (String) session.getAttribute( "pivot-"+PivotViewComponent.CHARTLOCATION+"-"+pivotId );
  }
  int chartWidth = -1;
  if ( session.getAttribute( "pivot-"+PivotViewComponent.CHARTWIDTH+"-"+pivotId ) != null ) {
    chartWidth = ((Integer)session.getAttribute( "pivot-"+PivotViewComponent.CHARTWIDTH+"-"+pivotId )).intValue();
  }
  int chartHeight = -1;
  if ( session.getAttribute( "pivot-"+PivotViewComponent.CHARTHEIGHT+"-"+pivotId ) != null ) {
    chartHeight = ((Integer) session.getAttribute( "pivot-"+PivotViewComponent.CHARTHEIGHT+"-"+pivotId )).intValue();
  }
  boolean chartDrillThroughEnabled = false;
  /*
  if ( session.getAttribute( "pivot-"+PivotViewComponent.CHARTDRILLTHROUGHENABLED+"-"+pivotId ) != null ) {
    chartDrillThroughEnabled = ((Boolean) session.getAttribute( "pivot-"+PivotViewComponent.CHARTDRILLTHROUGHENABLED+"-"+pivotId )).booleanValue();
  }
  */
  String chartTitle = "";
  if (session.getAttribute( "pivot-"+PivotViewComponent.CHARTTITLE+"-"+pivotId) != null ) {
    chartTitle = session.getAttribute( "pivot-"+PivotViewComponent.CHARTTITLE+"-"+pivotId).toString() ;
  }
  String chartTitleFontFamily = "";
  if (session.getAttribute( "pivot-"+PivotViewComponent.CHARTTITLEFONTFAMILY+"-"+pivotId) != null ) {
    chartTitleFontFamily = session.getAttribute( "pivot-"+PivotViewComponent.CHARTTITLEFONTFAMILY+"-"+pivotId).toString();
  }
  int chartTitleFontStyle = -1;
  if (session.getAttribute( "pivot-"+PivotViewComponent.CHARTTITLEFONTSTYLE+"-"+pivotId) != null ) {
    chartTitleFontStyle = ((Integer)session.getAttribute( "pivot-"+PivotViewComponent.CHARTTITLEFONTSTYLE+"-"+pivotId)).intValue();
  }
  int chartTitleFontSize = -1;
  if (session.getAttribute( "pivot-"+PivotViewComponent.CHARTTITLEFONTSIZE+"-"+pivotId) != null ) {
    chartTitleFontSize = ((Integer)session.getAttribute( "pivot-"+PivotViewComponent.CHARTTITLEFONTSIZE+"-"+pivotId)).intValue();
  }
  String chartHorizAxisLabel = "";
  if (session.getAttribute( "pivot-"+PivotViewComponent.CHARTHORIZAXISLABEL+"-"+pivotId) != null ) {
    chartHorizAxisLabel = session.getAttribute( "pivot-"+PivotViewComponent.CHARTHORIZAXISLABEL+"-"+pivotId).toString();
  }
  String chartVertAxisLabel = "";
  if (session.getAttribute( "pivot-"+PivotViewComponent.CHARTVERTAXISLABEL+"-"+pivotId) != null ) {
    chartVertAxisLabel = session.getAttribute( "pivot-"+PivotViewComponent.CHARTVERTAXISLABEL+"-"+pivotId).toString();
  }
  String chartAxisLabelFontFamily = "";
  if (session.getAttribute( "pivot-"+PivotViewComponent.CHARTAXISLABELFONTFAMILY+"-"+pivotId) != null ) {
    chartAxisLabelFontFamily = session.getAttribute( "pivot-"+PivotViewComponent.CHARTAXISLABELFONTFAMILY+"-"+pivotId).toString();
  }
  int chartAxisLabelFontStyle = -1;
  if (session.getAttribute( "pivot-"+PivotViewComponent.CHARTAXISLABELFONTSTYLE+"-"+pivotId) != null ) {
    chartAxisLabelFontStyle = ((Integer)session.getAttribute( "pivot-"+PivotViewComponent.CHARTAXISLABELFONTSTYLE+"-"+pivotId)).intValue();
  }
  int chartAxisLabelFontSize = -1;
  if (session.getAttribute( "pivot-"+PivotViewComponent.CHARTAXISLABELFONTSIZE+"-"+pivotId) != null ) {
    chartAxisLabelFontSize = ((Integer)session.getAttribute( "pivot-"+PivotViewComponent.CHARTAXISLABELFONTSIZE+"-"+pivotId)).intValue();
  }
  String chartAxisTickFontFamily = "";
  if (session.getAttribute( "pivot-"+PivotViewComponent.CHARTAXISTICKFONTFAMILY+"-"+pivotId) != null ) {
    chartAxisTickFontFamily = session.getAttribute( "pivot-"+PivotViewComponent.CHARTAXISTICKFONTFAMILY+"-"+pivotId).toString();
  }
  int chartAxisTickFontStyle = -1;
  if (session.getAttribute( "pivot-"+PivotViewComponent.CHARTAXISTICKFONTSTYLE+"-"+pivotId) != null ) {
    chartAxisTickFontStyle = ((Integer)session.getAttribute( "pivot-"+PivotViewComponent.CHARTAXISTICKFONTSTYLE+"-"+pivotId)).intValue();
  }
  int chartAxisTickFontSize = -1;
  if (session.getAttribute( "pivot-"+PivotViewComponent.CHARTAXISTICKFONTSIZE+"-"+pivotId) != null ) {
    chartAxisTickFontSize = ((Integer)session.getAttribute( "pivot-"+PivotViewComponent.CHARTAXISTICKFONTSIZE+"-"+pivotId)).intValue();
  }
  int chartAxisTickLabelRotation = -1;
  if (session.getAttribute( "pivot-"+PivotViewComponent.CHARTAXISTICKLABELROTATION+"-"+pivotId) != null ) {
    chartAxisTickLabelRotation = ((Integer)session.getAttribute( "pivot-"+PivotViewComponent.CHARTAXISTICKLABELROTATION+"-"+pivotId)).intValue();
  }
  boolean chartShowLegend = false;
  if ( session.getAttribute( "pivot-"+PivotViewComponent.CHARTSHOWLEGEND+"-"+pivotId ) != null ) {
    chartShowLegend = ((Boolean) session.getAttribute( "pivot-"+PivotViewComponent.CHARTSHOWLEGEND+"-"+pivotId )).booleanValue();
  }
  int chartLegendLocation = -1;
  if (session.getAttribute( "pivot-"+PivotViewComponent.CHARTLEGENDLOCATION+"-"+pivotId) != null ) {
    chartLegendLocation = ((Integer)session.getAttribute( "pivot-"+PivotViewComponent.CHARTLEGENDLOCATION+"-"+pivotId)).intValue();
  }
  String chartLegendFontFamily = "";
  if (session.getAttribute( "pivot-"+PivotViewComponent.CHARTLEGENDFONTFAMILY+"-"+pivotId) != null ) {
    chartLegendFontFamily = session.getAttribute( "pivot-"+PivotViewComponent.CHARTLEGENDFONTFAMILY+"-"+pivotId).toString();
  }
  int chartLegendFontStyle = -1;
  if (session.getAttribute( "pivot-"+PivotViewComponent.CHARTLEGENDFONTSTYLE+"-"+pivotId) != null ) {
    chartLegendFontStyle = ((Integer)session.getAttribute( "pivot-"+PivotViewComponent.CHARTLEGENDFONTSTYLE+"-"+pivotId)).intValue();
  }
    int chartLegendFontSize = -1;
  if (session.getAttribute( "pivot-"+PivotViewComponent.CHARTLEGENDFONTSIZE+"-"+pivotId) != null ) {
    chartLegendFontSize = ((Integer)session.getAttribute( "pivot-"+PivotViewComponent.CHARTLEGENDFONTSIZE+"-"+pivotId)).intValue();
  }
    boolean chartShowSlicer = false;
  if ( session.getAttribute( "pivot-"+PivotViewComponent.CHARTSHOWSLICER+"-"+pivotId ) != null ) {
    chartShowSlicer = ((Boolean) session.getAttribute( "pivot-"+PivotViewComponent.CHARTSHOWSLICER+"-"+pivotId )).booleanValue();
  }
    int chartSlicerLocation = -1;
  if (session.getAttribute( "pivot-"+PivotViewComponent.CHARTSLICERLOCATION+"-"+pivotId) != null ) {
    chartSlicerLocation = ((Integer)session.getAttribute( "pivot-"+PivotViewComponent.CHARTSLICERLOCATION+"-"+pivotId)).intValue();
  }
  int chartSlicerAlignment = -1;
  if (session.getAttribute( "pivot-"+PivotViewComponent.CHARTSLICERALIGNMENT+"-"+pivotId) != null ) {
    chartSlicerAlignment = ((Integer)session.getAttribute( "pivot-"+PivotViewComponent.CHARTSLICERALIGNMENT+"-"+pivotId)).intValue();
  }
  String chartSlicerFontFamily = "";
  if (session.getAttribute( "pivot-"+PivotViewComponent.CHARTSLICERFONTFAMILY+"-"+pivotId) != null ) {
    chartSlicerFontFamily = session.getAttribute( "pivot-"+PivotViewComponent.CHARTSLICERFONTFAMILY+"-"+pivotId).toString();
  }
  int chartSlicerFontStyle = -1;
  if (session.getAttribute( "pivot-"+PivotViewComponent.CHARTSLICERFONTSTYLE+"-"+pivotId) != null ) {
    chartSlicerFontStyle = ((Integer)session.getAttribute( "pivot-"+PivotViewComponent.CHARTSLICERFONTSTYLE+"-"+pivotId)).intValue();
  }
    int chartSlicerFontSize = -1;
  if (session.getAttribute( "pivot-"+PivotViewComponent.CHARTSLICERFONTSIZE+"-"+pivotId) != null ) {
    chartSlicerFontSize = ((Integer)session.getAttribute( "pivot-"+PivotViewComponent.CHARTSLICERFONTSIZE+"-"+pivotId)).intValue();
  }   
    int chartBackgroundR = -1;
  if (session.getAttribute( "pivot-"+PivotViewComponent.CHARTBACKGROUNDR+"-"+pivotId) != null ) {
    chartBackgroundR = ((Integer)session.getAttribute( "pivot-"+PivotViewComponent.CHARTBACKGROUNDR+"-"+pivotId)).intValue();
  } 
    int chartBackgroundG = -1;
  if (session.getAttribute( "pivot-"+PivotViewComponent.CHARTBACKGROUNDG+"-"+pivotId) != null ) {
    chartBackgroundG = ((Integer)session.getAttribute( "pivot-"+PivotViewComponent.CHARTBACKGROUNDG+"-"+pivotId)).intValue();
  }
    int chartBackgroundB = -1;
  if (session.getAttribute( "pivot-"+PivotViewComponent.CHARTBACKGROUNDB+"-"+pivotId) != null ) {
    chartBackgroundB = ((Integer)session.getAttribute( "pivot-"+PivotViewComponent.CHARTBACKGROUNDB+"-"+pivotId)).intValue();
  }
      
  if( solutionName != null && actionPath != null && actionName != null ) {
      // we need to initialize from an action sequence document

    IRuntimeContext context = null;
    try {
      context = getRuntimeForQuery( solutionName, actionPath, actionName, request, userSession );
      if( context != null && context.getStatus() == IRuntimeContext.RUNTIME_STATUS_SUCCESS ) {
          if (context.getOutputNames().contains("uri") && context.getOutputParameter("uri")!=null) {
            provider = "xmla";
            try {
              catalogUri = context.getOutputParameter( "uri" ).getStringValue();
              session.setAttribute("pivot-"+PivotViewComponent.MODEL+"-"+pivotId, catalogUri);
              dataSource = context.getOutputParameter( "datasource" ).getStringValue(); dataSource = (dataSource==null)?"":dataSource;
              catalog = context.getOutputParameter( "catalog" ).getStringValue();
            } catch (Exception e) {
            }
          } else
          if (context.getOutputNames().contains(PivotViewComponent.MODEL)) {
            provider = "mondrian";
            try {
              catalogUri = context.getOutputParameter( PivotViewComponent.MODEL ).getStringValue(); //$NON-NLS-1$
              session.setAttribute("pivot-"+PivotViewComponent.MODEL+"-"+pivotId, catalogUri);
              
              dataSource = context.getOutputParameter( PivotViewComponent.CONNECTION ).getStringValue(); //$NON-NLS-1$
              
              if (context.getOutputNames().contains(PivotViewComponent.ROLE)) { //$NON-NLS-1$
                role = context.getOutputParameter( PivotViewComponent.ROLE ).getStringValue(); //$NON-NLS-1$
              }
              
              if ((role==null) || (role.trim().length()==0)){
                // Only if the action sequence/requester hasn't already injected a role in here do this.
                if(PentahoSystem.getObjectFactory().objectDefined(MDXConnection.MDX_CONNECTION_MAPPER_KEY)) {
                  IConnectionUserRoleMapper mondrianUserRoleMapper = PentahoSystem.get(IConnectionUserRoleMapper.class, MDXConnection.MDX_CONNECTION_MAPPER_KEY, null);
                  if (mondrianUserRoleMapper != null) {
                  // Do role mapping
                  	String[] validMondrianRolesForUser = mondrianUserRoleMapper.mapConnectionRoles(PentahoSessionHolder.getSession(), catalogUri);
                  	if ( (validMondrianRolesForUser != null) && (validMondrianRolesForUser.length>0) ) {
                  	StringBuffer buff = new StringBuffer();
                  	String aRole = null;
                  	for (int i=0; i<validMondrianRolesForUser.length; i++) {
                  	  aRole = validMondrianRolesForUser[i];
                  	  // According to http://mondrian.pentaho.org/documentation/configuration.php
                  	  // double-comma escapes a comma
                  	  if (i>0) {
                  	    buff.append(",");
                  	  }
                  	  buff.append(aRole.replaceAll(",", ",,"));
                  	}
                  	role = buff.toString();
										}
									}
								}
							}
						} catch (Exception e) {
						}
					}
					
					query = context.getOutputParameter( "mdx" ).getStringValue(); //$NON-NLS-1$
					
					if (context.getOutputNames().contains( "clickables" )) {
						clickables = context.getOutputParameter( "clickables" ).getStringValue();
					}
					
					if (catalogUri == null || dataSource == null || query == null) {
						throw new Exception(Messages.getErrorString("UI.ERROR_0003_XACTION_INVALID_OUTPUTS", ActionInfo.buildSolutionPath(solutionName,actionPath,actionName), "Catalog URI=" + catalogUri + "; Data Source=" + dataSource + "; MDX Query=" + query, "isPromptPending=" + context.isPromptPending()));
					}
					
					if( context.getOutputNames().contains( PivotViewComponent.CHARTTYPE ) ) { //$NON-NLS-1$
						try {
							chartType = Integer.parseInt( context.getOutputParameter( PivotViewComponent.CHARTTYPE ).getStringValue() ); //$NON-NLS-1$
							session.setAttribute( "pivot-"+PivotViewComponent.CHARTTYPE+"-"+pivotId, new Integer(chartType) ); //$NON-NLS-1$
							
						} catch (Exception e) {
						}
					} else {
						chartType = 1;
					}
					if (context.getOutputNames().contains(PivotViewComponent.SHOWGRID) ) {
						try {
							showGrid = Boolean.valueOf(context.getOutputParameter( PivotViewComponent.SHOWGRID ).getStringValue()).booleanValue();
							session.setAttribute("pivot-"+PivotViewComponent.SHOWGRID+"-"+pivotId, new Boolean(showGrid));
						} catch (Exception e) {
						}
					} else {
						showGrid = true;
					}
					if (context.getOutputNames().contains(PivotViewComponent.CHARTWIDTH) ) { //$NON-NLS-1$
						try {
							chartWidth = Integer.parseInt( context.getOutputParameter( PivotViewComponent.CHARTWIDTH ).getStringValue() ); //$NON-NLS-1$
							session.setAttribute( "pivot-"+PivotViewComponent.CHARTWIDTH+"-"+pivotId, new Integer(chartWidth) ); //$NON-NLS-1$
						} catch (Exception e) {
						}
					} else {
						chartWidth = 500;  // Default from ChartComponent
					}
					if (context.getOutputNames().contains(PivotViewComponent.CHARTHEIGHT) ) { //$NON-NLS-1$
						try {
							chartHeight = Integer.parseInt( context.getOutputParameter( PivotViewComponent.CHARTHEIGHT ).getStringValue() ); //$NON-NLS-1$
							session.setAttribute( "pivot-"+PivotViewComponent.CHARTHEIGHT+"-"+pivotId, new Integer(chartHeight) ); //$NON-NLS-1$
						} catch (Exception e) {
						}
					} else {
						chartHeight = 300; // Default from ChartComponent
					}
					if( context.getOutputNames().contains( PivotViewComponent.CHARTLOCATION ) ) { //$NON-NLS-1$
						chartLocation = context.getOutputParameter( PivotViewComponent.CHARTLOCATION ).getStringValue(); //$NON-NLS-1$
						session.setAttribute( "pivot-"+PivotViewComponent.CHARTLOCATION+"-"+pivotId, chartLocation ); //$NON-NLS-1$
					} else {
						chartLocation = "none"; //$NON-NLS-1$
					}
					chartDrillThroughEnabled = false;
					/* // This option will not be available in stpivot
					if( context.getOutputNames().contains( PivotViewComponent.CHARTDRILLTHROUGHENABLED )) {
						chartDrillThroughEnabled = Boolean.valueOf(context.getOutputParameter( PivotViewComponent.CHARTDRILLTHROUGHENABLED ).getStringValue()).booleanValue();
						session.setAttribute("pivot-"+PivotViewComponent.CHARTDRILLTHROUGHENABLED+"-"+pivotId, new Boolean(chartDrillThroughEnabled));
					} else {
						chartDrillThroughEnabled = false;
					}
					*/
					if( context.getOutputNames().contains( PivotViewComponent.CHARTTITLE ) ) {
						chartTitle = context.getOutputParameter( PivotViewComponent.CHARTTITLE ).getStringValue();
						session.setAttribute( "pivot-"+PivotViewComponent.CHARTTITLE+"-"+pivotId, chartTitle );
					} else {
						chartTitle = "";
					}
					if( context.getOutputNames().contains( PivotViewComponent.CHARTTITLEFONTFAMILY ) ) {
						chartTitleFontFamily = context.getOutputParameter( PivotViewComponent.CHARTTITLEFONTFAMILY ).getStringValue();
						session.setAttribute( "pivot-"+PivotViewComponent.CHARTTITLEFONTFAMILY+"-"+pivotId, chartTitleFontFamily );
					} else {
						chartTitleFontFamily = "SansSerif";
					}
					if( context.getOutputNames().contains( PivotViewComponent.CHARTTITLEFONTSTYLE ) ) {
						chartTitleFontStyle = Integer.parseInt(context.getOutputParameter( PivotViewComponent.CHARTTITLEFONTSTYLE ).getStringValue());
						session.setAttribute( "pivot-"+PivotViewComponent.CHARTTITLEFONTSTYLE+"-"+pivotId, new Integer(chartTitleFontStyle));
					} else {
						chartTitleFontStyle = java.awt.Font.BOLD;
					}
					if( context.getOutputNames().contains( PivotViewComponent.CHARTTITLEFONTSIZE ) ) {
						chartTitleFontSize = Integer.parseInt(context.getOutputParameter( PivotViewComponent.CHARTTITLEFONTSIZE ).getStringValue());
						session.setAttribute( "pivot-"+PivotViewComponent.CHARTTITLEFONTSIZE+"-"+pivotId, new Integer(chartTitleFontSize));
					} else {
						chartTitleFontSize = 18;
					}
					if( context.getOutputNames().contains( PivotViewComponent.CHARTHORIZAXISLABEL ) ) {
						chartHorizAxisLabel = context.getOutputParameter( PivotViewComponent.CHARTHORIZAXISLABEL ).getStringValue();
						session.setAttribute( "pivot-"+PivotViewComponent.CHARTHORIZAXISLABEL+"-"+pivotId, chartHorizAxisLabel );
					} else {
						chartHorizAxisLabel = "";
					}
					if( context.getOutputNames().contains( PivotViewComponent.CHARTVERTAXISLABEL ) ) {
						chartVertAxisLabel = context.getOutputParameter( PivotViewComponent.CHARTVERTAXISLABEL ).getStringValue();
						session.setAttribute( "pivot-"+PivotViewComponent.CHARTVERTAXISLABEL+"-"+pivotId, chartVertAxisLabel );
					} else {
						chartVertAxisLabel = "";
					}
					if( context.getOutputNames().contains( PivotViewComponent.CHARTAXISLABELFONTFAMILY ) ) {
						chartAxisLabelFontFamily = context.getOutputParameter( PivotViewComponent.CHARTAXISLABELFONTFAMILY ).getStringValue();
						session.setAttribute( "pivot-"+PivotViewComponent.CHARTAXISLABELFONTFAMILY+"-"+pivotId, chartAxisLabelFontFamily );
					} else {
						chartAxisLabelFontFamily = "SansSerif";
					}
					if( context.getOutputNames().contains( PivotViewComponent.CHARTAXISLABELFONTSTYLE ) ) {
						chartAxisLabelFontStyle = Integer.parseInt(context.getOutputParameter( PivotViewComponent.CHARTAXISLABELFONTSTYLE ).getStringValue());
						session.setAttribute( "pivot-"+PivotViewComponent.CHARTAXISLABELFONTSTYLE+"-"+pivotId, new Integer(chartAxisLabelFontStyle));
					} else {
						chartAxisLabelFontStyle = java.awt.Font.PLAIN;
					}
					if( context.getOutputNames().contains( PivotViewComponent.CHARTAXISLABELFONTSIZE ) ) {
						chartAxisLabelFontSize = Integer.parseInt(context.getOutputParameter( PivotViewComponent.CHARTAXISLABELFONTSIZE ).getStringValue());
						session.setAttribute( "pivot-"+PivotViewComponent.CHARTAXISLABELFONTSIZE+"-"+pivotId, new Integer(chartAxisLabelFontSize));
					} else {
						chartAxisLabelFontSize = 12;
					}
					if( context.getOutputNames().contains( PivotViewComponent.CHARTAXISTICKFONTFAMILY ) ) {
						chartAxisTickFontFamily = context.getOutputParameter( PivotViewComponent.CHARTAXISTICKFONTFAMILY ).getStringValue();
						session.setAttribute( "pivot-"+PivotViewComponent.CHARTAXISTICKFONTFAMILY+"-"+pivotId, chartAxisTickFontFamily );
					} else {
						chartAxisTickFontFamily = "SansSerif";
					}
					if( context.getOutputNames().contains( PivotViewComponent.CHARTAXISTICKFONTSTYLE ) ) {
						chartAxisTickFontStyle = Integer.parseInt(context.getOutputParameter( PivotViewComponent.CHARTAXISTICKFONTSTYLE ).getStringValue());
						session.setAttribute( "pivot-"+PivotViewComponent.CHARTAXISTICKFONTSTYLE+"-"+pivotId, new Integer(chartAxisTickFontStyle));
					} else {
						chartAxisTickFontStyle = java.awt.Font.PLAIN;
					}
					if( context.getOutputNames().contains( PivotViewComponent.CHARTAXISTICKFONTSIZE ) ) {
						chartAxisTickFontSize = Integer.parseInt(context.getOutputParameter( PivotViewComponent.CHARTAXISTICKFONTSIZE ).getStringValue());
						session.setAttribute( "pivot-"+PivotViewComponent.CHARTAXISTICKFONTSIZE+"-"+pivotId, new Integer(chartAxisTickFontSize));
					} else {
						chartAxisTickFontSize = 12;
					}
					if( context.getOutputNames().contains( PivotViewComponent.CHARTAXISTICKLABELROTATION ) ) {
						chartAxisTickLabelRotation = Integer.parseInt(context.getOutputParameter( PivotViewComponent.CHARTAXISTICKLABELROTATION ).getStringValue());
						session.setAttribute( "pivot-"+PivotViewComponent.CHARTAXISTICKLABELROTATION+"-"+pivotId, new Integer(chartAxisTickLabelRotation));
					} else {
						chartAxisTickLabelRotation = 30;
					}
					if( context.getOutputNames().contains( PivotViewComponent.CHARTSHOWLEGEND )) {
						chartShowLegend = Boolean.valueOf(context.getOutputParameter( PivotViewComponent.CHARTSHOWLEGEND ).getStringValue()).booleanValue();
						session.setAttribute("pivot-"+PivotViewComponent.CHARTSHOWLEGEND+"-"+pivotId, new Boolean(chartShowLegend));
					} else {
						chartShowLegend = true;
					}
					if( context.getOutputNames().contains( PivotViewComponent.CHARTLEGENDLOCATION ) ) {
						chartLegendLocation = Integer.parseInt(context.getOutputParameter( PivotViewComponent.CHARTLEGENDLOCATION ).getStringValue());
						session.setAttribute( "pivot-"+PivotViewComponent.CHARTLEGENDLOCATION+"-"+pivotId, new Integer(chartLegendLocation));
					} else {
						chartLegendLocation = 3;
					}
					if( context.getOutputNames().contains( PivotViewComponent.CHARTLEGENDFONTFAMILY ) ) {
						chartLegendFontFamily = context.getOutputParameter( PivotViewComponent.CHARTLEGENDFONTFAMILY ).getStringValue();
						session.setAttribute( "pivot-"+PivotViewComponent.CHARTLEGENDFONTFAMILY+"-"+pivotId, chartLegendFontFamily );
					} else {
						chartLegendFontFamily = "SansSerif";
					}
					if( context.getOutputNames().contains( PivotViewComponent.CHARTLEGENDFONTSTYLE ) ) {
						chartLegendFontStyle = Integer.parseInt(context.getOutputParameter( PivotViewComponent.CHARTLEGENDFONTSTYLE ).getStringValue());
						session.setAttribute( "pivot-"+PivotViewComponent.CHARTLEGENDFONTSTYLE+"-"+pivotId, new Integer(chartLegendFontStyle));
					} else {
						chartLegendFontStyle = java.awt.Font.PLAIN;
					}
					if( context.getOutputNames().contains( PivotViewComponent.CHARTLEGENDFONTSIZE ) ) {
						chartLegendFontSize = Integer.parseInt(context.getOutputParameter( PivotViewComponent.CHARTLEGENDFONTSIZE ).getStringValue());
						session.setAttribute( "pivot-"+PivotViewComponent.CHARTLEGENDFONTSIZE+"-"+pivotId, new Integer(chartLegendFontSize));
					} else {
						chartLegendFontSize = 10;
					}
					if( context.getOutputNames().contains( PivotViewComponent.CHARTSHOWSLICER )) {
						chartShowSlicer = Boolean.valueOf(context.getOutputParameter( PivotViewComponent.CHARTSHOWSLICER ).getStringValue()).booleanValue();
						session.setAttribute("pivot-"+PivotViewComponent.CHARTSHOWSLICER+"-"+pivotId, new Boolean(chartShowSlicer));
					} else {
						chartShowSlicer = true;
					}
					if( context.getOutputNames().contains( PivotViewComponent.CHARTSLICERLOCATION ) ) {
						chartSlicerLocation = Integer.parseInt(context.getOutputParameter( PivotViewComponent.CHARTSLICERLOCATION ).getStringValue());
						session.setAttribute( "pivot-"+PivotViewComponent.CHARTSLICERLOCATION+"-"+pivotId, new Integer(chartSlicerLocation));
					} else {
						chartSlicerLocation = 1;
					}
					if( context.getOutputNames().contains( PivotViewComponent.CHARTSLICERALIGNMENT ) ) {
						chartSlicerAlignment = Integer.parseInt(context.getOutputParameter( PivotViewComponent.CHARTSLICERALIGNMENT ).getStringValue());
						session.setAttribute( "pivot-"+PivotViewComponent.CHARTSLICERALIGNMENT+"-"+pivotId, new Integer(chartSlicerAlignment));
					} else {
						chartSlicerAlignment = 3;
					}
					if( context.getOutputNames().contains( PivotViewComponent.CHARTSLICERFONTFAMILY ) ) {
						chartSlicerFontFamily = context.getOutputParameter( PivotViewComponent.CHARTSLICERFONTFAMILY ).getStringValue();
						session.setAttribute( "pivot-"+PivotViewComponent.CHARTSLICERFONTFAMILY+"-"+pivotId, chartSlicerFontFamily );
					} else {
						chartSlicerFontFamily = "SansSerif";
					}
					if( context.getOutputNames().contains( PivotViewComponent.CHARTSLICERFONTSTYLE ) ) {
						chartSlicerFontStyle = Integer.parseInt(context.getOutputParameter( PivotViewComponent.CHARTSLICERFONTSTYLE ).getStringValue());
						session.setAttribute( "pivot-"+PivotViewComponent.CHARTSLICERFONTSTYLE+"-"+pivotId, new Integer(chartSlicerFontStyle));
					} else {
						chartSlicerFontStyle = java.awt.Font.PLAIN;
					}
					if( context.getOutputNames().contains( PivotViewComponent.CHARTSLICERFONTSIZE ) ) {
						chartSlicerFontSize = Integer.parseInt(context.getOutputParameter( PivotViewComponent.CHARTSLICERFONTSIZE ).getStringValue());
						session.setAttribute( "pivot-"+PivotViewComponent.CHARTSLICERFONTSIZE+"-"+pivotId, new Integer(chartSlicerFontSize));
					} else {
						chartSlicerFontSize = 12;
					}
					if( context.getOutputNames().contains( PivotViewComponent.CHARTBACKGROUNDR ) ) {
						chartBackgroundR = Integer.parseInt(context.getOutputParameter( PivotViewComponent.CHARTBACKGROUNDR ).getStringValue());
						session.setAttribute( "pivot-"+PivotViewComponent.CHARTBACKGROUNDR+"-"+pivotId, new Integer(chartBackgroundR));
					} else {
						chartBackgroundR = 255;
					}
					if( context.getOutputNames().contains( PivotViewComponent.CHARTBACKGROUNDG ) ) {
						chartBackgroundG = Integer.parseInt(context.getOutputParameter( PivotViewComponent.CHARTBACKGROUNDG ).getStringValue());
						session.setAttribute( "pivot-"+PivotViewComponent.CHARTBACKGROUNDG+"-"+pivotId, new Integer(chartBackgroundG));
					} else {
						chartBackgroundG = 255;
					}
					if( context.getOutputNames().contains( PivotViewComponent.CHARTBACKGROUNDB ) ) {
						chartBackgroundB = Integer.parseInt(context.getOutputParameter( PivotViewComponent.CHARTBACKGROUNDB ).getStringValue());
						session.setAttribute( "pivot-"+PivotViewComponent.CHARTBACKGROUNDB+"-"+pivotId, new Integer(chartBackgroundB));
					} else {
						chartBackgroundB = 255;
					}
					
					chartChange = true;
					
					options = (ArrayList) context.getOutputParameter( PivotViewComponent.OPTIONS ).getValue(); //$NON-NLS-1$
					pivotTitle = context.getOutputParameter( PivotViewComponent.TITLE ).getStringValue(); //$NON-NLS-1$
					actionTitle = context.getActionTitle();
					if( options != null ) {
						session.setAttribute( optionsId, options );
					} else {
						session.removeAttribute( optionsId );
					}
					actionReference = solutionName+"/"+actionPath+"/"+actionName; //$NON-NLS-1$ //$NON-NLS-2$
					
					session.setAttribute( "pivot-action-"+pivotId, actionReference ); //$NON-NLS-1$
					session.setAttribute( "pivot-"+PivotViewComponent.TITLE+"-"+pivotId, pivotTitle ); //$NON-NLS-1$
					session.setAttribute( "action-"+PivotViewComponent.TITLE+"-"+pivotId, actionTitle ); //$NON-NLS-1$
				}
			} finally {
				if( context != null ) {
					context.dispose();
				}
			}
			
		}
		
		if( pivotTitle == null ) {
			pivotTitle = Messages.getString("UI.USER_ANALYSIS_UNTITLED_PIVOT_NAME"); //$NON-NLS-1$
		}
		
		if( query != null ) {
			if(provider=="mondrian"){
				IDatasourceService datasourceService = PentahoSystem.getObjectFactory().get(IDatasourceService.class, null);
				DataSource currDataSource = null;
				try {
					currDataSource = datasourceService.getDataSource(dataSource);
				} catch (Throwable t) {
					t.printStackTrace();
				}
				if (currDataSource != null) {
					request.setAttribute("currDataSource", currDataSource);
					%><jp:mondrianQuery id="<%=queryId%>" dataSource="${currDataSource}"
						dynResolver="mondrian.i18n.LocalizingDynamicSchemaProcessor"
						dynLocale="<%= userSession.getLocale().toString() %>"
						role="<%=role%>" catalogUri="<%=catalogUri%>"
						config="/stpivot/xml/jpivot/mondrian/config.xml" >
						<%=query%>
					</jp:mondrianQuery><%
				} else {
					%><jp:mondrianQuery id="<%=queryId%>" dataSource="<%=dataSource%>"
						dynResolver="mondrian.i18n.LocalizingDynamicSchemaProcessor"
						dynLocale="<%= userSession.getLocale().toString() %>"
						role="<%=role%>" catalogUri="<%=catalogUri%>"
						config="/stpivot/xml/jpivot/mondrian/config.xml" >
						<%=query%>
					</jp:mondrianQuery><%
				}
			} else { // provider=="xmla"
				%><jp:xmlaQuery id="<%=queryId%>"
					uri="<%=catalogUri%>"
					dataSource="<%=dataSource%>"
					catalog="<%=catalog%>"
					config="/stpivot/xml/jpivot/xmla/config.xml" >
					<%=query%>
				</jp:xmlaQuery><%
			}
		}
		
		_olapModel =  (OlapModel)session.getAttribute(queryId);
		if (_olapModel == null) {
			%><%= Messages.getString("UI.USER_ANALYSIS_INVALID_PAGE") %><%
		} else {
			
			// this is used to know what part of Pivot must be returned as an ajax response
			String pivotPart = null;
			if (request.getParameter("pivotPart") != null) {
				pivotPart = request.getParameter("pivotPart");
			}
			
			if(pivotPart==null){
				%><%-- define table, navigator and forms --%>
				<wcf:scroller />
				<jp:table id="<%=tableId%>" query="<%=queryId%>" configXml="/stpivot/xml/jpivot/table/config.xml">
					<%
					if(clickables!=null&&clickables!=""){
						String[] clickable = clickables.split(";");
						for(int k=0;k<clickable.length;k++){
							String aUrlPattern="",
								aPage="",
								aUniqueName="",
								aMenuLabel="",
								aSessionParam="",
								aPropertyName="",
								aPropertyPrefix="",
								aProviderClass="";
							if(clickable[k].matches("^.*urlPattern=\".*\".*$")){
								aUrlPattern = clickable[k].replaceAll("^(.*urlPattern=\")(.*)$","$2");
								aUrlPattern = aUrlPattern.substring(0,aUrlPattern.indexOf("\""));
							}
							if(clickable[k].matches("^.*page=\".*\".*$")){
								aPage = clickable[k].replaceAll("^(.*page=\")(.*)$","$2");
								aPage = aPage.substring(0,aPage.indexOf("\""));
							}
							if(clickable[k].matches("^.*uniqueName=\".*\".*$")){
								aUniqueName = clickable[k].replaceAll("^(.*uniqueName=\")(.*)$","$2");
								aUniqueName = aUniqueName.substring(0,aUniqueName.indexOf("\""));
							}
							if(clickable[k].matches("^.*menuLabel=\".*\".*$")){
								aMenuLabel = clickable[k].replaceAll("^(.*menuLabel=\")(.*)$","$2");
								aMenuLabel = aMenuLabel.substring(0,aMenuLabel.indexOf("\""));
							}
							if(clickable[k].matches("^.*sessionParam=\".*\".*$")){
								aSessionParam = clickable[k].replaceAll("^(.*sessionParam=\")(.*)$","$2");
								aSessionParam = aSessionParam.substring(0,aSessionParam.indexOf("\""));
							}
							if(clickable[k].matches("^.*propertyName=\".*\".*$")){
								aPropertyName = clickable[k].replaceAll("^(.*propertyName=\")(.*)$","$2");
								aPropertyName = aPropertyName.substring(0,aPropertyName.indexOf("\""));
							}
							if(clickable[k].matches("^.*propertyPrefix=\".*\".*$")){
								aPropertyPrefix = clickable[k].replaceAll("^(.*propertyPrefix=\")(.*)$","$2");
								aPropertyPrefix = aPropertyPrefix.substring(0,aPropertyPrefix.indexOf("\""));
							}
							if(clickable[k].matches("^.*providerClass=\".*\".*$")){
								aProviderClass = clickable[k].replaceAll("^(.*providerClass=\")(.*)$","$2");
								aProviderClass = aProviderClass.substring(0,aProviderClass.indexOf("\""));
							}
							if(!aUrlPattern.equals("")){ // urlPattern
								if(!aProviderClass.equals("")){ // providerClass
									%><jp:clickable
										urlPattern="<%= aUrlPattern %>"
										uniqueName="<%= aUniqueName %>"
										menuLabel="<%= aMenuLabel %>"
										providerClass="<%= aProviderClass %>"
										/><%
								} else { // sessionParam, propertyName, propertyPrefix
									if(!aPropertyPrefix.equals("")){
										%><jp:clickable
											urlPattern="<%= aUrlPattern %>"
											uniqueName="<%= aUniqueName %>"
											menuLabel="<%= aMenuLabel %>"
											propertyPrefix="<%= aPropertyPrefix %>"
											/><%
									} else if(!aSessionParam.equals("")){
										%><jp:clickable
											urlPattern="<%= aUrlPattern %>"
											uniqueName="<%= aUniqueName %>"
											menuLabel="<%= aMenuLabel %>"
											sessionParam="<%= aSessionParam %>"
											propertyName="<%= aPropertyName %>"
											/><%
									} else {
										%><jp:clickable
											urlPattern="<%= aUrlPattern %>"
											uniqueName="<%= aUniqueName %>"
											menuLabel="<%= aMenuLabel %>"
											/><%
									}
								}
							} else { // page
								if(!aProviderClass.equals("")){ // providerClass
									%><jp:clickable
										page="<%= aPage %>"
										uniqueName="<%= aUniqueName %>"
										menuLabel="<%= aMenuLabel %>"
										providerClass="<%= aProviderClass %>"
										/><%
								} else { // sessionParam, propertyName, propertyPrefix
									if(!aPropertyPrefix.equals("")){
										%><jp:clickable
											page="<%= aPage %>"
											uniqueName="<%= aUniqueName %>"
											menuLabel="<%= aMenuLabel %>"
											propertyPrefix="<%= aPropertyPrefix %>"
											/><%
									} else {
										%><jp:clickable
											page="<%= aPage %>"
											uniqueName="<%= aUniqueName %>"
											menuLabel="<%= aMenuLabel %>"
											sessionParam="<%= aSessionParam %>"
											propertyName="<%= aPropertyName %>"
											/><%
									}
								}
							}
						}
					}
					%>
				</jp:table>
				<jp:navigator id="<%=naviId%>" query="<%=queryId%>" visible="true" />
				<%
				String wrappedQueryId = "#{" + queryId + "}";
				String wrappedTableId = "#{" + tableId + "}";
				String wrappedPrintId = "#{" + printId + "}";
				String chartControllerURL = "?pivotId=" + pivotId;
				%><wcf:form id="<%=mdxEditId%>" xmlUri="/stpivot/xml/jpivot/table/mdxedit.xml" model="<%=wrappedQueryId%>" visible="true" />
				<wcf:form id="<%=sortFormId%>" xmlUri="/stpivot/xml/jpivot/table/sortform.xml" model="<%=wrappedTableId%>" visible="true" />
				<wcf:form id="<%=axisFormId%>" xmlUri="/stpivot/xml/jpivot/table/axisform.xml" model="<%=wrappedTableId%>" visible="true" />
				<jp:print id="<%=printId%>" />
				<wcf:form id="<%=printFormId%>" xmlUri="/stpivot/xml/jpivot/print/printpropertiesform.xml" model="<%=wrappedPrintId%>" visible="true" />
				<jp:chart id="<%=chartId%>" query="<%=wrappedQueryId%>" controllerURL="<%=chartControllerURL%>" visible="true" />
				<%
				// we've reloaded the following session objects
				_table =  (TableComponent) session.getAttribute(tableId);
				_mdxEdit = (FormComponent)session.getAttribute(mdxEditId);
				_chart = (ChartComponent) session.getAttribute( chartId );
				if( chartChange ) {
					_chart.setChartType( chartType );
					_chart.setVisible( (chartLocation != null) && !chartLocation.equals( "none" ) );
					if (chartWidth > 0) {
						_chart.setChartWidth(chartWidth);
					} else {
						_chart.setChartWidth(500);    // 500 is the default that the ChartCompoent uses
					}
					if (chartHeight > 0) {
						_chart.setChartHeight(chartHeight);
					} else {
						_chart.setChartHeight(300); // 300 is the default that the ChartComponent uses
					}
					_chart.setChartTitle(chartTitle);
					_chart.setDrillThroughEnabled(chartDrillThroughEnabled);
					_chart.setFontName(chartTitleFontFamily);
					_chart.setFontStyle(chartTitleFontStyle);
					_chart.setFontSize(chartTitleFontSize);
					_chart.setHorizAxisLabel(chartHorizAxisLabel);
					_chart.setVertAxisLabel(chartVertAxisLabel);
					_chart.setAxisFontName(chartAxisLabelFontFamily);
					_chart.setAxisFontStyle(chartAxisLabelFontStyle);
					_chart.setAxisFontSize(chartAxisLabelFontSize);
					_chart.setAxisTickFontName(chartAxisTickFontFamily);
					_chart.setAxisTickFontStyle(chartAxisTickFontStyle);
					_chart.setAxisTickFontSize(chartAxisTickFontSize);
					_chart.setTickLabelRotate(chartAxisTickLabelRotation);
					_chart.setShowLegend(chartShowLegend);
					_chart.setLegendPosition(chartLegendLocation);
					_chart.setLegendFontName(chartLegendFontFamily);
					_chart.setLegendFontStyle(chartLegendFontStyle);
					_chart.setLegendFontSize(chartLegendFontSize);
					_chart.setShowSlicer(chartShowSlicer);
					_chart.setSlicerPosition(chartSlicerLocation);
					_chart.setSlicerAlignment(chartSlicerAlignment);
					_chart.setSlicerFontName(chartSlicerFontFamily);
					_chart.setSlicerFontStyle(chartSlicerFontStyle);
					_chart.setSlicerFontSize(chartSlicerFontSize);
					_chart.setBgColorR(chartBackgroundR);
					_chart.setBgColorG(chartBackgroundG);
					_chart.setBgColorB(chartBackgroundB);     
				}
				String wrappedChartId = "#{" + chartId + "}";
				%><wcf:form id="<%=chartFormId%>" xmlUri="/stpivot/xml/jpivot/chart/chartpropertiesform.xml" model="<%=wrappedChartId%>" visible="true" />
				<wcf:table id="<%=drillThroughTableId%>" visible="false" selmode="none" editable="true" /><%
				// define a toolbar
				if( options != null ) {
					session.removeAttribute( toolbarId );
				}
				String wrappedNaviVisible = "#{" + naviId + ".visible}";
				String wrappedMdxEditVisible = "#{" + mdxEditId + ".visible}";
				String wrappedSortFormVisible = "#{" + sortFormId + ".visible}";
				String wrappedAxisFormVisible = "#{" + axisFormId + ".visible}";
				String wrappedTableLevelStyle = "#{" + tableId + ".extensions.axisStyle.levelStyle}";
				String wrappedTableHideSpans = "#{" + tableId + ".extensions.axisStyle.hideSpans}";
				String wrappedTableShowProperties = "#{" + tableId + ".rowAxisBuilder.axisConfig.propertyConfig.showProperties}";
				String wrappedTableNonEmptyButtonPressed = "#{" + tableId + ".extensions.nonEmpty.buttonPressed}";
				String wrappedTableSwapAxesButtonPressed = "#{" + tableId + ".extensions.swapAxes.buttonPressed}";
				String wrappedTableDrillMemberEnabled = "#{" + tableId + ".extensions.drillMember.enabled}";
				String wrappedTableDrillPositionEnabled = "#{" + tableId + ".extensions.drillPosition.enabled}";
				String wrappedTableDrillReplaceEnabled = "#{" + tableId + ".extensions.drillReplace.enabled}";
				String wrappedTableDrillThroughEnabled = "#{" + tableId + ".extensions.drillThrough.enabled}";
				String wrappedChartVisible = "#{" + chartId + ".visible}";
				String wrappedChartFormVisible = "#{" + chartFormId + ".visible}";
				String wrappedPrintFormVisible = "#{" + printFormId + ".visible}";
				String printExcel = "./Print?cube=" + pivotId + "&type=0";
				String printPdf = "./Print?cube=" + pivotId + "&type=1";
				%><wcf:toolbar id="<%=toolbarId%>" bundle="com.tonbeller.jpivot.toolbar.resources">
					<%--wcf:scriptbutton id="cubeNaviButton" tooltip="toolb.cube" img="cube" model="<%=wrappedNaviVisible%>" /--%>
					<%--wcf:scriptbutton id="mdxEditButton" tooltip="toolb.mdx.edit" img="mdx-edit" model="<%=wrappedMdxEditVisible%>" /--%>
					<%--wcf:scriptbutton id="sortConfigButton" tooltip="toolb.table.config" img="sort-asc" model="<%=wrappedSortFormVisible%>" /--%>
					<wcf:separator />
					<wcf:scriptbutton id="levelStyle" tooltip="toolb.level.style" img="level-style" model="<%=wrappedTableLevelStyle%>" />
					<wcf:scriptbutton id="hideSpans" tooltip="toolb.hide.spans" img="hide-spans" model="<%=wrappedTableHideSpans%>" />
					<wcf:scriptbutton id="propertiesButton" tooltip="toolb.properties" img="properties" model="<%=wrappedTableShowProperties%>" />
					<wcf:scriptbutton id="nonEmpty" tooltip="toolb.non.empty" img="non-empty" model="<%=wrappedTableNonEmptyButtonPressed%>" />
					<wcf:scriptbutton id="swapAxes" tooltip="toolb.swap.axes" img="swap-axes" model="<%=wrappedTableSwapAxesButtonPressed%>" />
					<wcf:separator />
					<wcf:scriptbutton model="<%=wrappedTableDrillMemberEnabled%>" tooltip="toolb.navi.member" radioGroup="navi" id="drillMember" img="navi-member" />
					<wcf:scriptbutton model="<%=wrappedTableDrillPositionEnabled%>" tooltip="toolb.navi.position" radioGroup="navi" id="drillPosition" img="navi-position" />
					<wcf:scriptbutton model="<%=wrappedTableDrillReplaceEnabled%>" tooltip="toolb.navi.replace" radioGroup="navi" id="drillReplace" img="navi-replace" />
					<wcf:separator />
					<wcf:scriptbutton model="<%=wrappedTableDrillThroughEnabled%>" tooltip="toolb.navi.drillthru" id="drillThrough01" img="navi-through" />
					<%--wcf:separator /--%>
					<%--wcf:scriptbutton id="chartButton01" tooltip="toolb.chart" img="chart" model="<%=wrappedChartVisible%>" /--%>
					<%--wcf:scriptbutton id="chartPropertiesButton01" tooltip="toolb.chart.config" img="chart-config" model="<%=wrappedChartFormVisible%>" /--%>
					<%--wcf:separator /--%>
					<%--wcf:scriptbutton id="printPropertiesButton01" tooltip="toolb.print.config" img="print-config" model="<%=wrappedPrintFormVisible%>" /--%>
					<%--wcf:imgbutton id="printpdf" tooltip="toolb.print" img="print" href="<%= printPdf %>" /--%>
					<%--wcf:imgbutton id="printxls" tooltip="toolb.excel" img="excel" href="<%= printExcel %>" /--%>
				</wcf:toolbar><%
				session.setAttribute(titleId, pivotTitle);
				%><html>
					<head>
						<title><%= Messages.getString("UI.USER_ANALYSIS") %></title>
						<meta http-equiv="Content-Type" content="text/html; charset=<%= LocaleHelper.getSystemEncoding() %>" />
						
						<link rel="stylesheet" type="text/css" href="stpivot/style/jpivot/table/mdxtable.css" />
						<link rel="stylesheet" type="text/css" href="stpivot/style/jpivot/navi/mdxnavi.css" />
						<link rel="stylesheet" type="text/css" href="stpivot/style/wcf/form/xform.css" />
						<link rel="stylesheet" type="text/css" href="stpivot/style/wcf/table/xtable.css" />
						<link rel="stylesheet" type="text/css" href="stpivot/style/wcf/tree/xtree.css" />
						
						<link rel="stylesheet" type="text/css" href="stpivot/style/wcf/popup/popup.css" />
						<script src="stpivot/style/wcf/popup/popup.js" type="text/javascript"></script>
						
						<link href="/pentaho-style/styles-new.css" rel="stylesheet"
							type="text/css" />
						<link rel="shortcut icon" href="/pentaho-style/favicon.ico" />
						
						<!-- ****************************************************************************************** -->
						<!-- ****************        JAVASCRIPT FOR SAVE DIALOGS              ************************* -->
						<!-- ****************************************************************************************** -->
						
						<link href="adhoc/styles/repositoryBrowserStyles.css" rel="stylesheet" type="text/css" />
						<link href="adhoc/styles/jpivot.css" rel="stylesheet" type="text/css" />
						<!--[if IE]>
						<link href="adhoc/styles/jpivotIE6.css" rel="stylesheet" type="text/css"/>
						<![endif]-->
						
						<script src="wcf/scroller.js" type="text/javascript"></script>
						<script src="js/ajaxslt0.7/xmltoken.js" type="text/javascript"></script>
						<script src="js/ajaxslt0.7/util.js" type="text/javascript"></script>
						<script src="js/ajaxslt0.7/dom.js" type="text/javascript"></script>
						<script src="js/ajaxslt0.7/xpath.js" type="text/javascript"></script>
						<script src="js/ajaxslt0.7/xslt.js" type="text/javascript"></script>
						
						<script src="js/pentaho-ajax.js" type="text/javascript"></script>
						<script src="js/utils.js" type="text/javascript"></script>
						<script type="text/javascript">
							djConfig = { isDebug: false};
						</script>
						
						<script src="js/dojo.js" type="text/javascript"></script>
						
						<script type="text/javascript">
							dojo.registerModulePath("adhoc", "../adhoc/js");
						</script>
						
						<script src="adhoc/js/common/ui/messages/Messages.js" type="text/javascript"></script>
						
						<script type="text/javascript">
							Messages.addBundle("adhoc.ui.messages", "message_strings");
						</script>
						
						<script src="adhoc/js/common/ui/MessageCtrl.js" type="text/javascript"></script>
						<script src="adhoc/js/common/server/WebServiceProxy.js" type="text/javascript"></script>
						<script src="adhoc/js/common/util/StringUtils.js" type="text/javascript"></script>
						<script src="adhoc/js/common/util/Status.js" type="text/javascript"></script>
						<script src="adhoc/js/common/util/XmlUtil.js" type="text/javascript"></script>
						
						<script src="adhoc/js/model/SolutionRepository.js" type="text/javascript"></script>
						
						<script src="adhoc/js/common/ui/UIUtil.js" type="text/javascript"></script>
						<script type="text/javascript">
							UIUtil.setImageFolderPath( "adhoc/images/" );
						</script>
						<script src="adhoc/js/common/ui/HTMLCtrl.js" type="text/javascript"></script>
						<script src="adhoc/js/common/ui/Logger.js" type="text/javascript"></script>
						<script src="adhoc/js/common/ui/BusyCtrl.js" type="text/javascript"></script>
						<script src="adhoc/js/common/ui/PickListCtrl.js" type="text/javascript"></script>
						<script src="adhoc/js/common/ui/ListCtrl.js" type="text/javascript"></script>
						<script src="adhoc/js/common/ui/ComboCtrl.js" type="text/javascript"></script>
						<script src="adhoc/js/common/ui/Dialog.js" type="text/javascript"></script>
						
						<script src="adhoc/js/common/ui/ButtonCtrl.js" type="text/javascript"></script>
						<script src="adhoc/js/common/ui/MessageCtrl.js" type="text/javascript"></script>
						
						<script src="adhoc/js/ui/RepositoryBrowser.js" type="text/javascript"></script>
						<script src="js/pivot/PivotRepositoryBrowserController.js" type="text/javascript"></script>
						
						<!-- ****************************************************************************************** -->
						<!-- ****************                HEADER FOR STPIVOT               ************************* -->
						<!-- ****************************************************************************************** -->
						
						<script type="text/javascript" src="stpivot/js/jquery/jquery-1.4.4.js"></script>
						<script type="text/javascript" src="stpivot/js/jquery/jquery.layout.js"></script>
						<script type="text/javascript" src="stpivot/js/jquery/jquery.form.js"></script>
						<script type="text/javascript" src="stpivot/js/jquery/ui/jquery-ui-1.8.7.custom.js"></script>
						<link rel="stylesheet" type="text/css" href="stpivot/js/jquery/themes/base/jquery.ui.all.css">
						
						<link rel="stylesheet" type="text/css" href="stpivot/js/CodeMirror/lib/codemirror.css">
						<script type="text/javascript" src="stpivot/js/CodeMirror/lib/codemirror.js"></script>
						<script type="text/javascript" src="stpivot/js/CodeMirror/mode/mdx/mdx.js"></script>
						<link rel="stylesheet" type="text/css" href="stpivot/js/CodeMirror/mode/mdx/mdx.css">
		
						<link rel="stylesheet" href="stpivot/js/treeview/jquery.treeview.css" />
						<script type="text/javascript" src="stpivot/js/treeview/jquery.treeview.js"></script>
						
						<script>
							var pivotId = "<%=ESAPI.encoder().encodeForHTMLAttribute(pivotId)%>";
							var pageName = "<%=pageName%>";
							var showGrid = <%= showGrid %>;
							var showChart = <%= _chart.isVisible() %>;
							var showToolbar = <%= (options!=null) %>;
							var CONTEXT_PATH = "<%= cpath %>";
						</script>
						<script type="text/javascript" src="stpivot/js/stpivot.js"></script>
						<link rel="stylesheet" type="text/css" href="stpivot/style/stpivot.css" />
						
						<%-- ****************************************************************************************** --%>
						<%-- ****************************************************************************************** --%>
						<%-- ****************************************************************************************** --%>
						
						<script type="text/javascript"><!--
	
	var controller = null;
	var newActionName = null;
	var newSolution = null;
	var newActionPath = null;
	
	function cursor_wait() {
		document.body.style.cursor = 'wait';
	}
	
	function cursor_clear() {
		document.body.style.cursor = 'default';
	}
	
	//
	// This method creates a temporary form in the dom,
	// adds the inputs we want to post back to ourselves,
	// and then posts the form. Once the form is posted,
	// we remove the temporary form from the DOM.
	//
	function doSaveAsPost(postActionName, postActionSolution, postActionPath, postActionTitle) {
		/*
		var postForm = document.createElement("form");
		postForm.method="post" ;
		postForm.action = '<%= pageName %>';
		var anInput;
		// save-action
		anInput = document.createElement("input");
		anInput.setAttribute("name", "save-action");
		anInput.setAttribute("value", "saveAs");
		postForm.appendChild(anInput);
		// save-path
		anInput = document.createElement("input");
		anInput.setAttribute("name", "save-path");
		anInput.setAttribute("value", postActionSolution +'/'+postActionPath );
		postForm.appendChild(anInput);
		// save-file
		anInput = document.createElement("input");
		anInput.setAttribute("name", "save-file");
		anInput.setAttribute("value",  postActionName);
		postForm.appendChild(anInput);
		// save-title
		anInput = document.createElement("input");
		anInput.setAttribute("name", "save-title");
		anInput.setAttribute("value",  postActionTitle);
		postForm.appendChild(anInput);
		// pivotId
		anInput = document.createElement("input");
		anInput.setAttribute("name", "pivotId");
		anInput.setAttribute("value",  "<%=ESAPI.encoder().encodeForJavaScript(pivotId)%>");
		postForm.appendChild(anInput);
		
		document.body.appendChild(postForm); // Add the form into the document...
		postForm.submit(); // Post to ourselves...
		document.body.removeChild(postForm); // Remove the temporary form from the DOM.
		*/
		$("#save_form input[name=save-path]").val(postActionSolution +'/'+postActionPath);
		$("#save_form input[name=save-file]").val(postActionName);
		$("#save_form input[name=save-title]").val(postActionTitle);
		$("#save_form").submit();
	}
	
	function load(){
		xScrollerScroll();
		cursor_wait();
		controller = new PivotRepositoryBrowserController();
		controller.setOnAfterSaveCallback( function()
		{
			var nActionName = controller.getActionName();
			var nSolution = controller.getSolution();
			var nActionPath = controller.getActionPath();
			var nActionTitle = controller.getActionTitle()!=null?controller.getActionTitle():controller.getActionName();
			doSaveAsPost(nActionName, nSolution, nActionPath, nActionTitle);
		});
		cursor_clear();
		if (saveMessage != null && "" != saveMessage) {
			if (window.top != null && window.top.mantle_initialized) {
				window.top.mantle_refreshRepository();
				window.top.mantle_showMessage("Info", saveMessage);
			} else {
				alert(saveMessage);
			}
		}
		
		if (window.top != null && window.top.mantle_initialized) { // Uncomment this line and the close brace to enable these buttons when in window only mode
			var tmpSaveButton = document.getElementById('folder-down');
			var tmpSaveAsButton = document.getElementById('folder-up');
			tmpSaveButton.parentNode.parentNode.removeChild(tmpSaveButton.parentNode);
			tmpSaveAsButton.parentNode.parentNode.removeChild(tmpSaveAsButton.parentNode);
		}  // Uncomment this if above if is uncommented
		
		window.pivot_initialized = true;
		<% if ("true".equalsIgnoreCase(PentahoSystem.getSystemSetting("kiosk-mode", "false"))) { %>
			try {
				var mdxEditTxtBx = document.getElementById('<%=ESAPI.encoder().encodeForJavaScript(mdxEditId)%>.9');
				if (mdxEditTxtBx) {
					mdxEditTxtBx.readOnly = true;
				}
			} catch (ignored) {
			}
		<% } %>
	}
	
	function save() {
		cursor_wait();
		<%
		ActionInfo actionInfo = ActionInfo.parseActionString( actionReference );
		if (actionInfo != null) {
		%>
		var nActionName = "<%= ESAPI.encoder().encodeForJavaScript(actionInfo.getActionName()) %>";
		var nSolution = "<%= ESAPI.encoder().encodeForJavaScript(actionInfo.getSolutionName()) %>";
		var nActionPath = "<%= ESAPI.encoder().encodeForJavaScript(actionInfo.getPath()) %>";
		var nActionTitle = "<%= ESAPI.encoder().encodeForJavaScript(actionTitle) %>";
		doSaveAsPost(nActionName, nSolution, nActionPath, nActionTitle);
		<% } %>
		cursor_clear();
    }
    
    function saveAs() {
    	controller.save();
    }
    
    					--></script>
    					<%-- ****************************************************************************************** --%>
    					<%-- ****************************************************************************************** --%>
    					<%-- ****************************************************************************************** --%>
    					
    					<script type="text/javascript">


	function doSubscribed() {
		var submitUrl = '';
		var action= document.getElementById('subscription-action').value;
		var target='';
		
		if( action == 'load' ) {
			submitUrl += '<%= pageName %>?subscribe=load&query=SampleData';
		}
		else
		if( action == 'delete' ) {
			submitUrl += '<%= pageName %>?subscribe=delete';
		}
		var name= document.getElementById('subscription').value;
		submitUrl += '&subscribe-name='+encodeURIComponent(name);
		document.location.href=submitUrl;
		return false;
	}
	
	/***********************************************
	* Ajax Includes script-  Dynamic Drive DHTML code library (www.dynamicdrive.com)
	* This notice MUST stay intact for legal use
	* Visit Dynamic Drive at http://www.dynamicdrive.com/ for full source code
	***********************************************/
	
	//To include a page, invoke ajaxinclude("afile.htm") in the BODY of page
	//Included file MUST be from the same domain as the page displaying it.
	
	var rootdomain="http://"+window.location.hostname
	
	function ajaxinclude(url) {
		var page_request = false
		if (window.XMLHttpRequest) // if Mozilla, Safari etc
			page_request = new XMLHttpRequest()
		else if (window.ActiveXObject){ // if IE
			try {
				page_request = new ActiveXObject("Msxml2.XMLHTTP")
			} catch (e){
				try {
					page_request = new ActiveXObject("Microsoft.XMLHTTP")
				}catch (e){}
				}
			}
		else
			return false
		page_request.open('GET', url, false) //get page synchronously 
		page_request.send(null)
		writecontent(page_request)
	}
	
	function writecontent(page_request){
		if (window.location.href.indexOf("http")==-1 || page_request.status==200)
			document.write(page_request.responseText)
	}
    
						</script>
						
						<%-- ****************************************************************************************** --%>
						<%-- ****************************************************************************************** --%>
						<%-- ****************************************************************************************** --%>
						
					</head>
					<body class="body_dialog01" dir="<%= LocaleHelper.getTextDirection() %>" onload="javascript:load();">
						
						<form id="toolbar_form">
							<div class="ui-layout-north" style="padding:0px;overflow:hidden;">
								<table cellpadding="0" cellspacing="0" style="top: 0;width: 100%;z-index:1000;background-image: url(stpivot/style/jpivot/table/toolbar_bg.png);height: 28px;vertical-align: top;border-bottom: 1px solid #848484;">
									<tr>
										<td width="1px" nowrap="nowrap" align="left" valign="middle">
											<table cellpadding="0" cellspacing="0">
												<tr>
													<td><input type="image" src="stpivot/style/images/cube.png" alt="Navi" title="Navi" onclick="myLayout.toggle('west');return false;" class="imgButton"/></td>
													<td><input type="image" src="stpivot/style/images/editor.png" alt="MDX" title="MDX" onclick="myLayout.toggle('south');return false;" class="imgButton" /></td>
													<td><input type="image" src="stpivot/style/images/home.png" alt="Home" title="Home" onclick="goHome();return false;" class="imgButton" /></td>
												</tr>
											</table>
										</td>
										<td width="1px" nowrap="nowrap" align="left" valign="top">
											<table cellpadding="0" cellspacing="0">
												<tr>
													<%-- ****************************************************************************************** --%>
													<%-- ******************                   SAVE BUTTONS               ************************** --%>
													<%-- ****************************************************************************************** --%>
													
													<% if( authenticated ) { %>
													<td><span id="folder-down" style="display: none"> <img class="imgButton"
														src="stpivot/style/images/save.png" onclick="javascript:save();"
														alt="Save" title="Save" /> </span></td>
													<td><span id="folder-up" style="display: block"> <img class="imgButton"
														src="stpivot/style/images/save_as.png" onclick="javascript:saveAs();"
														alt="Save As" title="Save As" /> </span></td>
													<% } %>
													
													<%-- ****************************************************************************************** --%>
													<%-- ****************************************************************************************** --%>
													<%-- ****************************************************************************************** --%>
												</tr>
											</table>
										</td>
										<td width="1px" nowrap="nowrap" align="left" valign="middle">
											<div id="toolbar_container">
												<%-- render toolbar --%>
												<wcf:render ref="<%=toolbarId%>" xslUri="/stpivot/xml/jpivot/toolbar/htoolbar.xsl" xslCache="true" />
											</div>
										</td>
										<td width="1px" nowrap="nowrap" align="left" valign="middle">
											<table cellpadding="0" cellspacing="0">
												<tr>
													<td><input type="image" src="stpivot/style/images/xml.png" alt="XML" title="Show Xml (toolbar)" onclick="showXml('<%=toolbarId%>')" class="showxml"/></td>
												</tr>
											</table>
										</td>
										<td nowrap="nowrap" align="right" valign="middle" style="width:100%">
											<div id="stats_summary" style="font-size:11px;"></div>
										</td>
										<td width="1px" nowrap="nowrap" align="right" valign="middle">
											<table>
												<tr>
													<td><img src="stpivot/style/images/formulas.png" alt="f(x)" title="Formulas" onclick="addFormula()" class="imgButton" /></a></td>
													<td nowrap="nowrap" style="background: url(stpivot/style/images/table.png) 8px no-repeat;" title="Grid"><input type="checkbox" id="cb_show_grid" onclick="toggleGrid()" <%= (showGrid)?"checked=\"checked\"":""%> />&nbsp;&nbsp;&nbsp;</td>
													<td nowrap="nowrap" style="background: url(stpivot/style/images/chart.png) 8px no-repeat;" title="Chart"><input type="checkbox" id="cb_show_chart" onclick="toggleChart()" <%= (_chart.isVisible())?"checked=\"checked\"":""%> />&nbsp;&nbsp;&nbsp;</td>
													<td><a href="./Print?cube=<%= pivotId %>&type=1"><img src="stpivot/style/images/pdf.png" alt="PDF" title="PDF" class="imgButton" /></a></td>
													<td><a href="./Print?cube=<%= pivotId %>&type=0"><img src="stpivot/style/images/xls.png" alt="XLS" title="XLS" class="imgButton" /></a></td>
													<td>
														<img src="stpivot/style/images/options.png" alt="Options" title="Edit options ..." onclick="$('#options_tabs').toggle()" class="imgButton" />
													</td>
													<td>
														<img src="stpivot/style/images/cache.png" alt="Refresh" title="Clear cache ..." onclick="flushMondrianSchemaCache()" class="imgButton" /></a>
													</td>
													<td align="right">
														<div style="width:20px">
															<img id="loading" src="stpivot/style/images/loading.gif" alt="Wait" title="Loading...">
														</div>
													</td>
												</tr>
											</table>
										</td>
									</tr>
								</table>
							</div>
						</form>
						
						<%-- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX --%>
						<div id="browser.modalDiv" class='browser'>
							<%-- ======================================================
							     ==  SAVEAS DIALOG                                   ==
							     ====================================================== --%>
							<div id="browser.saveasDialog" style="display: none; position: absolute; top: 100px; left: 200px; height: 25px;">
								<table border="0" cellspacing="0" cellpadding="0" class="popupDialog_table">
									<tr>
										<td class="popupDialog_header">
											<div id="browser.titleBar" class="popupDialogTitleBar" onmouseover="this.onmousedown=Dialog.dragIsDown;" ondragstart="return false;" onselectstart="return false;"></div>
										</td>
									</tr>
									<tr>
										<td valign="top" style="padding: 15px;">
											<table style="width: 40em; height: 100%;" border="0" cellspacing="2px" cellpadding="2px">
												<tr>
													<td id="saveDlgSaveAsPrompt" style='width: 25%'>Save As:</td>
													<td style='width: 75%'><input type="text" id="browser.saveAsNameInputText" tabindex='0' name="textfield" class="browserSaveAsText" /></td>
												</tr>
												<tr>
													<td id="saveDlgWherePrompt">Where:</td>
													<td>
														<table style='width: 100%;' border="0" cellspacing="0" cellpadding="0">
															<tr>
																<td style="width: 100%; padding-right: 5px;" id="browser.comboContainer"></td>
																<td><img id='browser.upImg' src="adhoc/images/up.png" alt="up" /></td>
															</tr>
														</table>
													</td>
												</tr>
												<tr>
													<td id="saveDlgSelectSltnTitle" colspan='2'>Select a Solution</td>
												</tr>
												<tr>
													<td id="browser.solutionFolderListTd" height="100%" colspan='2'>
												</td>
											</tr>
										</table>
									</td>
								</tr>
								<tr>
									<td style="border-top: 1px solid #818f49; background-color: #ffffff;">
										<table border="0" cellpadding="0" cellspacing="0" align="right">
											<tr>
												<td id="browser.saveBtnContainer" width="75"></td>
												<td id="browser.cancelBtnContainer" width="85"></td>
											</tr>
										</table>
									</td>
								</tr>
							</table>
						</div>
						<%-- ======================================================
						     ==  END SAVEAS DIALOG                               ==
						     ====================================================== --%>
					</div>
					<%-- XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX --%>
					
					<script type="text/javascript">
						var saveMessage = '<%= ESAPI.encoder().encodeForJavaScript(saveMessage) %>';
					</script> <%
					
					switch (saveResult) {
						case ISolutionRepository.FILE_ADD_SUCCESSFUL: 
							if ("saveAs".equals(saveAction)){
								// If performing a save as.. , we need to reload the view with the newly saved
								// action sequence.
								ActionInfo info = ActionInfo.parseActionString(request.getParameter("save-path")+ "/" + request.getParameter("save-file"));
								String fileName = info.getActionName();
								fileName = fileName.endsWith(AnalysisSaver.SUFFIX) ? fileName : fileName+AnalysisSaver.SUFFIX;
								%>
								<script type="text/javascript">
									var path = encodeURIComponent( "<%= ESAPI.encoder().encodeForJavaScript(info.getPath()) %>" );
									var fileName = encodeURIComponent( "<%= ESAPI.encoder().encodeForJavaScript(fileName) %>" );
									var solutionName = encodeURIComponent( "<%= ESAPI.encoder().encodeForJavaScript(info.getSolutionName()) %>" );
									var uri = "ViewAction?solution=" + solutionName + "&path=" + path + "&action=" + fileName;
									document.location.href = uri;
								</script> <%
							}
							break;
						case ISolutionRepository.FILE_EXISTS:
							break;
						case ISolutionRepository.FILE_ADD_FAILED:
							break;
						case ISolutionRepository.FILE_ADD_INVALID_PUBLISH_PASSWORD:
							break;
						case ISolutionRepository.FILE_ADD_INVALID_USER_CREDENTIALS:
							break;
						case 0:
							saveMessage="";
							session.setAttribute( "save-message-01", saveMessage); //$NON-NLS-1$
							break;
					}
					%>
    
						<div class="ui-layout-west" style="padding:3px;">
							<table style="width:100%" cellpadding="0" cellspacing="0">
								<tr>
									<td>
										<input type="image" src="stpivot/style/images/xml.png" alt="XML" title="Show Xml (navi)" onclick="showXml('<%=naviId%>')" class="showxml"/>
										<form id="navi_form">
											<div id="navi_container">
												<%-- render navigator --%>
												<wcf:render ref="<%=naviId%>" xslUri="/stpivot/xml/jpivot/navi/navigator.xsl" xslCache="true" />
											</div>
										</form>
									</td>
								</tr>
								<tr>
									<td>
										<table width="100%">
											<thead>
												<tr><th class="navi-axis" colspan="2" align="left"><img src="stpivot/style/jpivot/navi/functions.png" alt="fx">Formulas:</th></tr>
											</thead>
											<tbody id="with_formulas">
												<!--tr>
													<td class="navi-hier" style="padding-left: 15px;"><a href="#" onclick="editFormula('name')">[Mercados]...</a></td>
													<td class="navi-hier"><input type="image" src="stpivot/style/jpivot/navi/remove.png" alt="-" title="Remove" onclick="removeFormula()" /></td>
												</tr>
												<tr>
													<td class="navi-hier" style="padding-left: 15px;"><a href="#" onclick="editFormula('name')">[Measures].[Sales2]...</a></td>
													<td class="navi-hier"><input type="image" src="stpivot/style/jpivot/navi/remove.png" alt="-" title="Remove" onclick="removeFormula()" /></td>
												</tr-->
											</thead>
											<tfoot>
												<tr>
													<td class="navi-axis" style="padding-left: 15px;" colspan="2"><input type="image" src="stpivot/style/jpivot/navi/add.png" alt="+" title="Add" onclick="addFormula()" /></td>
												</tr>
											</tfoot>
										</table>
									</td>
								</tr>
							</table>
						</div>
						
						<div class="ui-layout-south" style="padding:0px;padding-left:10px;">
							<input type="image" src="stpivot/style/images/xml.png" alt="XML" title="Show Xml (mdxEdit)" onclick="showXml('<%=mdxEditId%>')" class="showxml"/>
							<table>
								<tr>
									<td></td>
									<td style="max-width:900px;">
										<div id="toolbar" style="margin:0px;padding:0px;font-size:14px;">
											<input type="image" src="stpivot/js/CodeMirror/mode/mdx/images/arrow_undo.png" title="undo (ctrl-z)" onclick="editor.undo();return false"/>
											<input type="image" src="stpivot/js/CodeMirror/mode/mdx/images/arrow_redo.png" title="redo (ctrl-y)" onclick="editor.redo();return false"/>
											&nbsp;&nbsp;&nbsp;
											<input type="image" src="stpivot/js/CodeMirror/mode/mdx/images/page_refresh.png" onclick="reindent();return false"/>
											<input type="image" src="stpivot/js/CodeMirror/mode/mdx/images/text_indent.png" onclick="indentSelected('add');return false"/>
											<input type="image" src="stpivot/js/CodeMirror/mode/mdx/images/text_indent_remove.png" onclick="indentSelected('sub');return false"/>
											&nbsp;&nbsp;&nbsp;
											<input type="text" id="searchkey" name="searchkey" style="width:150px;" />
											<input type="image" src="stpivot/js/CodeMirror/mode/mdx/images/find.png" onclick="search();return false"/>
											<input type="checkbox" id="ignorecase" name="case-sensitive" onclick="search()">A/a
											<input type="checkbox" id="regex" name="reg-exp" onclick="search()">RegEx
										</div>
									</td>
									<td align="right"><input type="image" src="stpivot/style/images/cube_navigator.gif" alt="(+)" title="Cube" onclick="toggleEditorExplorer()"/></td>
								</tr>
								<tr>
									<td valign="top">
										<table>
											<tr>
												<td>
													<select onchange="editorFunctionFilter(this.value)" style="width:100px">
														<option value="">( functions )</option>
														<option value="logical">Logical</option>
														<option value="set">Set</option>
														<option value="member">Member</option>
														<option value="numeric">Numeric</option>
														<option value="integer">Integer</option>
														<option value="string">String</option>
														<option value="datetime">Datetime</option>
														<option value="misc">Misc</option>
													</select>
												</td>
											</tr>
											<tr>
												<td>
													<select id="editor_functions" ondblclick="editorFunctionSelect(this.value)" size="11" style="width:100px">
														<jsp:include page="stpivot/mdx_functions_opts.jsp"/>
													</select>
												</td>
											</tr>
										</table>
									</td>
									<td colspan="2">
										<div id="editor_explorer" style="border:1px solid gray;z-Index:1100;background-color:white;position:absolute;display:none;left:600px;margin-top:5px;width:300px;height:200px;float:right;overflow:scroll;" />test</div>
										<textarea id="mdx_cp" onchange="dirty_query=true;"></textarea>
									</td>
								</tr>
								<tr>
									<td style="max-width:900px;" colspan="3">
										<form id="mdx_form" style="padding:0px;">
											<div id="mdx_container">
												<%-- render mdx query editor --%>
												<wcf:render ref="<%=mdxEditId%>" xslUri="/stpivot/xml/wcf/wcf.xsl" xslCache="true" />
											</div>
										</form>
									</td>
								</tr>
							</table>
						</div>
						<script>
							// Init MDX Editor
							var editor = CodeMirror.fromTextArea(document.getElementById("mdx_cp"), {
								mode: "text/x-mdx",
								indentUnit: 2,
								indentWithTabs: true,
								tabMode: "shift",
								enterMode: "keep",
								lineNumbers: true,
								firstLineNumber: 1,
								gutter: true,
								readOnly: false,
								onCursorActivity: function(){
									editor.setLineClass(hlLine, null);
									hlLine = editor.setLineClass(editor.getCursor().line, "activeline");
								},
								onGutterClick: function(cm, n){
									var info = cm.lineInfo(n);
									if (info.markerText)
										cm.clearMarker(n);
									else
										cm.setMarker(n, "<span style=\"color: #900\">->%N%</span>");
								},
								matchBrackets: true,
								workTime: 200,
								workDelay: 300,
								undoDepth : 40,
								onKeyEvent: function(i, e){
									if (e.keyCode == 32 && (e.ctrlKey || e.metaKey) && !e.altKey){
										e.stop();
										return startComplete();
									}
								}
							});
						
						var hlLine = editor.setLineClass(0, "activeline");
						</script>
						
						<div class="ui-layout-center">
							<table id="options_panel" style="float:left;position:absolute;z-index:1000;font-size:9px;">
								<tr>
									<td>
										<div id="options_tabs" style="display:none;">
											<ul>
												<li><a href="#chart_opts"><span>Chart</span></a></li>
												<li><a href="#axis_opts"><span>Axis</span></a></li>
												<li><a href="#sort_opts"><span>Sort</span></a></li>
												<li><a href="#print_opts"><span>Print</span></a></li>
											</ul>
											<div id="chart_opts">
												<input type="image" src="stpivot/style/images/xml.png" alt="XML" title="Show Xml (chartForm)" onclick="showXml('<%=chartFormId%>')" class="showxml"/>
												<form id="chartopts_form">
													<div id="chartopts_container">
														<%-- render chart properties --%>
														<wcf:render ref="<%=chartFormId%>" xslUri="/stpivot/xml/wcf/wcf.xsl" xslCache="true" />
													</div>
												</form>
											</div>
											<div id="axis_opts">
												<input type="image" src="stpivot/style/images/xml.png" alt="XML" title="Show Xml (axisForm)" onclick="showXml('<%=axisFormId%>')" class="showxml"/>
												<form id="axisopts_form">
													<div id="axisopts_container">
														<%-- axis properties --%>
														<wcf:render ref="<%=axisFormId%>" xslUri="/stpivot/xml/wcf/wcf.xsl" xslCache="true" />
													</div>
												</form>
											</div>
											<div id="sort_opts">
												<input type="image" src="stpivot/style/images/xml.png" alt="XML" title="Show Xml (sortForm)" onclick="showXml('<%=sortFormId%>')" class="showxml"/>
												<form id="sortopts_form">
													<div id="sortopts_container">
														<%-- sort properties --%>
														<wcf:render ref="<%=sortFormId%>" xslUri="/stpivot/xml/wcf/wcf.xsl" xslCache="true" />
													</div>
												</form>
											</div>
											<div id="print_opts">
												<input type="image" src="stpivot/style/images/xml.png" alt="XML" title="Show Xml (printForm)" onclick="showXml('<%=printFormId%>')" class="showxml"/>
												<form id="printopts_form">
													<div id="printopts_container">
														<%-- print properties --%>
														<wcf:render ref="<%=printFormId%>" xslUri="/stpivot/xml/wcf/wcf.xsl" xslCache="true" />
													</div>
												</form>
											</div>
										</div>
									</td>
								</tr>
							</table>
							<div class="dialog01_content">
								<%
								if( subscribeResult != null ) {
									out.println( ESAPI.encoder().encodeForHTML( subscribeResult ));
									out.println( "<br/>" ); //$NON-NLS-1$
								}								
								%>
								<table border="0" width="100%" class="content_container2" cellpadding="0" cellspacing="0">
									<tr>
										<td class="content_body">
											<table border="0">
												<tr>
													<td valign="top">
														<input type="image" src="stpivot/style/images/xml.png" alt="XML" title="Show Xml (table)" onclick="showXml('<%=tableId%>')" class="showxml"/>
														<input type="image" src="stpivot/style/images/xml.png" alt="XML" title="Show Xml (chart)" onclick="showXml('<%=chartId%>')" class="showxml"/>
														<form id="save_form" method="POST" style="display:none;">
															<input type="hidden" name="save-action" value="saveAs" />
															<input type="hidden" name="save-path" value="" />
															<input type="hidden" name="save-file" value="" />
															<input type="hidden" name="save-title" value="" />
														</form>
														<div id="formula_dialog" style="border:1px solid gray;z-Index:1001;background-color:white; position:absolute;display:none;:">
															<table>
																<tr>
																	<td align="left" colspan="2">
																		<input type="image" src="stpivot/style/jpivot/navi/button_cancel.png" alt="Cancel" title="Cancel" style="float:right" onclick="cancelFormula()"/>
																		<input type="image" src="stpivot/style/jpivot/navi/button_ok.png" alt="Ok" title="Ok" style="float:right;margin-right:5px;" onclick="saveFormula()"/>
																		<b>Formula Editor</b></td>
																	</td>
																</tr>
																<tr id="formula_new_line">
																	<td align="right" style="width:1%"></td>
																	<td align="left">
																		<input type="radio" name="formula_type" value="member" onclick="changeFormulaType(this)" checked="checked" />[ Member ]
																		<input type="radio" name="formula_type" value="set" onclick="changeFormulaType(this)" />{ NamedSet }
																		<input type="hidden" name="formula_id" value="" />
																	</td>
																</tr>
																<tr id="formula_dim_line">
																	<td align="right" style="width:1%">Dimension:</td>
																	<td align="left">
																		<select name="formula_dimension" style="width:100%" onchange="changeFormulaDimension(this)"></select>
																	</td>
																</tr>
																<tr>
																	<td align="right" style="width:1%">Name:</td>
																	<td align="left">
																		<input type="text" name="formula_name" value="" size="40" style="width:100%" />
																	</td>
																</tr>
																<tr><td align="right">Expression:</td><td align="right"><input type="image" src="stpivot/style/images/cube_navigator.gif" alt="(+)" title="Cube" onclick="toggleExpExplorer()"/></td></tr>
																<tr>
																	<td valign="top">
																		<select onchange="functionFilter(this.value)" style="width:100px">
																			<option value="">( functions )</option>
																			<option value="logical">Logical</option>
																			<option value="set">Set</option>
																			<option value="member">Member</option>
																			<option value="numeric">Numeric</option>
																			<option value="integer">Integer</option>
																			<option value="string">String</option>
																			<option value="datetime">Datetime</option>
																			<option value="misc">Misc</option>
																		</select>
																		<select id="formula_functions" ondblclick="functionSelect(this.value)" size="11" style="width:100px">
																			<jsp:include page="stpivot/mdx_functions_opts.jsp"/>
																		</select>
																	</td>
																	<td valign="top" style="width:600px;max-width:600px;">
																		<div id="formula_exp_explorer" style="border:1px solid gray;z-Index:1100;background-color:white; position:absolute;display:none;right:5;margin-top:5px;width:300px;height:250px;float:right;overflow:scroll;" /></div>
																		<textarea id="formula_exp" name="formula_exp">''</textarea>
																	</td>
																</tr>
																<tr id="formula_props_line">
																	<td align="left" colspan="2">
																		<table id="formula_props">
																			<tbody>
																				<tr>
																					<td><input type="text" value="format_string" size="10" class="prop_name"/></td>
																					<td>&nbsp;=&nbsp;</td>
																					<td><input type="text" value='""' size="40" class="prop_value"/></td>
																					<td><input type="image" src="stpivot/style/jpivot/navi/remove.png" alt="-" title="Remove" onclick="removeFormulaProperty(this)" /></td>
																				</tr>
																				<!--tr>
																					<td><input type="text" value="SOLVE_ORDER" size="16" class="prop_name"/></td>
																					<td>&nbsp;=&nbsp;</td>
																					<td><input type="text" value="0" size="26" class="prop_value"/></td>
																					<td><input type="image" src="stpivot/style/jpivot/navi/remove.png" alt="-" title="Remove" onclick="removeFormulaProperty(this)" /></td>
																				</tr-->
																			</tbody>
																			<tfoot>
																				<td><input type="image" src="stpivot/style/jpivot/navi/add.png" alt="+" title="Add property" onclick="addFormulaProperty()" /><td>
																			</tfoot>
																		</table>
																	</td>
																</tr>
															</table>
														</div>
														<script>
															// Init MDX Formula Editor
															var formulaEditor = CodeMirror.fromTextArea(document.getElementById("formula_exp"), {
																mode: "text/x-mdx",
																indentWithTabs: true,
																tabMode: "shift",
																enterMode: "keep",
																lineNumbers: true,
																gutter: true,
																readOnly: false,
																matchBrackets: true,
																workTime: 200,
																workDelay: 300,
																undoDepth : 40
															});
														</script>
														<form id="grid_form">
															<div id="grid_container">
																<%
																// if there was an overflow, show error message
																// note, if internal error is caused by query.getResult(),
																// no usable log messages make it to the user or the log system
																if (_olapModel != null) {
																	try {
																		_olapModel.getResult();
																		if (_olapModel.getResult().isOverflowOccured()) {
																			%><p><strong style="color: red">Resultset overflow occured</strong></p><%
																		}
																	} catch (Throwable t) {
																		t.printStackTrace();
																		%><p><strong style="color: red">Error Occurred While getting Resultset</strong></p><%
																	}
																}
																%>
																<%-- render the table --%>
																<div id="grid_dialog" style="<%= (showGrid)?"":"display:none;" %>">
																	<% if (showGrid) { %>
																		<p><wcf:render ref="<%=tableId%>" xslUri="/stpivot/xml/jpivot/table/mdxtable.xsl" xslCache="true" />
																		<p><font size="2"><img src="stpivot/style/jpivot/navi/filter.png" width="13" height="13"/> <wcf:render ref="<%=tableId%>" xslUri="/stpivot/xml/jpivot/table/mdxslicer.xsl" xslCache="true" /></font></p>
																	<% } %>
																</div>
															</div>
														</form>
													</td>
													<td valign="top">
														<!--form id="chart_form"-->
															<div id="chart_dialog" style="border: 1px solid gray;z-Index:100;background-color:white; float:right; position:relative;<%= (_chart.isVisible())?"":"display:none;" %>">
																<div id="chart_options" style="float:right;">
																	<table width="100%">
																		<tr>
																			<td width="100%">
																				<table id="chart_options_panel" style="display:none;font-size:small;">
																					<tr>
																						<td title="Type">
																							<select id="combo_chart_type" onchange="changeChartOptions()">
																								<option value="1" style="background:url(stpivot/style/images/bar.png) no-repeat;padding-left:20px;" selected="selected">Bar</option>
																								<option value="5" style="background:url(stpivot/style/images/stackedbar.png) no-repeat;padding-left:20px;">Stacked bar</option>
																								<option value="9" style="background:url(stpivot/style/images/line.png) no-repeat;padding-left:20px;">Line</option>
																								<option value="11" style="background:url(stpivot/style/images/area.png) no-repeat;padding-left:20px;">Area</option>
																								<option value="13" style="background:url(stpivot/style/images/stackedarea.png) no-repeat;padding-left:20px;">Stacked area</option>
																								<option value="15" style="background:url(stpivot/style/images/pie.png) no-repeat;padding-left:20px;">Pie</option>
																							</select>
																						</td>
																						<td title="Vertical" nowrap="nowrap" style="background: url(stpivot/style/images/vertical.png) 12px no-repeat;"><input type="radio" name="radio_orientation" id="radio_orientation_vertical" checked="checked" onclick="changeChartOptions()" />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
																						<td title="Horizontal" nowrap="nowrap" style="background: url(stpivot/style/images/horizontal.png) 16px no-repeat;"><input type="radio" name="radio_orientation" id="radio_orientation_horizontal" onclick="changeChartOptions()" />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
																						<td title="3D" nowrap="nowrap" style="background: url(stpivot/style/images/3d.png) 10px no-repeat;"><input type="checkbox" id="check_3d" onclick="changeChartOptions()" />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
																						<td title="Legend" nowrap="nowrap" style="background: url(stpivot/style/images/legend.png) 10px no-repeat;"><input type="checkbox" id="check_legend" onclick="changeChartOptions()" />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
																						<td title="Slicer" nowrap="nowrap" style="background: url(stpivot/style/images/slicer.png) 10px no-repeat;"><input type="checkbox" id="check_slicer" onclick="changeChartOptions()" />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
																					</tr>
																				</table>
																				<script>
																					var chartType = <%= chartType %>;
																					var chartVertical = true;
																					var chart3d = false;
																					var chartShowSlicer = <%= chartShowSlicer %>;
																					var chartShowLegend = <%= chartShowLegend %>;
																					
																					updateChartOptions();
																				</script>
																			</td>
																			<td valign="top" heigh="22">
																				<img src="stpivot/style/images/chart.png" onclick="$('#chart_options_panel').toggle()" title="Charts opts" height="16" class="imgButton"/>
																			</td>
																		</tr>
																	</table>
																</div>
																<div id="chart_container">
																	<%-- render chart --%>
																	<wcf:render ref="<%=chartId%>" xslUri="/stpivot/xml/jpivot/chart/chart.xsl" xslCache="true" />
																</div>
															</div>
														<!--/form-->
													</td>
												</tr>
												<tr>
													<td colspan="2">
														<div>
															<input type="image" src="stpivot/style/images/powered_stratebi.gif" alt="Powered by StrateBI" title="Logo StrateBI" onclick="window.open('http://www.stratebi.com')"/>
														</div>
													</td>	
												</tr>
												<tr>
													<td colspan="2">
														<input type="image" src="stpivot/style/images/xml.png" alt="XML" title="Show Xml (drillThroughTable)" onclick="showXml('<%=drillThroughTableId%>')" class="showxml"/>
														<form id="drill_form">
															<div id="drill_container">
																<p>
																	<%-- drill through table --%>
																	<wcf:render ref="<%=drillThroughTableId%>" xslUri="/stpivot/xml/wcf/wcf.xsl" xslCache="true" />
																</p>
															</div>
														</form>
													</td>
												</tr>
											</table>
										</td>
									</tr>
								</table>
							</div>
						</div>
						<div id="browser.modalDiv" class='browser'>
							<div id="browser.saveasDialog" style="display: none; position: absolute; top: 100px; left: 200px; height: 25px;">
								<table border="0" cellspacing="0" cellpadding="0" class="popupDialog_table">
									<tr>
										<td class="popupDialog_header">
											<div id="browser.titleBar" class="popupDialogTitleBar" onmouseover="this.onmousedown=Dialog.dragIsDown;" ondragstart="return false;" onselectstart="return false;"></div>
										</td>
									</tr>
									<tr>
										<td valign="top" style="padding: 15px;">
											<table style="width: 40em; height: 100%;" border="0" cellspacing="2px" cellpadding="2px">
												<tr>
													<td id="saveDlgSaveAsPrompt" style='width: 25%'>Save As:</td>
													<td style='width: 75%'><input type="text" id="browser.saveAsNameInputText" tabindex='0' name="textfield" class="browserSaveAsText" /></td>
												</tr>
												<tr>
													<td id="saveDlgWherePrompt">Where:</td>
													<td>
														<table style='width: 100%;' border="0" cellspacing="0" cellpadding="0">
															<tr>
																<td style="width: 100%; padding-right: 5px;" id="browser.comboContainer"></td>
																<td><img id='browser.upImg' src="adhoc/images/up.png" alt="up" /></td>
															</tr>
														</table>
													</td>
												</tr>
												<tr>
													<td id="saveDlgSelectSltnTitle" colspan='2'>Select a Solution</td>
												</tr>
												<tr>
													<td id="browser.solutionFolderListTd" height="100%" colspan='2'></td>
												</tr>
											</table>
										</td>
									</tr>
									<tr>
										<td style="border-top: 1px solid #818f49; background-color: #ffffff;">
											<table border="0" cellpadding="0" cellspacing="0" align="right">
												<tr>
													<td id="browser.saveBtnContainer" width="75"></td>
													<td id="browser.cancelBtnContainer" width="85"></td>
												</tr>
											</table>
										</td>
									</tr>
								</table>
							</div>
						</div>
						
					</body>
					
				</html>
				<%
			} else if(pivotPart.equals("navi")){
				if(!_navi.isVisible()){
					_navi.setVisible(true);
				}
				%>
				<%-- render navigator --%>
				<wcf:render ref="<%=naviId%>" xslUri="/stpivot/xml/jpivot/navi/navigator.xsl" xslCache="true" />
				<%
			} else if(pivotPart.equals("toolbar")){
				%>
				<%-- render toolbar --%>
				<wcf:render ref="<%=toolbarId%>" xslUri="/stpivot/xml/jpivot/toolbar/htoolbar.xsl" xslCache="true" />
				<%
			} else if(pivotPart.equals("table")){
				if( subscribeResult != null ) {
					out.println( subscribeResult );
					out.println( "<br/>" );
				}
				
				// if there was an overflow, show error message
				// note, if internal error is caused by query.getResult(),
				// no usable log messages make it to the user or the log system
				if (_olapModel != null) {
					try {
						_olapModel.getResult();
						if (_olapModel.getResult().isOverflowOccured()) {
							%><p><strong style="color: red">Resultset overflow occured</strong></p><%
						}
					} catch (Throwable t) {
						t.printStackTrace();
						%><p><strong style="color: red">Error Occurred While getting Resultset</strong></p><%
					}
				}
				// render the table
				%><div id="grid_dialog" style="<%= (showGrid)?"":"display:none;" %>"><%
					if (showGrid) {
						%>
						<p><wcf:render ref="<%=tableId%>" xslUri="/stpivot/xml/jpivot/table/mdxtable.xsl" xslCache="true" />
						<p><font size="2"><img src="stpivot/style/jpivot/navi/filter.png" width="13" height="13"/> <wcf:render ref="<%=tableId%>" xslUri="/stpivot/xml/jpivot/table/mdxslicer.xsl" xslCache="true" /></font></p>
						<%
					}
				%></div><%
			} else if(pivotPart.equals("mdx")){
				%>
				<wcf:render ref="<%=mdxEditId%>" xslUri="/stpivot/xml/wcf/wcf.xsl" xslCache="true" />
				<%
			} else if(pivotPart.equals("xml")){
				String componentId = request.getParameter("render");
				response.setContentType("text/xml; charset=UTF-8");
				%>
				<ROOT>
					<wcf:render ref="<%= componentId %>" xslUri="/stpivot/xml/wcf/showxml.xsl" xslCache="true"/>
				</ROOT>
				<%
			} else if(pivotPart.equals("drill")){
				%>
				<wcf:render ref="<%=drillThroughTableId%>" xslUri="/stpivot/xml/wcf/wcf.xsl" xslCache="true" />
				<%
			} else if(pivotPart.equals("chart")){
				if (request.getParameter("chartType") != null) {
					chartType = Integer.parseInt( request.getParameter("chartType") );
					_chart.setChartType( chartType );
				}
				if (request.getParameter("chartWidth") != null) {
					chartWidth = Integer.parseInt( request.getParameter("chartWidth") );
					if (chartWidth > 0) {
						_chart.setChartWidth(chartWidth);
					} else {
						_chart.setChartWidth(500);		// 500 is the default that the ChartCompoent uses
					}
				}
				if (request.getParameter("chartHeight") != null) {
					chartHeight = Integer.parseInt( request.getParameter("chartHeight") );
					if (chartHeight > 0) {
						_chart.setChartHeight(chartHeight);
					} else {
						_chart.setChartHeight(300);	// 300 is the default that the ChartComponent uses
					}
				}
				if (request.getParameter("chartShowSlicer") != null) {
					chartShowSlicer = (new Boolean(request.getParameter("chartShowSlicer"))).booleanValue();;
					_chart.setShowSlicer(chartShowSlicer);
				}
				if (request.getParameter("chartShowLegend") != null) {
					chartShowLegend = (new Boolean(request.getParameter("chartShowLegend"))).booleanValue();;
					_chart.setShowLegend(chartShowLegend);
				}
				%>
				<wcf:render ref="<%=chartId%>" xslUri="/stpivot/xml/jpivot/chart/chart.xsl" xslCache="true" />
				<%
			} else if(pivotPart.equals("model")){
				Dimension[] dimensions = _olapModel.getDimensions();
				MemberTree tree = (MemberTree) _olapModel.getExtension(MemberTree.ID);
				String result = "{ \"dimensions\": [\n";
				int dc = 0;
				for(int i=0;i<dimensions.length;i++){
					if(dc>0){ result += ",\n"; }
					dc++;
					result += "  { \"name\": \""+((MDXElement)dimensions[i]).getUniqueName()+"\", \"caption\": \""+((Displayable)dimensions[i]).getLabel()+"\", \"isTime\": "+dimensions[i].isTime()+", \"isMeasure\": "+dimensions[i].isMeasure()+",\n";
					result += "    \"hierarchies\": [\n";
					Hierarchy[] hierarchies = dimensions[i].getHierarchies();
					for(int j=0;j<hierarchies.length;j++){
						if(j>0){ result += ",\n"; }
						result += "      { \"name\": \""+((MDXElement)hierarchies[j]).getUniqueName()+"\", \"caption\": \""+((Displayable)hierarchies[j]).getLabel()+"\", \"hasAll\": "+hierarchies[j].hasAll()+",\n";
						result += "        \"levels\": [\n";
						Level[] levels = hierarchies[j].getLevels();
						for(int k=0;k<levels.length;k++){
							if(k>0){ result += ",\n"; }
							result += "        { \"name\": \""+((MDXElement) levels[k]).getUniqueName()+"\", \"caption\": \""+((Displayable)levels[k]).getLabel()+"\", \"depth\": "+((MDXLevel) levels[k]).getDepth()+", \"isAll\": "+((MDXLevel) levels[k]).isAll()+", \"hasChildLevel\": "+((MDXLevel) levels[k]).hasChildLevel()+" }";
						}
						result += "        ] ,\n";
						result += "        \"rootMembers\": [\n";
						Member[] rootMembers = tree.getRootMembers(hierarchies[j]);
						for(int k=0;k<rootMembers.length;k++){
							if(k>0){ result += ",\n"; }
							result += "        { \"name\": \""+((MDXElement)rootMembers[k]).getUniqueName()+"\", \"caption\": \""+((Displayable)rootMembers[k]).getLabel()+"\", \"hasChildren\": "+tree.hasChildren(rootMembers[k])+"}";
						}
						result += "] }";
					}
					result += "] }";
				}
				result += " ],\n";
				Result _result = _olapModel.getResult();
				Axis[] _axes = _result.getAxes();
				Axis _slicer = _result.getSlicer();
				result += "\"columns\": [\n";
				if(_axes.length>0){
					Hierarchy[] hierarchies = _axes[0].getHierarchies();
					for(int i=0;i<hierarchies.length;i++){
						if(i>0){ result += ",\n"; }
						result += "  { \"name\": \""+((MDXElement)hierarchies[i]).getUniqueName()+"\"}";
					}
				}
				result += "\n],\n";
				result += "\"rows\": [\n";
				if(_axes.length>1){
					Hierarchy[] hierarchies = _axes[1].getHierarchies();
					for(int i=0;i<hierarchies.length;i++){
						if(i>0){ result += ",\n"; }
						result += "  { \"name\": \""+((MDXElement)hierarchies[i]).getUniqueName()+"\"}";
					}
				}
				result += "\n],\n";
				result += "\"slicer\": [\n";
				Hierarchy[] hierarchies = _slicer.getHierarchies();
				for(int i=0;i<hierarchies.length;i++){
					if(i>0){ result += ",\n"; }
					result += "  { \"name\": \""+((MDXElement)hierarchies[i]).getUniqueName()+"\"}";
				}
				result += "\n]\n";
				result += "}";
				%><%= result %><%
			} else if(pivotPart.equals("memberChildren")){
				ExpressionParser parser = (ExpressionParser) _olapModel.getExtension(ExpressionParser.ID);
				MemberTree tree = (MemberTree) _olapModel.getExtension(MemberTree.ID);
				String uniqueName = request.getParameter("uniqueName");
				Member member = parser.lookupMember(uniqueName);
				Member[] children = tree.getChildren(member);
				String result;
				result  = "[";
				for(int i=0;i<children.length;i++){
					if(i>0){ result += ","; }
					result += "{ \"name\": \""+((MDXElement)children[i]).getUniqueName()+"\", \"caption\": \""+((Displayable)children[i]).getLabel()+"\", \"hasChildren\": "+tree.hasChildren(children[i])+"}";
				}
				result += "]";
				%><%= result %><%
			} else if(pivotPart.equals("validateMDX")){
				MdxQuery q = (MdxQuery) _olapModel.getExtension(MdxQuery.ID);
				String newQuery = request.getParameter("query");
				String result = "";
				try {
					q.setMdxQuery(newQuery);
				} catch (Throwable e){
					result = e.getMessage();
				}%><%= result %><%
			} else if(pivotPart.equals("noanswer")){
				// Clear mondrian cache
				if (request.getParameter("clearCache") != null) {
					if(Boolean.parseBoolean( request.getParameter("clearCache") )){
						//flushSchemaCache
						mondrian.rolap.agg.AggregationManager.instance().getCacheControl(null).flushSchemaCache();
					}
				}
				// Toggle chart display
				if (request.getParameter("showChart") != null) {
					_chart.setVisible(Boolean.parseBoolean( request.getParameter("showChart") ));
				}
				// Toggle grid display
				if (request.getParameter("showGrid") != null) {
					session.setAttribute("pivot-"+PivotViewComponent.SHOWGRID+"-"+pivotId, Boolean.parseBoolean(request.getParameter("showGrid")) );
				}
			} else if(pivotPart.equals("save")){
				
				// Take care of saving this xaction
				if ( saveAction != null ) {
					// Get the current mdx
					String mdx = null;
					String connectString = null;
					if( _table != null ) {
						OlapModel olapModel = _table.getOlapModel();
						while( olapModel != null ) {
							if( olapModel instanceof OlapModelProxy ) {
								OlapModelProxy proxy = (OlapModelProxy) olapModel;
								olapModel = proxy.getDelegate();
							}
							if( olapModel instanceof OlapModelDecorator) {
								OlapModelDecorator decorator = (OlapModelDecorator) olapModel;
								olapModel = decorator.getDelegate();
							}
							if( olapModel instanceof MdxOlapModel) {
								MdxOlapModel model = (MdxOlapModel) olapModel;
								mdx = model.getCurrentMdx();
								olapModel = null;
							}
						}
					}
					
					HashMap props = new HashMap();
					
					props.put(PivotViewComponent.MODEL, catalogUri);
					props.put(PivotViewComponent.CONNECTION, dataSource);
					props.put(PivotViewComponent.ROLE, role);
					props.put(PivotViewComponent.SHOWGRID, new Boolean(showGrid));
					props.put("query", mdx);
					props.put(PivotViewComponent.OPTIONS, options);
					props.put(PivotViewComponent.TITLE, request.getParameter("save-title"));
					props.put("actionreference", actionReference);
					
					if(_chart != null){
						props.put(PivotViewComponent.CHARTTYPE, new Integer(_chart.getChartType()));
						props.put(PivotViewComponent.CHARTWIDTH, new Integer(_chart.getChartWidth()));
						props.put(PivotViewComponent.CHARTHEIGHT, new Integer(_chart.getChartHeight()));
						if (_chart.isVisible() && chartLocation.equalsIgnoreCase("none")){
							chartLocation = "bottom";
						}
						props.put(PivotViewComponent.CHARTLOCATION, _chart.isVisible() ? chartLocation : "none");
						props.put(PivotViewComponent.CHARTDRILLTHROUGHENABLED, new Boolean(_chart.isDrillThroughEnabled()));
						props.put(PivotViewComponent.CHARTTITLE, _chart.getChartTitle());
						props.put(PivotViewComponent.CHARTTITLEFONTFAMILY, _chart.getFontName());
						props.put(PivotViewComponent.CHARTTITLEFONTSTYLE, new Integer(_chart.getFontStyle()));
						props.put(PivotViewComponent.CHARTTITLEFONTSIZE, new Integer(_chart.getFontSize()));
						props.put(PivotViewComponent.CHARTHORIZAXISLABEL, _chart.getHorizAxisLabel());
						props.put(PivotViewComponent.CHARTVERTAXISLABEL, _chart.getVertAxisLabel());
						props.put(PivotViewComponent.CHARTAXISLABELFONTFAMILY, _chart.getAxisFontName());
						props.put(PivotViewComponent.CHARTAXISLABELFONTSTYLE, new Integer(_chart.getAxisFontStyle()));
						props.put(PivotViewComponent.CHARTAXISLABELFONTSIZE, new Integer(_chart.getAxisFontSize()));
						props.put(PivotViewComponent.CHARTAXISTICKFONTFAMILY, _chart.getAxisTickFontName());
						props.put(PivotViewComponent.CHARTAXISTICKFONTSTYLE, new Integer(_chart.getAxisTickFontStyle()));
						props.put(PivotViewComponent.CHARTAXISTICKFONTSIZE, new Integer(_chart.getAxisTickFontSize()));
						props.put(PivotViewComponent.CHARTAXISTICKLABELROTATION, new Integer(_chart.getTickLabelRotate()));
						props.put(PivotViewComponent.CHARTSHOWLEGEND, new Boolean(_chart.getShowLegend()));
						props.put(PivotViewComponent.CHARTLEGENDLOCATION, new Integer(_chart.getLegendPosition()));
						props.put(PivotViewComponent.CHARTLEGENDFONTFAMILY, _chart.getLegendFontName());
						props.put(PivotViewComponent.CHARTLEGENDFONTSTYLE, new Integer(_chart.getLegendFontStyle()));
						props.put(PivotViewComponent.CHARTLEGENDFONTSIZE, new Integer(_chart.getLegendFontSize()));
						props.put(PivotViewComponent.CHARTSHOWSLICER, new Boolean(_chart.isShowSlicer()));
						props.put(PivotViewComponent.CHARTSLICERLOCATION, new Integer(_chart.getSlicerPosition()));
						props.put(PivotViewComponent.CHARTSLICERALIGNMENT, new Integer(_chart.getSlicerAlignment()));
						props.put(PivotViewComponent.CHARTSLICERFONTFAMILY, _chart.getSlicerFontName());
						props.put(PivotViewComponent.CHARTSLICERFONTSTYLE, new Integer(_chart.getSlicerFontStyle()));
						props.put(PivotViewComponent.CHARTSLICERFONTSIZE, new Integer(_chart.getSlicerFontSize()));
						props.put(PivotViewComponent.CHARTBACKGROUNDR, new Integer(_chart.getBgColorR()));
						props.put(PivotViewComponent.CHARTBACKGROUNDG, new Integer(_chart.getBgColorG()));
						props.put(PivotViewComponent.CHARTBACKGROUNDB, new Integer(_chart.getBgColorB()));
					}
					
					if (( "save".equals(saveAction)) || ("saveAs".equals(saveAction))) {
						
						// Overwrite is true, because the saveAs dialog checks for overwrite, and we never
						// would have gotten here unless the user selected to overwrite the file. 
						try {
							saveResult = AnalysisSaver.saveAnalysis(userSession, props, request.getParameter("save-path"), request.getParameter("save-file"), true);
							switch (saveResult) {
								case ISolutionRepository.FILE_ADD_SUCCESSFUL:
									saveMessage = Messages.getString("UI.USER_SAVE_SUCCESS");
									// only set the session attribute on success, it's the only path that requires it
									session.setAttribute( "save-message-"+pivotId, saveMessage); //$NON-NLS-1$
									break;
								case ISolutionRepository.FILE_EXISTS:
									// Shouldn't ever get here, since we pass overwrite=true;
									break;
								case ISolutionRepository.FILE_ADD_FAILED:
									saveMessage = Messages.getString("UI.USER_SAVE_FAILED_GENERAL");
									break;
								case ISolutionRepository.FILE_ADD_INVALID_PUBLISH_PASSWORD:
									// There is no publish password on this save...
									break;
								case ISolutionRepository.FILE_ADD_INVALID_USER_CREDENTIALS:
									saveMessage = Messages.getString("UI.USER_SAVE_FAILED_INVALID_USER_CREDS");
									break;
								case 0:
									saveMessage="";
									break;
							}
						} catch (Throwable e){
							saveResult = ISolutionRepository.FILE_ADD_FAILED;
							saveMessage = e.getMessage();
						}
					}
				}
				%><%= saveMessage %><%
			}
		}
	} catch (Throwable t ) {
		%> An error occurred while rendering Pivot.jsp. Please see the log for details. <%
		// TODO log an error
		t.printStackTrace();
	} finally {
		PentahoSystem.systemExitPoint();
	}
	%><%!
	private IRuntimeContext getRuntimeForQuery( String actionReference, HttpServletRequest request, IPentahoSession userSession ) {
		ActionInfo actionInfo = ActionInfo.parseActionString( actionReference );
		if( actionInfo == null ) {
			return null;
		}
		return getRuntimeForQuery( actionInfo.getSolutionName(), actionInfo.getPath(), actionInfo.getActionName(), request, userSession );
	}
	
	private IRuntimeContext getRuntimeForQuery( String solutionName, String actionPath, String actionName, HttpServletRequest request, IPentahoSession userSession ) {
		String processId = "PivotView"; //$NON-NLS-1$
		String instanceId = request.getParameter( "instance-id" ); //$NON-NLS-1$
		boolean doMessages = "true".equalsIgnoreCase( request.getParameter("debug" ) ); //$NON-NLS-1$ //$NON-NLS-2$
		
		ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
		SimpleOutputHandler outputHandler = new SimpleOutputHandler( outputStream, true );
		ISolutionEngine solutionEngine = PentahoSystem.get(ISolutionEngine.class, userSession );
		solutionEngine.init( userSession );
		IRuntimeContext context = null;
		ArrayList messages = new ArrayList();
		HttpRequestParameterProvider requestParameters = new HttpRequestParameterProvider( request );
		HttpSessionParameterProvider sessionParameters = new HttpSessionParameterProvider( userSession );
		HashMap parameterProviders = new HashMap();
		requestParameters.setParameter( PivotViewComponent.MODE, PivotViewComponent.EXECUTE ); //$NON-NLS-1$ //$NON-NLS-2$
    parameterProviders.put( HttpRequestParameterProvider.SCOPE_REQUEST, requestParameters ); //$NON-NLS-1$
    parameterProviders.put( HttpSessionParameterProvider.SCOPE_SESSION, sessionParameters ); //$NON-NLS-1$
    SimpleUrlFactory urlFactory = new SimpleUrlFactory( "" ); //$NON-NLS-1$
		
		context = solutionEngine.execute( solutionName, actionPath, actionName, Messages.getString("BaseTest.DEBUG_JUNIT_TEST"), false, true, instanceId, false, parameterProviders, outputHandler, null, urlFactory, messages ); //$NON-NLS-1$
		
		if( context != null && context.getStatus() == IRuntimeContext.RUNTIME_STATUS_SUCCESS ) {
			return context;
		} else {
			return null;
		}
	}
	%><%
} finally {
	wcfcontext.invalidate();
}
%>