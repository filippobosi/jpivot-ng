package com.stratebi.stpivot.jpivot.table;

import org.apache.log4j.Logger;
import org.w3c.dom.Element;

import com.tonbeller.jpivot.olap.model.Cell;
import com.tonbeller.jpivot.olap.model.Property;
import com.tonbeller.jpivot.table.span.PropertyUtils;
import com.tonbeller.jpivot.table.PartBuilderSupport;
import com.tonbeller.jpivot.table.CellBuilder;

/**
 * Created on 18.10.2002
 * 
 * @author av
 */
public class CellBuilderImpl extends PartBuilderSupport implements CellBuilder {

	private static final Logger logger = Logger
			.getLogger(CellBuilderImpl.class);

	private static final String STYLE = "style";

	private static final String NBSP = "\u00a0";

	/**
	 * renders DOM element of cell
	 */
	public Element build(Cell cell, boolean even) {
		Element cellElem = table.elem("cell");
		String s = cell.isNull() ? NBSP : cell.getFormattedValue();
		s = s.trim();
		if (s.length() == 0)
			s = NBSP;
		cellElem.setAttribute("value", s);
		if (logger.isDebugEnabled())
			logger.debug("building cell " + s);

		String v = cell.isNull() ? NBSP : cell.getValue().toString();
		v = v.trim();
		if (v.length() == 0)
			v = NBSP;
		cellElem.setAttribute("val", v);

		PropertyUtils.addProperties(cellElem, cell.getProperties());
		Property style = cell.getProperty(STYLE);
		if (style != null) {
			String value = style.getValue();
			if (value != null && value.length() > 0)
				cellElem.setAttribute(STYLE, value);
			else
				cellElem.setAttribute(STYLE, even ? "even" : "odd");
		} else
			cellElem.setAttribute(STYLE, even ? "even" : "odd");

		return cellElem;
	}
	
	/**
	 * returns null
	 */
	  public Object getBookmarkState(int levelOfDetail) {
	    return null;
	  }

}
