--
-- PostgreSQL database dump
--

-- Dumped from database version 11.18 (Debian 11.18-0+deb10u1)
-- Dumped by pg_dump version 17.1

-- Started on 2025-06-05 11:49:45

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 6 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- TOC entry 239 (class 1255 OID 22863)
-- Name: get_price_detail(character varying, character varying); Type: FUNCTION; Schema: public; Owner: main
--

CREATE FUNCTION public.get_price_detail(group_id_param character varying, channel_param character varying) RETURNS TABLE(sold_price numeric, total_qty bigint, total_revenue numeric, total_gross_profit numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.soldprice AS sold_price,
        SUM(s.qty) AS total_qty,
        ROUND(SUM(
            CASE 
                WHEN s.tax = 1 THEN (s.soldprice / 1.2) * s.qty
                ELSE s.soldprice * s.qty
            END
        ), 2) AS total_revenue,
        ROUND(SUM(
            CASE 
                WHEN s.tax = 1 THEN ((s.soldprice / 1.2) - s.cost::NUMERIC) * s.qty
                ELSE (s.soldprice - s.cost::NUMERIC) * s.qty
            END
        ), 2) AS total_gross_profit
    FROM sales s
    WHERE s.groupid = group_id_param
      AND s.channel = channel_param
    GROUP BY s.soldprice
    ORDER BY sold_price DESC;
END;
$$;


ALTER FUNCTION public.get_price_detail(group_id_param character varying, channel_param character varying) OWNER TO main;

--
-- TOC entry 252 (class 1255 OID 22864)
-- Name: get_recent_incoming_stock(); Type: FUNCTION; Schema: public; Owner: main
--

CREATE FUNCTION public.get_recent_incoming_stock() RETURNS TABLE(groupid character varying, code character varying, created_at timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        i.groupid, 
        i.code, 
        i.created_at
    FROM incoming_stock i
    WHERE i.created_at >= CURRENT_DATE - INTERVAL '8 days'
    ORDER BY i.created_at DESC;
END;
$$;


ALTER FUNCTION public.get_recent_incoming_stock() OWNER TO main;

--
-- TOC entry 253 (class 1255 OID 22865)
-- Name: groupid_summary_performance(); Type: FUNCTION; Schema: public; Owner: main
--

CREATE FUNCTION public.groupid_summary_performance() RETURNS TABLE(supplier character varying, groupid character varying, net_sales_qty numeric, revenue numeric, total_cost numeric, gross_profit numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    WITH sales_data AS (
        SELECT
            s.groupid,
            SUM(s.qty)::NUMERIC AS net_sales_qty, -- Explicitly cast SUM to NUMERIC
            SUM(
                CASE 
                    WHEN ss.tax = 1 THEN (s.soldprice / 1.2) * s.qty
                    ELSE s.soldprice * s.qty
                END
            ) AS total_revenue
        FROM sales s
        JOIN skusummary ss ON s.groupid = ss.groupid
        GROUP BY s.groupid, ss.tax
    )
    SELECT
        ss.supplier::VARCHAR(100), -- Cast supplier to VARCHAR(100)
        sd.groupid::VARCHAR(100),  -- Cast groupid to VARCHAR(100)
        sd.net_sales_qty,
        ROUND(sd.total_revenue, 2) AS revenue,
        ROUND(COALESCE(ss.cost::NUMERIC, 0) * ABS(sd.net_sales_qty), 2) AS total_cost,
        ROUND(
            sd.total_revenue - (COALESCE(ss.cost::NUMERIC, 0) * ABS(sd.net_sales_qty)),
            2
        ) AS gross_profit
    FROM sales_data sd
    JOIN skusummary ss ON sd.groupid = ss.groupid
    ORDER BY gross_profit DESC;
END;
$$;


ALTER FUNCTION public.groupid_summary_performance() OWNER TO main;

--
-- TOC entry 254 (class 1255 OID 22866)
-- Name: groupid_summary_performance_90(); Type: FUNCTION; Schema: public; Owner: main
--

CREATE FUNCTION public.groupid_summary_performance_90() RETURNS TABLE(supplier character varying, groupid character varying, net_sales_qty numeric, revenue numeric, total_cost numeric, gross_profit numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    WITH sales_data AS (
        SELECT
            s.groupid,
            SUM(s.qty)::NUMERIC AS net_sales_qty, -- Explicitly cast SUM to NUMERIC
            SUM(
                CASE 
                    WHEN ss.tax = 1 THEN (s.soldprice / 1.2) * s.qty
                    ELSE s.soldprice * s.qty
                END
            ) AS total_revenue
        FROM sales s
        JOIN skusummary ss ON s.groupid = ss.groupid
        WHERE s.solddate >= CURRENT_DATE - INTERVAL '90 days' -- Filter for the last 90 days
        GROUP BY s.groupid, ss.tax
    )
    SELECT
        ss.supplier::VARCHAR(100), -- Cast supplier to VARCHAR(100)
        sd.groupid::VARCHAR(100),  -- Cast groupid to VARCHAR(100)
        sd.net_sales_qty,
        ROUND(sd.total_revenue, 2) AS revenue,
        ROUND(COALESCE(ss.cost::NUMERIC, 0) * ABS(sd.net_sales_qty), 2) AS total_cost,
        ROUND(
            sd.total_revenue - (COALESCE(ss.cost::NUMERIC, 0) * ABS(sd.net_sales_qty)),
            2
        ) AS gross_profit
    FROM sales_data sd
    JOIN skusummary ss ON sd.groupid = ss.groupid
    ORDER BY gross_profit DESC;
END;
$$;


ALTER FUNCTION public.groupid_summary_performance_90() OWNER TO main;

SET default_tablespace = '';

--
-- TOC entry 196 (class 1259 OID 22867)
-- Name: amzfeed; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.amzfeed (
    sku character varying(50) NOT NULL,
    fnsku character varying(50),
    groupid character varying(50),
    code character varying(50) NOT NULL,
    fbafee character varying(50),
    asin character varying(50),
    amzreturn integer,
    amzsold integer,
    amzsoldprice character varying(10),
    amzsolddate character varying(30),
    amzprice character varying(10),
    amztotal integer,
    amzlive integer,
    amzsold7 integer,
    buybox character varying(10)
);


ALTER TABLE public.amzfeed OWNER TO brookfield_dev_user;

--
-- TOC entry 197 (class 1259 OID 22870)
-- Name: amzshipment; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.amzshipment (
    box integer NOT NULL,
    supplier character varying(50),
    code character varying(50),
    sku character varying(50) NOT NULL,
    fnsku character varying(50),
    qty integer,
    weight character varying(10),
    length character varying(10),
    height character varying(10),
    width character varying(10)
);


ALTER TABLE public.amzshipment OWNER TO brookfield_dev_user;

--
-- TOC entry 198 (class 1259 OID 22873)
-- Name: amzshipment_archive; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.amzshipment_archive (
    box integer,
    supplier character varying(50),
    code character varying(50),
    sku character varying(50),
    fnsku character varying(50),
    qty integer,
    created_at timestamp without time zone DEFAULT now(),
    id integer,
    weight character varying(10),
    length character varying(10),
    height character varying(10),
    width character varying(10)
);


ALTER TABLE public.amzshipment_archive OWNER TO brookfield_dev_user;

--
-- TOC entry 199 (class 1259 OID 22877)
-- Name: amzstockreport; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.amzstockreport (
    sku character varying(100) NOT NULL,
    fnsku character varying(20),
    title character varying(200),
    groupid character varying(50),
    code character varying(50) NOT NULL,
    supplier character varying(30),
    minlocal integer,
    localstock integer,
    ukd integer,
    amztotal integer,
    amzlive integer,
    sold integer,
    return integer,
    profit character varying(10),
    floor character varying(10),
    rrp character varying(10),
    price character varying(10),
    soldprice character varying(10),
    roi character varying(10),
    solddate character varying(20),
    inamazon integer,
    barcode character varying(20),
    season character varying(10),
    cost character varying(10),
    netsold integer,
    shopify integer,
    created character varying(20),
    pfgstock integer
);


ALTER TABLE public.amzstockreport OWNER TO brookfield_dev_user;

--
-- TOC entry 200 (class 1259 OID 22883)
-- Name: attributes; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.attributes (
    groupid character varying(100) NOT NULL,
    updated character varying(30),
    gender character varying(20),
    producttype character varying(100),
    tag1 character varying(50),
    tag2 character varying(50),
    tag3 character varying(50),
    tag4 character varying(50),
    tag5 character varying(50),
    tag6 character varying(50),
    tag7 character varying(50),
    tag8 character varying(50),
    tag9 character varying(50),
    tag10 character varying(50),
    alt character varying(50)
);


ALTER TABLE public.attributes OWNER TO brookfield_dev_user;

--
-- TOC entry 201 (class 1259 OID 22889)
-- Name: bclog; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.bclog (
    id integer NOT NULL,
    workstation character varying(50) NOT NULL,
    log character varying(500),
    section character varying(50),
    date date,
    "time" character varying(10)
);


ALTER TABLE public.bclog OWNER TO brookfield_dev_user;

--
-- TOC entry 202 (class 1259 OID 22895)
-- Name: bclog_id_seq; Type: SEQUENCE; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE public.bclog ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.bclog_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 203 (class 1259 OID 22897)
-- Name: birkstock; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.birkstock (
    groupid character varying(100) NOT NULL,
    style character varying(50),
    material character varying(50),
    width character varying(50),
    colour character varying(50),
    link character varying(200),
    size35 smallint,
    size35order smallint,
    size36 smallint,
    size36order smallint,
    size37 smallint,
    size37order smallint,
    size38 smallint,
    size38order smallint,
    size39 smallint,
    size39order smallint,
    size40 smallint,
    size40order smallint,
    size41 smallint,
    size41order smallint,
    size42 smallint,
    size42order smallint,
    size43 smallint,
    size43order smallint,
    size44 smallint,
    size44order smallint,
    size45 smallint,
    size45order smallint,
    size46 smallint,
    size46order smallint,
    title character varying(200)
);


ALTER TABLE public.birkstock OWNER TO brookfield_dev_user;

--
-- TOC entry 204 (class 1259 OID 22903)
-- Name: birktracker; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.birktracker (
    code character varying(100) NOT NULL,
    ordernum character varying(100) NOT NULL,
    placedate character varying(20),
    bksize character varying(20),
    requested integer,
    invoiced integer,
    arrived integer,
    invoicedate character varying(20),
    invoicenum character varying(20),
    justarrived integer,
    rrp character varying(10),
    cost character varying(10),
    colouralt integer,
    due character varying(20),
    ean character varying(20)
);


ALTER TABLE public.birktracker OWNER TO brookfield_dev_user;

--
-- TOC entry 205 (class 1259 OID 22906)
-- Name: brand; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.brand (
    brand character varying(50) NOT NULL,
    supplier character varying(50)
);


ALTER TABLE public.brand OWNER TO brookfield_dev_user;

--
-- TOC entry 206 (class 1259 OID 22909)
-- Name: campaign; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.campaign (
    title character varying(50) NOT NULL,
    budget character varying(10),
    roas character varying(10),
    id character varying(10) NOT NULL,
    items bigint,
    troas character varying(10),
    startdate date
);


ALTER TABLE public.campaign OWNER TO brookfield_dev_user;

--
-- TOC entry 207 (class 1259 OID 22912)
-- Name: category; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.category (
    id integer NOT NULL,
    categoryname character varying(50),
    gender character varying(20),
    brand character varying(100),
    producttype character varying(100),
    onbuy character varying(200),
    tiktok character varying(200)
);


ALTER TABLE public.category OWNER TO brookfield_dev_user;

--
-- TOC entry 208 (class 1259 OID 22918)
-- Name: colour; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.colour (
    colour character varying(50) NOT NULL
);


ALTER TABLE public.colour OWNER TO brookfield_dev_user;

--
-- TOC entry 209 (class 1259 OID 22921)
-- Name: grouplabel; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.grouplabel (
    label character varying(50),
    code character varying(20) NOT NULL
);


ALTER TABLE public.grouplabel OWNER TO brookfield_dev_user;

--
-- TOC entry 210 (class 1259 OID 22924)
-- Name: incoming_stock; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.incoming_stock (
    id integer NOT NULL,
    code character varying(100) NOT NULL,
    groupid character varying(100) NOT NULL,
    arrival_date date NOT NULL,
    quantity_added integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    target character varying(50),
    workstation character varying(50)
);


ALTER TABLE public.incoming_stock OWNER TO brookfield_dev_user;

--
-- TOC entry 211 (class 1259 OID 22929)
-- Name: incoming_stock_id_seq; Type: SEQUENCE; Schema: public; Owner: brookfield_dev_user
--

CREATE SEQUENCE public.incoming_stock_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.incoming_stock_id_seq OWNER TO brookfield_dev_user;

--
-- TOC entry 3175 (class 0 OID 0)
-- Dependencies: 211
-- Name: incoming_stock_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: brookfield_dev_user
--

ALTER SEQUENCE public.incoming_stock_id_seq OWNED BY public.incoming_stock.id;


--
-- TOC entry 212 (class 1259 OID 22931)
-- Name: inivalues; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.inivalues (
    attribute character varying(100) NOT NULL,
    value character varying(100) NOT NULL
);


ALTER TABLE public.inivalues OWNER TO brookfield_dev_user;

--
-- TOC entry 213 (class 1259 OID 22934)
-- Name: localstock; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.localstock (
    id character varying(100) NOT NULL,
    updated character varying(50),
    ordernum character varying(100),
    location character varying(100),
    groupid character varying(100),
    code character varying(100),
    supplier character varying(100),
    qty integer,
    brand character varying(100),
    deleted integer,
    assigned character varying(20),
    pickorder integer,
    allocated character varying(50) DEFAULT 'unallocated'::character varying
);


ALTER TABLE public.localstock OWNER TO brookfield_dev_user;

--
-- TOC entry 214 (class 1259 OID 22941)
-- Name: location; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.location (
    updated character varying(30),
    location character varying(50) NOT NULL,
    anypicks character varying(10),
    barcode character varying(20) NOT NULL,
    pickorder integer
);


ALTER TABLE public.location OWNER TO brookfield_dev_user;

--
-- TOC entry 215 (class 1259 OID 22944)
-- Name: offlinesold; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.offlinesold (
    id character varying(30) NOT NULL,
    location character varying(30),
    code character varying(50),
    orderdate date,
    groupid character varying(50),
    qty integer,
    ordertime character varying(10),
    soldprice numeric(5,2),
    collectedvat numeric(5,2),
    paytype character varying(10)
);


ALTER TABLE public.offlinesold OWNER TO brookfield_dev_user;

--
-- TOC entry 216 (class 1259 OID 22947)
-- Name: orderstatus; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.orderstatus (
    ordernum character varying(100) NOT NULL,
    shopifysku character varying(50) NOT NULL,
    qty integer,
    updated character varying(50),
    created character varying(50),
    batch character varying(10),
    supplier character varying(50),
    title character varying(200),
    shippingname character varying(100),
    postcode character varying(20),
    address1 character varying(200),
    address2 character varying(200),
    company character varying(100),
    city character varying(100),
    county character varying(100),
    country character varying(100),
    phone character varying(50),
    shippingnotes character varying(200),
    orderdate character varying(50),
    ukd integer,
    localstock integer,
    amz integer,
    othersupplier integer,
    fnsku character varying(20),
    weight character varying(10),
    pickedqty integer,
    email character varying(100),
    courier character varying(100),
    courierfixed integer,
    customerwaiting integer,
    notorderamz integer,
    alloworder integer,
    searchalt character varying(50),
    channel character varying(50),
    picknotfound integer,
    fbaordered character varying(20),
    notes character varying(255),
    shopcustomer integer,
    shippingcost character varying(20),
    ordertype integer,
    ponumber character varying(50),
    createddate date,
    arrived smallint,
    arriveddate date
);


ALTER TABLE public.orderstatus OWNER TO brookfield_dev_user;

--
-- TOC entry 238 (class 1259 OID 23983)
-- Name: pickpin; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.pickpin (
    pin integer NOT NULL,
    name text NOT NULL
);


ALTER TABLE public.pickpin OWNER TO brookfield_dev_user;

--
-- TOC entry 237 (class 1259 OID 23981)
-- Name: pickpin_pin_seq; Type: SEQUENCE; Schema: public; Owner: brookfield_dev_user
--

CREATE SEQUENCE public.pickpin_pin_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pickpin_pin_seq OWNER TO brookfield_dev_user;

--
-- TOC entry 3176 (class 0 OID 0)
-- Dependencies: 237
-- Name: pickpin_pin_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: brookfield_dev_user
--

ALTER SEQUENCE public.pickpin_pin_seq OWNED BY public.pickpin.pin;


--
-- TOC entry 217 (class 1259 OID 22953)
-- Name: productlink; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.productlink (
    groupid character varying(50) NOT NULL,
    updated date
);


ALTER TABLE public.productlink OWNER TO brookfield_dev_user;

--
-- TOC entry 218 (class 1259 OID 22956)
-- Name: producttype; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.producttype (
    producttype character varying(50) NOT NULL
);


ALTER TABLE public.producttype OWNER TO brookfield_dev_user;

--
-- TOC entry 219 (class 1259 OID 22959)
-- Name: sales; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.sales (
    id integer NOT NULL,
    code character varying(50),
    solddate date,
    groupid character varying(50),
    ordernum character varying(50),
    ordertime character varying(20),
    qty integer,
    soldprice numeric(5,2),
    channel character varying(20),
    paytype character varying(20),
    collectedvat numeric(5,2),
    productname character varying(200),
    returnsaleid character varying(20),
    brand character varying(50),
    profit numeric(5,2) DEFAULT 0,
    discount integer
);


ALTER TABLE public.sales OWNER TO brookfield_dev_user;

--
-- TOC entry 220 (class 1259 OID 22966)
-- Name: sales_id_seq; Type: SEQUENCE; Schema: public; Owner: brookfield_dev_user
--

CREATE SEQUENCE public.sales_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sales_id_seq OWNER TO brookfield_dev_user;

--
-- TOC entry 3177 (class 0 OID 0)
-- Dependencies: 220
-- Name: sales_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: brookfield_dev_user
--

ALTER SEQUENCE public.sales_id_seq OWNED BY public.sales.id;


--
-- TOC entry 221 (class 1259 OID 22968)
-- Name: shopifyimages; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.shopifyimages (
    handle character varying(200) NOT NULL,
    imagepos smallint NOT NULL,
    imagesrc character varying(200)
);


ALTER TABLE public.shopifyimages OWNER TO brookfield_dev_user;

--
-- TOC entry 222 (class 1259 OID 22971)
-- Name: shopifysnapshot; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.shopifysnapshot (
    groupid character varying(100),
    code character varying(100) NOT NULL,
    stock integer,
    price character varying(10)
);


ALTER TABLE public.shopifysnapshot OWNER TO brookfield_dev_user;

--
-- TOC entry 223 (class 1259 OID 22974)
-- Name: shopifysold; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.shopifysold (
    id character varying(30) NOT NULL,
    code character varying(50),
    solddate date,
    groupid character varying(50),
    ordernum character varying(50),
    ordertime character varying(20),
    qty integer,
    soldprice character varying(10)
);


ALTER TABLE public.shopifysold OWNER TO brookfield_dev_user;

--
-- TOC entry 224 (class 1259 OID 22977)
-- Name: shopprices; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.shopprices (
    groupid character varying(50) NOT NULL,
    price character varying(10),
    location character varying(50),
    rrp character varying(10),
    changed integer,
    label character varying(20)
);


ALTER TABLE public.shopprices OWNER TO brookfield_dev_user;

--
-- TOC entry 225 (class 1259 OID 22980)
-- Name: skumap; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.skumap (
    sku character varying(50),
    updated character varying(30),
    groupid character varying(50) NOT NULL,
    variantlink character varying(20),
    optionsize character varying(100),
    uksize character varying(30),
    eurosize character varying(20),
    ean character varying(20),
    code character varying(50) NOT NULL,
    googleid character varying(100),
    googlestatus integer,
    search2 character varying(20),
    status character varying(10),
    notes character varying(200),
    cost character varying(10),
    tax integer,
    fba character varying(10),
    soldprice character varying(10),
    amzprice character varying(10),
    floor character varying(10),
    msp character varying(10),
    supplier character varying(30),
    nextdelivery character varying(20),
    deleted integer,
    minstock integer,
    weight character varying(10),
    amzreturn integer,
    amzsold integer,
    amzsoldprice character varying(10),
    amzsolddate character varying(20),
    googleadstatus character varying(20),
    amzminprice character varying(10),
    amzperformance integer,
    shelf integer,
    shopifyprice character varying(10),
    reportgroup_a character varying(50),
    reportgroup_b character varying(50),
    reportgroup_c character varying(50),
    reportgroup_d character varying(50),
    shopifyminprice character varying(10),
    amzmaxprice character varying(10),
    shopifymaxprice character varying(10),
    pricestatus integer,
    googlecampaign character varying(10),
    amzprofit character varying(10),
    tiktokskuid character varying(20),
    amzallow character varying(20),
    amz365 integer,
    shp365 integer,
    amzfeatureprice character varying(10),
    shopifynotes character varying(200),
    shopifyreplenstatus character varying(10),
    localreserve integer,
    order365 integer,
    amzorderdate2 date,
    fbafee numeric(5,2),
    amzrank integer,
    amzstorage numeric(5,2),
    cmb365 integer,
    stockcheck_class character varying(10),
    stockcheck_date date,
    amzrequest integer,
    amzpickrequest integer
);


ALTER TABLE public.skumap OWNER TO brookfield_dev_user;

--
-- TOC entry 226 (class 1259 OID 22986)
-- Name: skusummary; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.skusummary (
    groupid character varying(50) NOT NULL,
    updated character varying(30),
    shopify integer,
    googlestatus integer,
    colour character varying(20),
    colourmap character varying(20),
    variants integer,
    stockvariants integer,
    handle character varying(300),
    supplier character varying(30),
    brand character varying(30),
    notes character varying(200),
    rrp character varying(10),
    season character varying(10),
    imagename character varying(200),
    custom_label_0 character varying(200),
    custom_label_1 character varying(200),
    custom_label_2 character varying(200),
    custom_label_3 character varying(200),
    custom_label_4 character varying(200),
    created character varying(20),
    karen integer,
    tiktokshop integer,
    googlecampaign character varying(20),
    shopifyprice character varying(10),
    tiktokshopid character varying(20),
    minshopifyprice character varying(10),
    cost character varying(10),
    maxshopifyprice character varying(10),
    lowbench character varying(10),
    highbench character varying(10),
    insights character varying(10),
    birkcore integer,
    noukd integer,
    troas numeric(5,2),
    cmpbudget numeric(5,2),
    tax integer,
    shopifychange integer,
    width character varying(20),
    regular_groupid character varying(50),
    narrow_groupid character varying(50),
    material character varying(50),
    usereport integer DEFAULT 1
);


ALTER TABLE public.skusummary OWNER TO brookfield_dev_user;

--
-- TOC entry 227 (class 1259 OID 22993)
-- Name: stockorder; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.stockorder (
    id character varying(30) NOT NULL,
    code character varying(50),
    orderdate date,
    groupid character varying(50),
    qty integer,
    cost character varying(10)
);


ALTER TABLE public.stockorder OWNER TO brookfield_dev_user;

--
-- TOC entry 228 (class 1259 OID 22996)
-- Name: supplier; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.supplier (
    supplier character varying(100)
);


ALTER TABLE public.supplier OWNER TO brookfield_dev_user;

--
-- TOC entry 229 (class 1259 OID 22999)
-- Name: taglist; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.taglist (
    tag character varying(100) NOT NULL
);


ALTER TABLE public.taglist OWNER TO brookfield_dev_user;

--
-- TOC entry 230 (class 1259 OID 23002)
-- Name: title; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.title (
    groupid character varying(100) NOT NULL,
    updated character varying(30),
    shopifytitle character varying(200),
    googletitle character varying(150),
    googletitleb character varying(150)
);


ALTER TABLE public.title OWNER TO brookfield_dev_user;

--
-- TOC entry 231 (class 1259 OID 23008)
-- Name: ukdstock; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.ukdstock (
    groupid character varying(100) NOT NULL,
    code character varying(50) NOT NULL,
    stock integer,
    prevstock integer
);


ALTER TABLE public.ukdstock OWNER TO brookfield_dev_user;

--
-- TOC entry 232 (class 1259 OID 23011)
-- Name: weekly_stock_levels; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.weekly_stock_levels (
    id integer NOT NULL,
    groupid character varying(100) NOT NULL,
    week_start_date date NOT NULL,
    opening_stock integer NOT NULL,
    purchases integer DEFAULT 0,
    sales integer DEFAULT 0,
    returns integer DEFAULT 0,
    closing_stock integer NOT NULL,
    notes character varying(200)
);


ALTER TABLE public.weekly_stock_levels OWNER TO brookfield_dev_user;

--
-- TOC entry 233 (class 1259 OID 23017)
-- Name: weekly_stock_levels_id_seq; Type: SEQUENCE; Schema: public; Owner: brookfield_dev_user
--

CREATE SEQUENCE public.weekly_stock_levels_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.weekly_stock_levels_id_seq OWNER TO brookfield_dev_user;

--
-- TOC entry 3178 (class 0 OID 0)
-- Dependencies: 233
-- Name: weekly_stock_levels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: brookfield_dev_user
--

ALTER SEQUENCE public.weekly_stock_levels_id_seq OWNED BY public.weekly_stock_levels.id;


--
-- TOC entry 234 (class 1259 OID 23019)
-- Name: winner_channels; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.winner_channels (
    id integer NOT NULL,
    groupid character varying(100) NOT NULL,
    channel character varying(10) NOT NULL
);


ALTER TABLE public.winner_channels OWNER TO brookfield_dev_user;

--
-- TOC entry 235 (class 1259 OID 23022)
-- Name: winner_channels_id_seq; Type: SEQUENCE; Schema: public; Owner: brookfield_dev_user
--

CREATE SEQUENCE public.winner_channels_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.winner_channels_id_seq OWNER TO brookfield_dev_user;

--
-- TOC entry 3179 (class 0 OID 0)
-- Dependencies: 235
-- Name: winner_channels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: brookfield_dev_user
--

ALTER SEQUENCE public.winner_channels_id_seq OWNED BY public.winner_channels.id;


--
-- TOC entry 236 (class 1259 OID 23024)
-- Name: winner_products; Type: TABLE; Schema: public; Owner: brookfield_dev_user
--

CREATE TABLE public.winner_products (
    groupid character varying(100) NOT NULL,
    priority character varying(10),
    start_date date NOT NULL,
    end_date date,
    notes text,
    CONSTRAINT winner_products_priority_check CHECK (((priority)::text = ANY (ARRAY[('High'::character varying)::text, ('Medium'::character varying)::text, ('Low'::character varying)::text])))
);


ALTER TABLE public.winner_products OWNER TO brookfield_dev_user;

--
-- TOC entry 2949 (class 2604 OID 23031)
-- Name: incoming_stock id; Type: DEFAULT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.incoming_stock ALTER COLUMN id SET DEFAULT nextval('public.incoming_stock_id_seq'::regclass);


--
-- TOC entry 2961 (class 2604 OID 23986)
-- Name: pickpin pin; Type: DEFAULT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.pickpin ALTER COLUMN pin SET DEFAULT nextval('public.pickpin_pin_seq'::regclass);


--
-- TOC entry 2953 (class 2604 OID 23032)
-- Name: sales id; Type: DEFAULT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.sales ALTER COLUMN id SET DEFAULT nextval('public.sales_id_seq'::regclass);


--
-- TOC entry 2956 (class 2604 OID 23033)
-- Name: weekly_stock_levels id; Type: DEFAULT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.weekly_stock_levels ALTER COLUMN id SET DEFAULT nextval('public.weekly_stock_levels_id_seq'::regclass);


--
-- TOC entry 2960 (class 2604 OID 23034)
-- Name: winner_channels id; Type: DEFAULT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.winner_channels ALTER COLUMN id SET DEFAULT nextval('public.winner_channels_id_seq'::regclass);


--
-- TOC entry 2964 (class 2606 OID 23036)
-- Name: amzfeed amzfeed_pkey; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.amzfeed
    ADD CONSTRAINT amzfeed_pkey PRIMARY KEY (code);


--
-- TOC entry 2966 (class 2606 OID 23038)
-- Name: amzshipment amzshipment_pkey; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.amzshipment
    ADD CONSTRAINT amzshipment_pkey PRIMARY KEY (box, sku);


--
-- TOC entry 2968 (class 2606 OID 23040)
-- Name: amzstockreport amzstockreport_pkey; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.amzstockreport
    ADD CONSTRAINT amzstockreport_pkey PRIMARY KEY (code);


--
-- TOC entry 2970 (class 2606 OID 23042)
-- Name: attributes attributes_pkey; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.attributes
    ADD CONSTRAINT attributes_pkey PRIMARY KEY (groupid);


--
-- TOC entry 2972 (class 2606 OID 23044)
-- Name: bclog bclog_pkey; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.bclog
    ADD CONSTRAINT bclog_pkey PRIMARY KEY (id);


--
-- TOC entry 2974 (class 2606 OID 23046)
-- Name: birkstock birkstock_primary; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.birkstock
    ADD CONSTRAINT birkstock_primary PRIMARY KEY (groupid);


--
-- TOC entry 2976 (class 2606 OID 23048)
-- Name: birktracker birktracker_primary; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.birktracker
    ADD CONSTRAINT birktracker_primary PRIMARY KEY (code, ordernum);


--
-- TOC entry 2978 (class 2606 OID 23050)
-- Name: brand brand_pkey; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.brand
    ADD CONSTRAINT brand_pkey PRIMARY KEY (brand);


--
-- TOC entry 2980 (class 2606 OID 23052)
-- Name: campaign campaign_pkey; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.campaign
    ADD CONSTRAINT campaign_pkey PRIMARY KEY (id);


--
-- TOC entry 2982 (class 2606 OID 23054)
-- Name: category category_primary; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.category
    ADD CONSTRAINT category_primary PRIMARY KEY (id);


--
-- TOC entry 2984 (class 2606 OID 23056)
-- Name: colour colour_pkey; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.colour
    ADD CONSTRAINT colour_pkey PRIMARY KEY (colour);


--
-- TOC entry 2986 (class 2606 OID 23058)
-- Name: grouplabel grouplabel_pkey; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.grouplabel
    ADD CONSTRAINT grouplabel_pkey PRIMARY KEY (code);


--
-- TOC entry 2992 (class 2606 OID 23060)
-- Name: localstock id_pkey; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.localstock
    ADD CONSTRAINT id_pkey PRIMARY KEY (id);


--
-- TOC entry 2988 (class 2606 OID 23062)
-- Name: incoming_stock incoming_stock_pkey; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.incoming_stock
    ADD CONSTRAINT incoming_stock_pkey PRIMARY KEY (id);


--
-- TOC entry 2990 (class 2606 OID 23064)
-- Name: inivalues inivalues_pkey; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.inivalues
    ADD CONSTRAINT inivalues_pkey PRIMARY KEY (attribute);


--
-- TOC entry 2997 (class 2606 OID 23066)
-- Name: location location_pkey; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.location
    ADD CONSTRAINT location_pkey PRIMARY KEY (barcode);


--
-- TOC entry 2999 (class 2606 OID 23068)
-- Name: offlinesold offlinesold_pkey; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.offlinesold
    ADD CONSTRAINT offlinesold_pkey PRIMARY KEY (id);


--
-- TOC entry 3001 (class 2606 OID 23070)
-- Name: orderstatus orderstatus_pkey; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.orderstatus
    ADD CONSTRAINT orderstatus_pkey PRIMARY KEY (ordernum, shopifysku);


--
-- TOC entry 3046 (class 2606 OID 23991)
-- Name: pickpin pickpin_pkey; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.pickpin
    ADD CONSTRAINT pickpin_pkey PRIMARY KEY (pin);


--
-- TOC entry 3003 (class 2606 OID 23072)
-- Name: productlink productlink_pkey; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.productlink
    ADD CONSTRAINT productlink_pkey PRIMARY KEY (groupid);


--
-- TOC entry 3005 (class 2606 OID 23074)
-- Name: producttype producttype_pkey; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.producttype
    ADD CONSTRAINT producttype_pkey PRIMARY KEY (producttype);


--
-- TOC entry 3011 (class 2606 OID 23076)
-- Name: sales sales_pkey; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_pkey PRIMARY KEY (id);


--
-- TOC entry 3013 (class 2606 OID 23078)
-- Name: shopifyimages shopifyimages_primary; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.shopifyimages
    ADD CONSTRAINT shopifyimages_primary PRIMARY KEY (handle, imagepos);


--
-- TOC entry 3015 (class 2606 OID 23080)
-- Name: shopifysnapshot shopifysnapshot_primary; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.shopifysnapshot
    ADD CONSTRAINT shopifysnapshot_primary PRIMARY KEY (code);


--
-- TOC entry 3017 (class 2606 OID 23082)
-- Name: shopifysold shopifysold_pkey; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.shopifysold
    ADD CONSTRAINT shopifysold_pkey PRIMARY KEY (id);


--
-- TOC entry 3019 (class 2606 OID 23084)
-- Name: shopprices shopprices_pkey; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.shopprices
    ADD CONSTRAINT shopprices_pkey PRIMARY KEY (groupid);


--
-- TOC entry 3024 (class 2606 OID 23086)
-- Name: skumap skumap_pkey; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.skumap
    ADD CONSTRAINT skumap_pkey PRIMARY KEY (code);


--
-- TOC entry 3027 (class 2606 OID 23088)
-- Name: skusummary skusummary_pkey; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.skusummary
    ADD CONSTRAINT skusummary_pkey PRIMARY KEY (groupid);


--
-- TOC entry 3029 (class 2606 OID 23090)
-- Name: stockorder stockorder_pkey; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.stockorder
    ADD CONSTRAINT stockorder_pkey PRIMARY KEY (id);


--
-- TOC entry 3031 (class 2606 OID 23092)
-- Name: taglist taglist_pkey; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.taglist
    ADD CONSTRAINT taglist_pkey PRIMARY KEY (tag);


--
-- TOC entry 3033 (class 2606 OID 23094)
-- Name: title title_pkey; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.title
    ADD CONSTRAINT title_pkey PRIMARY KEY (groupid);


--
-- TOC entry 3035 (class 2606 OID 23096)
-- Name: ukdstock ukdstock_pkey; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.ukdstock
    ADD CONSTRAINT ukdstock_pkey PRIMARY KEY (code);


--
-- TOC entry 3040 (class 2606 OID 23098)
-- Name: winner_channels unique_groupid_channel; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.winner_channels
    ADD CONSTRAINT unique_groupid_channel UNIQUE (groupid, channel);


--
-- TOC entry 3038 (class 2606 OID 23100)
-- Name: weekly_stock_levels weekly_stock_levels_pkey; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.weekly_stock_levels
    ADD CONSTRAINT weekly_stock_levels_pkey PRIMARY KEY (id);


--
-- TOC entry 3042 (class 2606 OID 23102)
-- Name: winner_channels winner_channels_pkey; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.winner_channels
    ADD CONSTRAINT winner_channels_pkey PRIMARY KEY (id);


--
-- TOC entry 3044 (class 2606 OID 23104)
-- Name: winner_products winner_products_pkey; Type: CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.winner_products
    ADD CONSTRAINT winner_products_pkey PRIMARY KEY (groupid);


--
-- TOC entry 3036 (class 1259 OID 23105)
-- Name: idx_groupid_week; Type: INDEX; Schema: public; Owner: brookfield_dev_user
--

CREATE INDEX idx_groupid_week ON public.weekly_stock_levels USING btree (groupid, week_start_date);


--
-- TOC entry 2993 (class 1259 OID 23106)
-- Name: idx_localstock_code; Type: INDEX; Schema: public; Owner: brookfield_dev_user
--

CREATE INDEX idx_localstock_code ON public.localstock USING btree (code);


--
-- TOC entry 2994 (class 1259 OID 23107)
-- Name: idx_localstock_groupid; Type: INDEX; Schema: public; Owner: brookfield_dev_user
--

CREATE INDEX idx_localstock_groupid ON public.localstock USING btree (groupid);


--
-- TOC entry 2995 (class 1259 OID 23108)
-- Name: idx_localstock_location_code; Type: INDEX; Schema: public; Owner: brookfield_dev_user
--

CREATE INDEX idx_localstock_location_code ON public.localstock USING btree (location, code);


--
-- TOC entry 3006 (class 1259 OID 23109)
-- Name: idx_sales_code; Type: INDEX; Schema: public; Owner: brookfield_dev_user
--

CREATE INDEX idx_sales_code ON public.sales USING btree (code);


--
-- TOC entry 3007 (class 1259 OID 23110)
-- Name: idx_sales_groupid; Type: INDEX; Schema: public; Owner: brookfield_dev_user
--

CREATE INDEX idx_sales_groupid ON public.sales USING btree (groupid);


--
-- TOC entry 3008 (class 1259 OID 23111)
-- Name: idx_sales_ordernum; Type: INDEX; Schema: public; Owner: brookfield_dev_user
--

CREATE INDEX idx_sales_ordernum ON public.sales USING btree (ordernum);


--
-- TOC entry 3009 (class 1259 OID 23112)
-- Name: idx_sales_solddate; Type: INDEX; Schema: public; Owner: brookfield_dev_user
--

CREATE INDEX idx_sales_solddate ON public.sales USING btree (solddate);


--
-- TOC entry 3020 (class 1259 OID 23113)
-- Name: idx_skumap_code; Type: INDEX; Schema: public; Owner: brookfield_dev_user
--

CREATE INDEX idx_skumap_code ON public.skumap USING btree (code);


--
-- TOC entry 3021 (class 1259 OID 23114)
-- Name: idx_skumap_groupid; Type: INDEX; Schema: public; Owner: brookfield_dev_user
--

CREATE INDEX idx_skumap_groupid ON public.skumap USING btree (groupid);


--
-- TOC entry 3022 (class 1259 OID 23115)
-- Name: idx_skumap_groupid_code; Type: INDEX; Schema: public; Owner: brookfield_dev_user
--

CREATE INDEX idx_skumap_groupid_code ON public.skumap USING btree (groupid, code);


--
-- TOC entry 3025 (class 1259 OID 23116)
-- Name: idx_skusummary_groupid; Type: INDEX; Schema: public; Owner: brookfield_dev_user
--

CREATE INDEX idx_skusummary_groupid ON public.skusummary USING btree (groupid);


--
-- TOC entry 3047 (class 2606 OID 23117)
-- Name: winner_channels winner_channels_groupid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: brookfield_dev_user
--

ALTER TABLE ONLY public.winner_channels
    ADD CONSTRAINT winner_channels_groupid_fkey FOREIGN KEY (groupid) REFERENCES public.winner_products(groupid);


--
-- TOC entry 3174 (class 0 OID 0)
-- Dependencies: 6
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2025-06-05 11:49:49

--
-- PostgreSQL database dump complete
--

