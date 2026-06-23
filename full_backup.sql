--
-- PostgreSQL database dump
--

\restrict 3OksZROxbSLj7AVHa9bSw4ebIs9PeV8mcXSG7C33bDZm1m0wW4eP2PJuEOmOslh

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

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
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: access_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.access_type AS ENUM (
    'free',
    'pro',
    'ultra'
);


ALTER TYPE public.access_type OWNER TO postgres;

--
-- Name: crime_severity; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.crime_severity AS ENUM (
    'NONE',
    'LOW',
    'MODERATE',
    'EXTREME'
);


ALTER TYPE public.crime_severity OWNER TO postgres;

--
-- Name: emergency_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.emergency_type AS ENUM (
    'NONE',
    'PUBLIC_HEALTH',
    'NATURAL_DISASTER',
    'WAR_CONFLICT',
    'CIVIL_UNREST'
);


ALTER TYPE public.emergency_type OWNER TO postgres;

--
-- Name: impact_scope_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.impact_scope_type AS ENUM (
    'Local',
    'District',
    'State',
    'National',
    'International'
);


ALTER TYPE public.impact_scope_type OWNER TO postgres;

--
-- Name: news_category; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.news_category AS ENUM (
    'Economy',
    'Infrastructure',
    'Politics',
    'Crime',
    'Science',
    'Geopolitics',
    'Emergency'
);


ALTER TYPE public.news_category OWNER TO postgres;

--
-- Name: roles; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.roles AS ENUM (
    'user',
    'admin',
    'employe'
);


ALTER TYPE public.roles OWNER TO postgres;

--
-- Name: sentiment_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.sentiment_type AS ENUM (
    'Positive',
    'Neutral',
    'Negative'
);


ALTER TYPE public.sentiment_type OWNER TO postgres;

--
-- Name: create_monthly_partition(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_monthly_partition(start_date date) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    end_date DATE := (start_date + INTERVAL '1 month')::DATE;
    partition_name TEXT := 'news_all_' || to_char(start_date, 'YYYY_MM');
    sql TEXT;
BEGIN
    sql := format(
        'CREATE TABLE IF NOT EXISTS %I PARTITION OF news_all
         FOR VALUES FROM (%L) TO (%L);',
        partition_name,
        start_date,
        end_date
    );
    EXECUTE sql;
END;
$$;


ALTER FUNCTION public.create_monthly_partition(start_date date) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: api_keys; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.api_keys (
    user_id uuid,
    key_hash text NOT NULL,
    key_prefix text,
    revoked boolean DEFAULT false,
    expires_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now(),
    last_used_at timestamp without time zone,
    total_token_used integer DEFAULT 0 CONSTRAINT api_keys_token_used_not_null NOT NULL,
    id bigint CONSTRAINT api_keys_new_id_not_null NOT NULL,
    api_name character varying(64) DEFAULT 'bodh_api'::character varying,
    daily_token_used integer DEFAULT 0
);


ALTER TABLE public.api_keys OWNER TO postgres;

--
-- Name: api_keys_new_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.api_keys_new_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.api_keys_new_id_seq OWNER TO postgres;

--
-- Name: api_keys_new_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.api_keys_new_id_seq OWNED BY public.api_keys.id;


--
-- Name: channel_transcripts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.channel_transcripts (
    id integer NOT NULL,
    channel_id text NOT NULL,
    state_name text NOT NULL,
    channel_type text NOT NULL,
    transcript text NOT NULL,
    is_used boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.channel_transcripts OWNER TO postgres;

--
-- Name: channel_transcripts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.channel_transcripts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.channel_transcripts_id_seq OWNER TO postgres;

--
-- Name: channel_transcripts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.channel_transcripts_id_seq OWNED BY public.channel_transcripts.id;


--
-- Name: districts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.districts (
    id bigint NOT NULL,
    state_id bigint NOT NULL,
    name character varying(100) NOT NULL
);


ALTER TABLE public.districts OWNER TO postgres;

--
-- Name: districts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.districts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.districts_id_seq OWNER TO postgres;

--
-- Name: districts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.districts_id_seq OWNED BY public.districts.id;


--
-- Name: news_all; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all (
    id bigint NOT NULL,
    headline text NOT NULL,
    summary text,
    category public.news_category NOT NULL,
    impact_scope public.impact_scope_type NOT NULL,
    importance_score smallint DEFAULT 1 NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type NOT NULL,
    is_national boolean DEFAULT false NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb NOT NULL,
    broadcast_date date NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
)
PARTITION BY RANGE (broadcast_date);


ALTER TABLE public.news_all OWNER TO postgres;

--
-- Name: news_all_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.news_all_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.news_all_id_seq OWNER TO postgres;

--
-- Name: news_all_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.news_all_id_seq OWNED BY public.news_all.id;


--
-- Name: news_all_2026_04; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2026_04 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2026_04 OWNER TO postgres;

--
-- Name: news_all_2026_05; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2026_05 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2026_05 OWNER TO postgres;

--
-- Name: news_all_2026_06; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2026_06 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2026_06 OWNER TO postgres;

--
-- Name: news_all_2026_07; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2026_07 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2026_07 OWNER TO postgres;

--
-- Name: news_all_2026_08; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2026_08 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2026_08 OWNER TO postgres;

--
-- Name: news_all_2026_09; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2026_09 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2026_09 OWNER TO postgres;

--
-- Name: news_all_2026_10; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2026_10 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2026_10 OWNER TO postgres;

--
-- Name: news_all_2026_11; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2026_11 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2026_11 OWNER TO postgres;

--
-- Name: news_all_2026_12; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2026_12 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2026_12 OWNER TO postgres;

--
-- Name: news_all_2027_01; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2027_01 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2027_01 OWNER TO postgres;

--
-- Name: news_all_2027_02; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2027_02 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2027_02 OWNER TO postgres;

--
-- Name: news_all_2027_03; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2027_03 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2027_03 OWNER TO postgres;

--
-- Name: news_all_2027_04; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2027_04 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2027_04 OWNER TO postgres;

--
-- Name: news_all_2027_05; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2027_05 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2027_05 OWNER TO postgres;

--
-- Name: news_all_2027_06; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2027_06 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2027_06 OWNER TO postgres;

--
-- Name: news_all_2027_07; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2027_07 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2027_07 OWNER TO postgres;

--
-- Name: news_all_2027_08; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2027_08 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2027_08 OWNER TO postgres;

--
-- Name: news_all_2027_09; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2027_09 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2027_09 OWNER TO postgres;

--
-- Name: news_all_2027_10; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2027_10 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2027_10 OWNER TO postgres;

--
-- Name: news_all_2027_11; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2027_11 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2027_11 OWNER TO postgres;

--
-- Name: news_all_2027_12; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2027_12 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2027_12 OWNER TO postgres;

--
-- Name: news_all_2028_01; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2028_01 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2028_01 OWNER TO postgres;

--
-- Name: news_all_2028_02; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2028_02 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2028_02 OWNER TO postgres;

--
-- Name: news_all_2028_03; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2028_03 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2028_03 OWNER TO postgres;

--
-- Name: news_all_2028_04; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2028_04 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2028_04 OWNER TO postgres;

--
-- Name: news_all_2028_05; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2028_05 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2028_05 OWNER TO postgres;

--
-- Name: news_all_2028_06; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2028_06 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2028_06 OWNER TO postgres;

--
-- Name: news_all_2028_07; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2028_07 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2028_07 OWNER TO postgres;

--
-- Name: news_all_2028_08; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2028_08 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2028_08 OWNER TO postgres;

--
-- Name: news_all_2028_09; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2028_09 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2028_09 OWNER TO postgres;

--
-- Name: news_all_2028_10; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2028_10 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2028_10 OWNER TO postgres;

--
-- Name: news_all_2028_11; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2028_11 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2028_11 OWNER TO postgres;

--
-- Name: news_all_2028_12; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2028_12 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2028_12 OWNER TO postgres;

--
-- Name: news_all_2029_01; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2029_01 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2029_01 OWNER TO postgres;

--
-- Name: news_all_2029_02; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2029_02 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2029_02 OWNER TO postgres;

--
-- Name: news_all_2029_03; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2029_03 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2029_03 OWNER TO postgres;

--
-- Name: news_all_2029_04; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2029_04 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2029_04 OWNER TO postgres;

--
-- Name: news_all_2029_05; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2029_05 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2029_05 OWNER TO postgres;

--
-- Name: news_all_2029_06; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2029_06 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2029_06 OWNER TO postgres;

--
-- Name: news_all_2029_07; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2029_07 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2029_07 OWNER TO postgres;

--
-- Name: news_all_2029_08; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2029_08 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2029_08 OWNER TO postgres;

--
-- Name: news_all_2029_09; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2029_09 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2029_09 OWNER TO postgres;

--
-- Name: news_all_2029_10; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2029_10 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2029_10 OWNER TO postgres;

--
-- Name: news_all_2029_11; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2029_11 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2029_11 OWNER TO postgres;

--
-- Name: news_all_2029_12; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2029_12 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2029_12 OWNER TO postgres;

--
-- Name: news_all_2030_01; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2030_01 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2030_01 OWNER TO postgres;

--
-- Name: news_all_2030_02; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2030_02 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2030_02 OWNER TO postgres;

--
-- Name: news_all_2030_03; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2030_03 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2030_03 OWNER TO postgres;

--
-- Name: news_all_2030_04; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2030_04 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2030_04 OWNER TO postgres;

--
-- Name: news_all_2030_05; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2030_05 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2030_05 OWNER TO postgres;

--
-- Name: news_all_2030_06; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2030_06 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2030_06 OWNER TO postgres;

--
-- Name: news_all_2030_07; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2030_07 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2030_07 OWNER TO postgres;

--
-- Name: news_all_2030_08; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2030_08 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2030_08 OWNER TO postgres;

--
-- Name: news_all_2030_09; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2030_09 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2030_09 OWNER TO postgres;

--
-- Name: news_all_2030_10; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2030_10 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2030_10 OWNER TO postgres;

--
-- Name: news_all_2030_11; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2030_11 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2030_11 OWNER TO postgres;

--
-- Name: news_all_2030_12; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_all_2030_12 (
    id bigint DEFAULT nextval('public.news_all_id_seq'::regclass) CONSTRAINT news_all_id_not_null NOT NULL,
    headline text CONSTRAINT news_all_headline_not_null NOT NULL,
    summary text,
    category public.news_category CONSTRAINT news_all_category_not_null NOT NULL,
    impact_scope public.impact_scope_type CONSTRAINT news_all_impact_scope_not_null NOT NULL,
    importance_score smallint DEFAULT 1 CONSTRAINT news_all_importance_score_not_null NOT NULL,
    sentiment public.sentiment_type DEFAULT 'Neutral'::public.sentiment_type,
    crime_severity public.crime_severity DEFAULT 'NONE'::public.crime_severity CONSTRAINT news_all_crime_severity_not_null NOT NULL,
    emergency_type public.emergency_type DEFAULT 'NONE'::public.emergency_type CONSTRAINT news_all_emergency_type_not_null NOT NULL,
    is_national boolean DEFAULT false CONSTRAINT news_all_is_national_not_null NOT NULL,
    state_id bigint,
    district_id bigint,
    tags jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_tags_not_null NOT NULL,
    entities jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_entities_not_null NOT NULL,
    source_context jsonb DEFAULT '{}'::jsonb CONSTRAINT news_all_source_context_not_null NOT NULL,
    financial_type character varying(50),
    financial_amount numeric(18,2),
    financial_currency character varying(10),
    financial_denomination character varying(20),
    financial_status character varying(50),
    financial_industries jsonb DEFAULT '[]'::jsonb CONSTRAINT news_all_financial_industries_not_null NOT NULL,
    broadcast_date date CONSTRAINT news_all_broadcast_date_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() CONSTRAINT news_all_created_at_not_null NOT NULL,
    CONSTRAINT news_all_importance_score_check CHECK (((importance_score >= 1) AND (importance_score <= 10)))
);


ALTER TABLE public.news_all_2030_12 OWNER TO postgres;

--
-- Name: plans; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.plans (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    token_per_day integer CONSTRAINT plans_request_per_day_not_null NOT NULL,
    token_per_minute integer CONSTRAINT plans_request_per_minute_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    max_key integer DEFAULT 5 NOT NULL
);


ALTER TABLE public.plans OWNER TO postgres;

--
-- Name: plans_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.plans_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.plans_id_seq OWNER TO postgres;

--
-- Name: plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.plans_id_seq OWNED BY public.plans.id;


--
-- Name: refresh_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.refresh_tokens (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    token_hash text NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    ip text,
    user_agent text,
    jwt_id uuid,
    revoked_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.refresh_tokens OWNER TO postgres;

--
-- Name: state_transcripts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.state_transcripts (
    state_name text NOT NULL,
    news_transcript text,
    finance_transcript text,
    created_at timestamp without time zone DEFAULT now(),
    is_used boolean DEFAULT false,
    max_cnt smallint DEFAULT 0
);


ALTER TABLE public.state_transcripts OWNER TO postgres;

--
-- Name: states; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.states (
    id bigint NOT NULL,
    name character varying(100) NOT NULL
);


ALTER TABLE public.states OWNER TO postgres;

--
-- Name: states_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.states_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.states_id_seq OWNER TO postgres;

--
-- Name: states_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.states_id_seq OWNED BY public.states.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    google_id character varying(64) NOT NULL,
    email character varying(40) NOT NULL,
    name character varying(40),
    picture_url text,
    plan_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    user_role public.roles DEFAULT 'user'::public.roles NOT NULL
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: news_all_2026_04; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2026_04 FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');


--
-- Name: news_all_2026_05; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2026_05 FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');


--
-- Name: news_all_2026_06; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2026_06 FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');


--
-- Name: news_all_2026_07; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2026_07 FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');


--
-- Name: news_all_2026_08; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2026_08 FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');


--
-- Name: news_all_2026_09; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2026_09 FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');


--
-- Name: news_all_2026_10; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2026_10 FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');


--
-- Name: news_all_2026_11; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2026_11 FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');


--
-- Name: news_all_2026_12; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2026_12 FOR VALUES FROM ('2026-12-01') TO ('2027-01-01');


--
-- Name: news_all_2027_01; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2027_01 FOR VALUES FROM ('2027-01-01') TO ('2027-02-01');


--
-- Name: news_all_2027_02; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2027_02 FOR VALUES FROM ('2027-02-01') TO ('2027-03-01');


--
-- Name: news_all_2027_03; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2027_03 FOR VALUES FROM ('2027-03-01') TO ('2027-04-01');


--
-- Name: news_all_2027_04; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2027_04 FOR VALUES FROM ('2027-04-01') TO ('2027-05-01');


--
-- Name: news_all_2027_05; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2027_05 FOR VALUES FROM ('2027-05-01') TO ('2027-06-01');


--
-- Name: news_all_2027_06; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2027_06 FOR VALUES FROM ('2027-06-01') TO ('2027-07-01');


--
-- Name: news_all_2027_07; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2027_07 FOR VALUES FROM ('2027-07-01') TO ('2027-08-01');


--
-- Name: news_all_2027_08; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2027_08 FOR VALUES FROM ('2027-08-01') TO ('2027-09-01');


--
-- Name: news_all_2027_09; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2027_09 FOR VALUES FROM ('2027-09-01') TO ('2027-10-01');


--
-- Name: news_all_2027_10; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2027_10 FOR VALUES FROM ('2027-10-01') TO ('2027-11-01');


--
-- Name: news_all_2027_11; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2027_11 FOR VALUES FROM ('2027-11-01') TO ('2027-12-01');


--
-- Name: news_all_2027_12; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2027_12 FOR VALUES FROM ('2027-12-01') TO ('2028-01-01');


--
-- Name: news_all_2028_01; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2028_01 FOR VALUES FROM ('2028-01-01') TO ('2028-02-01');


--
-- Name: news_all_2028_02; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2028_02 FOR VALUES FROM ('2028-02-01') TO ('2028-03-01');


--
-- Name: news_all_2028_03; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2028_03 FOR VALUES FROM ('2028-03-01') TO ('2028-04-01');


--
-- Name: news_all_2028_04; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2028_04 FOR VALUES FROM ('2028-04-01') TO ('2028-05-01');


--
-- Name: news_all_2028_05; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2028_05 FOR VALUES FROM ('2028-05-01') TO ('2028-06-01');


--
-- Name: news_all_2028_06; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2028_06 FOR VALUES FROM ('2028-06-01') TO ('2028-07-01');


--
-- Name: news_all_2028_07; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2028_07 FOR VALUES FROM ('2028-07-01') TO ('2028-08-01');


--
-- Name: news_all_2028_08; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2028_08 FOR VALUES FROM ('2028-08-01') TO ('2028-09-01');


--
-- Name: news_all_2028_09; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2028_09 FOR VALUES FROM ('2028-09-01') TO ('2028-10-01');


--
-- Name: news_all_2028_10; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2028_10 FOR VALUES FROM ('2028-10-01') TO ('2028-11-01');


--
-- Name: news_all_2028_11; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2028_11 FOR VALUES FROM ('2028-11-01') TO ('2028-12-01');


--
-- Name: news_all_2028_12; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2028_12 FOR VALUES FROM ('2028-12-01') TO ('2029-01-01');


--
-- Name: news_all_2029_01; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2029_01 FOR VALUES FROM ('2029-01-01') TO ('2029-02-01');


--
-- Name: news_all_2029_02; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2029_02 FOR VALUES FROM ('2029-02-01') TO ('2029-03-01');


--
-- Name: news_all_2029_03; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2029_03 FOR VALUES FROM ('2029-03-01') TO ('2029-04-01');


--
-- Name: news_all_2029_04; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2029_04 FOR VALUES FROM ('2029-04-01') TO ('2029-05-01');


--
-- Name: news_all_2029_05; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2029_05 FOR VALUES FROM ('2029-05-01') TO ('2029-06-01');


--
-- Name: news_all_2029_06; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2029_06 FOR VALUES FROM ('2029-06-01') TO ('2029-07-01');


--
-- Name: news_all_2029_07; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2029_07 FOR VALUES FROM ('2029-07-01') TO ('2029-08-01');


--
-- Name: news_all_2029_08; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2029_08 FOR VALUES FROM ('2029-08-01') TO ('2029-09-01');


--
-- Name: news_all_2029_09; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2029_09 FOR VALUES FROM ('2029-09-01') TO ('2029-10-01');


--
-- Name: news_all_2029_10; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2029_10 FOR VALUES FROM ('2029-10-01') TO ('2029-11-01');


--
-- Name: news_all_2029_11; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2029_11 FOR VALUES FROM ('2029-11-01') TO ('2029-12-01');


--
-- Name: news_all_2029_12; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2029_12 FOR VALUES FROM ('2029-12-01') TO ('2030-01-01');


--
-- Name: news_all_2030_01; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2030_01 FOR VALUES FROM ('2030-01-01') TO ('2030-02-01');


--
-- Name: news_all_2030_02; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2030_02 FOR VALUES FROM ('2030-02-01') TO ('2030-03-01');


--
-- Name: news_all_2030_03; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2030_03 FOR VALUES FROM ('2030-03-01') TO ('2030-04-01');


--
-- Name: news_all_2030_04; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2030_04 FOR VALUES FROM ('2030-04-01') TO ('2030-05-01');


--
-- Name: news_all_2030_05; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2030_05 FOR VALUES FROM ('2030-05-01') TO ('2030-06-01');


--
-- Name: news_all_2030_06; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2030_06 FOR VALUES FROM ('2030-06-01') TO ('2030-07-01');


--
-- Name: news_all_2030_07; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2030_07 FOR VALUES FROM ('2030-07-01') TO ('2030-08-01');


--
-- Name: news_all_2030_08; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2030_08 FOR VALUES FROM ('2030-08-01') TO ('2030-09-01');


--
-- Name: news_all_2030_09; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2030_09 FOR VALUES FROM ('2030-09-01') TO ('2030-10-01');


--
-- Name: news_all_2030_10; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2030_10 FOR VALUES FROM ('2030-10-01') TO ('2030-11-01');


--
-- Name: news_all_2030_11; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2030_11 FOR VALUES FROM ('2030-11-01') TO ('2030-12-01');


--
-- Name: news_all_2030_12; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2030_12 FOR VALUES FROM ('2030-12-01') TO ('2031-01-01');


--
-- Name: api_keys id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_keys ALTER COLUMN id SET DEFAULT nextval('public.api_keys_new_id_seq'::regclass);


--
-- Name: channel_transcripts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.channel_transcripts ALTER COLUMN id SET DEFAULT nextval('public.channel_transcripts_id_seq'::regclass);


--
-- Name: districts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.districts ALTER COLUMN id SET DEFAULT nextval('public.districts_id_seq'::regclass);


--
-- Name: news_all id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all ALTER COLUMN id SET DEFAULT nextval('public.news_all_id_seq'::regclass);


--
-- Name: plans id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.plans ALTER COLUMN id SET DEFAULT nextval('public.plans_id_seq'::regclass);


--
-- Name: states id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.states ALTER COLUMN id SET DEFAULT nextval('public.states_id_seq'::regclass);


--
-- Data for Name: api_keys; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.api_keys (user_id, key_hash, key_prefix, revoked, expires_at, created_at, last_used_at, total_token_used, id, api_name, daily_token_used) FROM stdin;
2cfef765-be93-4f01-b96f-88f2b2b2ec39	33645d04b2002bb495625a4d0e23a77307f981dec4936028a8dbfb85dce24f54	bodh_live_b97627fcfe6a	f	2026-06-17 17:01:28.096	2026-06-17 16:31:28.09721	\N	0	65	okay	0
fa61f3e0-14ea-4ce1-bfd8-9701f5960dcd	cc7f0c556244638afc6bf0d68e7e570d337e4b4f5f4cf02b304b7336d77bb12b	bodh_live_6c05fe5ba6e9	f	2026-06-19 22:30:51.506	2026-06-19 22:00:51.508227	\N	0	68	rudresh	26
\.


--
-- Data for Name: channel_transcripts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.channel_transcripts (id, channel_id, state_name, channel_type, transcript, is_used, created_at) FROM stdin;
25	UCRWFSbif-RFENbBrSiez1DA	National	General	Transcript\nSearch transcript\n0:02\n2 seconds\nαñ¬αñ╢αÑìαñÜαñ┐αñ« αñ¼αñéαñùαñ╛αñ▓ αñ«αÑçαñé αñÿαÑüαñ╕αñ¬αÑêαñáαñ┐αñ»αÑïαñé αñ¬αñ░ αñ¼αñíαñ╝αñ╛ αñÅαñòαÑìαñ╢αñ¿αÑñ αñ«αÑüαñ░αÑìαñ╢αñ┐αñªαñ╛αñ¼αñ╛αñª αñöαñ░ αñ«αñ╛αñ▓αñªαñ╛ αñ╕αÑç αñ¬αñòαñíαñ╝αÑç αñùαñÅ αñ¼αñ╛αñéαñùαÑìαñ▓αñ╛αñªαÑçαñ╢αñ┐αñ»αÑïαñé αñòαÑï αñ╣αÑïαñ▓αÑìαñíαñ┐αñéαñù αñ╕αÑçαñéαñƒαñ░ αñ«αÑçαñé αñ░αñûαñ╛ αñùαñ»αñ╛αÑñ\n0:11\n11 seconds\nαñòαÑçαñéαñªαÑìαñ░ αñ╕αñ░αñòαñ╛αñ░ αñ¿αÑç αñíαÑçαñ«αÑïαñùαÑìαñ░αñ╛αñ½αñ┐αñò αñÜαÑçαñéαñ£ αñ¬αñ░ αñ╣αñ╛αñê αñ▓αÑçαñ╡αñ▓ αñòαñ«αÑçαñƒαÑÇ αñòαñ╛ αñòαñ┐αñ»αñ╛ αñùαñáαñ¿αÑñ αñùαÑâαñ╣ αñ«αñéαññαÑìαñ░αÑÇ αñàαñ«αñ┐αññ αñ╢αñ╛αñ╣ αñ¿αÑç αñªαÑÇ αñ£αñ╛αñ¿αñòαñ╛αñ░αÑÇαÑñ αñ£αñ¿αñ╕αñéαñûαÑìαñ»αñ╛ αñ¼αñªαñ▓αñ╛αñ╡ αñòαÑÇ αñ╕αñ«αÑÇαñòαÑìαñ╖αñ╛ αñòαñ░αÑçαñùαÑÇ αñòαñ«αÑçαñƒαÑÇαÑñ\n0:22\n22 seconds\nαñ░αñ╛αñ£αñ╕αÑìαñÑαñ╛αñ¿ αñòαÑç αñ¼αÑÇαñòαñ╛αñ¿αÑçαñ░ αñ«αÑçαñé αñùαÑâαñ╣ αñ«αñéαññαÑìαñ░αÑÇ αñàαñ«αñ┐αññ αñ╢αñ╛αñ╣ αñ¿αÑç αñ¼αÑÇαñÅαñ╕αñÅαñ½ αñòαÑç αñ£αñ╡αñ╛αñ¿αÑïαñé αñ╕αÑç αñòαÑÇ αñ«αÑüαñ▓αñ╛αñòαñ╛αññαÑñ\n0:26\n26 seconds\nαñàαñ«αñ┐αññ αñ╢αñ╛αñ╣ αñ¿αÑç αñæαñ¬αñ░αÑçαñ╢αñ¿ αñ╕αñ┐αñéαñªαÑéαñ░ αñòαÑï αñ▓αÑçαñòαñ░ αñ£αñ╡αñ╛αñ¿αÑïαñé αñòαÑÇ αñ¬αÑìαñ░αñ╢αñéαñ╕αñ╛ αñòαÑÇαÑñ αñòαñ╣αñ╛ αñ£αñ╡αñ╛αñ¿αÑïαñé αñ¿αÑç αñ¬αñ╛αñòαñ┐αñ╕αÑìαññαñ╛αñ¿ αñòαÑï αñªαñ┐αñ»αñ╛ αñ«αÑüαñéαñ╣αññαÑïαñíαñ╝ αñ£αñ╡αñ╛αñ¼αÑñ\n0:34\n34 seconds\nαñ£αñ«αÑìαñ«αÑé αñòαñ╢αÑìαñ«αÑÇαñ░ αñòαÑç αñ░αñ╛αñ£αÑîαñ░αÑÇ αñ«αÑçαñé αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñ¼αñ▓αÑïαñé αñòαñ╛ αñåαññαñéαñòαñ╡αñ╛αñª αñ╡αñ┐αñ░αÑïαñºαÑÇ αñàαñ¡αñ┐αñ»αñ╛αñ¿αÑñ αñ£αñéαñùαñ▓αÑÇ αñçαñ▓αñ╛αñòαÑïαñé αñ«αÑçαñé αñ░αÑüαñò-αñ░αÑüαñò αñòαñ░ αñ╣αÑï αñ░αñ╣αÑÇ αñ½αñ╛αñ»αñ░αñ┐αñéαñù αñòαÑç αñ¼αñ╛αñª αñÜαñ▓αñ╛αñ»αñ╛ αñ╕αñ░αÑìαñÜ αñæαñ¬αñ░αÑçαñ╢αñ¿αÑñ αñåαñ¿αÑç αñ£αñ╛αñ¿αÑç αñ╡αñ╛αñ▓αÑç αñ╡αñ╛αñ╣αñ¿αÑïαñé αñòαÑÇ αñ£αñ╛αñéαñÜαÑñ\n0:54\n54 seconds\nαñ╕αÑÇαñ¼αÑÇαñÅαñ╕αñê αñ╡αÑçαñ¼αñ╕αñ╛αñçαñƒ αñ«αÑçαñé αñªαñ┐αñòαÑìαñòαññ αñ¬αñ░ αñ╕αñ░αñòαñ╛αñ░ αñ╕αñûαÑìαññαÑñ αñ╢αñ┐αñòαÑìαñ╖αñ╛ αñ«αñéαññαÑìαñ░αÑÇ αñ¿αÑç αñÜαñ╛αñ░ αñ╕αñ░αñòαñ╛αñ░αÑÇ αñ¼αÑêαñéαñòαÑïαñé αñòαÑç αñàαñºαñ┐αñòαñ╛αñ░αñ┐αñ»αÑïαñé αñòαÑç αñ╕αñ╛αñÑ αñ¼αÑêαñáαñò αñòαÑÇαÑñ αñ¡αÑüαñùαññαñ╛αñ¿ αñ╕αñ┐αñ╕αÑìαñƒαñ« αñ«αÑçαñé αñ╕αÑüαñºαñ╛αñ░ αñ¬αñ░ αñÜαñ░αÑìαñÜαñ╛ αñòαÑÇ αñùαñêαÑñ\n1:06\n1 minute, 6 seconds\nαñªαñ┐αñ▓αÑìαñ▓αÑÇ αñ«αÑçαñé αñ¼αñòαñ░αÑÇ αñêαñª αñòαÑï αñ▓αÑçαñòαñ░ αñíαÑÇαñ╕αÑÇαñ¬αÑÇ αñ╕αÑçαñéαñƒαÑìαñ░αñ▓ αñòαÑç αñ¿αÑçαññαÑâαññαÑìαñ╡ αñ«αÑçαñé αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ¿αñ┐αñòαñ╛αñ▓αñ╛ αñ½αÑìαñ▓αÑêαñù αñ«αñ╛αñ░αÑìαñÜαÑñ αñ╕αñéαñ╡αÑçαñªαñ¿αñ╢αÑÇαñ▓ αñçαñ▓αñ╛αñòαÑïαñé αñòαÑÇ αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñòαñ╛ αñ▓αñ┐αñ»αñ╛ αñ£αñ╛αñ»αñ£αñ╛αÑñ\n1:15\n1 minute, 15 seconds\nαñ»αÑéαñ¬αÑÇ αñ«αÑçαñé αñ¼αñ┐αñ£αñ▓αÑÇ αñ╕αñ«αñ╕αÑìαñ»αñ╛αñôαñé αñòαÑï αñ▓αÑçαñòαñ░ αñ╕αÑÇαñÅαñ« αñ»αÑïαñùαÑÇ αñòαñ╛ αñàαñûαñ┐αñ▓αÑçαñ╢ αñ¬αñ░ αññαñéαñ£αÑñ αñòαñ╣αñ╛ αñ¼αñ┐αñ£αñ▓αÑÇ αñòαÑç αññαñ╛αñ░ αñ¬αñ░ αñòαñ¬αñíαñ╝αÑç αñ╕αÑüαñûαñ╛αñ¿αÑç αñ╡αñ╛αñ▓αÑç αñëαñáαñ╛ αñ░αñ╣αÑç αñèαñ░αÑìαñ£αñ╛ αñ╕αñéαñòαñƒ\n1:22\n1 minute, 22 seconds\nαñ¬αñ░ αñëαñéαñùαñ▓αÑÇαÑñ αñ╕αñ░αñòαñ╛αñ░ αñ£αñ▓αÑìαñª αñ¼αñ┐αñ£αñ▓αÑÇ αñ╕αñéαñòαñƒ αñ¬αñ░ αñ¿αñ┐αñòαñ╛αñ▓αÑçαñùαÑÇ αñ╕αñ«αñ╛αñºαñ╛αñ¿αÑñ\n1:27\n1 minute, 27 seconds\nαñ¡αÑïαñ¬αñ╛αñ▓ αñ«αÑçαñé αñƒαÑüαñ╢αñ╛ αñòαÑçαñ╕ αñ«αÑçαñé αñ╕αÑÇαñ¼αÑÇαñåαñê αñ¿αÑç αñ£αñ╛αñéαñÜ αñòαÑÇ αññαÑçαñ£αÑñ αñ¬αñ░αñ┐αñ£αñ¿αÑïαñé αñòαÑç αñ¼αñ»αñ╛αñ¿ αñòαñ░αñ╛αñÅ αñªαñ░αÑìαñ£αÑñ αñåαñ░αÑïαñ¬αÑÇ αñ╕αñ«αñ░αÑìαñÑ αñöαñ░ αñùαñ┐αñ░αñ┐αñ¼αñ╛αñ▓αñ╛ αñ╕αñ┐αñéαñ╣ αñ╕αÑç αñ¡αÑÇ αñ╣αÑïαñùαÑÇ αñ¬αÑéαñ¢αññαñ╛αñ¢αÑñ\n1:37\n1 minute, 37 seconds\nαñªαñ┐αñ▓αÑìαñ▓αÑÇ αñ«αÑçαñé αñòαÑìαñ╡αñ╛αñí αñ╡αñ┐αñªαÑçαñ╢ αñ«αñéαññαÑìαñ░αñ┐αñ»αÑïαñé αñòαÑÇ αñ¼αÑêαñáαñòαÑñ αñ¬αñ╢αÑìαñÜαñ┐αñ« αñÅαñ╢αñ┐αñ»αñ╛ αñ╕αñéαñòαñƒ, αñ╣αñ┐αñéαñª αñ¬αÑìαñ░αñ╢αñ╛αñéαññ αñòαÑìαñ╖αÑçαññαÑìαñ░ αñöαñ░ αñåαññαñéαñòαñ╡αñ╛αñª αñòαÑç αñ«αÑüαñªαÑìαñªαÑç αñ¬αñ░ αñÜαñ░αÑìαñÜαñ╛ αñòαÑÇ αñùαñêαÑñ αñ╕αñ¡αÑÇ αñòαÑìαñ╡αñ╛αñí αñªαÑçαñ╢ αñåαññαñéαñòαñ╡αñ╛αñª αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñÅαñòαñ£αÑüαñƒαÑñ\n1:48\n1 minute, 48 seconds\nαñ¬αñéαñ£αñ╛αñ¼ αñòαÑç αñ¬αñƒαñ┐αñ»αñ╛αñ▓αñ╛ αñòαÑÇ αñ╕αñ«αñ╛αñ¿αñ╛ αñ«αÑìαñ»αÑüαñ¿αñ┐αñ╕αñ┐αñ¬αñ▓ αñòαñ╛αñëαñéαñ╕αñ┐αñ▓ αñ«αÑçαñé αñ«αññαñªαñ╛αñ¿ αñòαÑç αñªαÑîαñ░αñ╛αñ¿ αñ£αñ«αñòαñ░ αñ¼αñ╡αñ╛αñ▓αÑñ\n1:52\n1 minute, 52 seconds\nαñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ▓αÑïαñùαÑïαñé αñòαÑï αñòαñ╛αñ¼αÑé αñòαñ░αñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ αñòαñ┐αñ»αñ╛ αñ▓αñ╛αñáαÑÇ αñÜαñ╛αñ░αÑìαñ£αÑñ\n1:57\n1 minute, 57 seconds\nαñ▓αÑüαñºαñ┐αñ»αñ╛αñ¿αñ╛ αñòαÑç αñ░αñ╛αñ»αñòαÑïαñƒ αñ«αÑçαñé αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñëαñ«αÑìαñ«αÑÇαñªαñ╡αñ╛αñ░ αñ£αñùαñªαÑçαñ╡ αñ╕αñ┐αñéαñ╣ αñ¬αñ░ αñ╣αñ«αñ▓αñ╛αÑñ αñ╣αñ«αñ▓αÑç αñ«αÑçαñé αñ£αñùαñªαÑçαñ╡ αñùαñéαñ¡αÑÇαñ░ αñ░αÑéαñ¬ αñ╕αÑç αñÿαñ╛αñ»αñ▓αÑñ αñàαñ╕αÑìαñ¬αññαñ╛αñ▓ αñ«αÑçαñé αñçαñ▓αñ╛αñ£ αñ£αñ╛αñ░αÑÇαÑñ\n2:06\n2 minutes, 6 seconds\nαñ»αÑéαñ¬αÑÇ αñòαÑç αñùαñ╛αñ£αñ┐αñ»αñ╛αñ¼αñ╛αñª αñ«αÑçαñé αñ╣αñ╛αñê αñ░αñ╛αñçαñ£ αñ¼αñ┐αñ▓αÑìαñíαñ┐αñéαñù αñòαÑç αñƒαÑëαñ¬ αñ½αÑìαñ▓αÑïαñ░ αñ¬αñ░ αñ▓αñùαÑÇ αñåαñùαÑñ αñ╕αÑïαñ╕αñ╛αñçαñƒαÑÇ αñ«αÑçαñé αñàαñ½αñ░αñ╛αññαñ½αñ░αÑÇ αñòαñ╛ αñ«αñ╛αñ╣αÑîαñ▓αÑñ αñ½αñ╛αñ»αñ░ αñ¼αÑìαñ░αñ┐αñùαÑçαñí αñ¿αÑç αñ¼αñ« αñ«αÑüαñ╢αÑìαñòαñ┐αñ▓ αñåαñù αñ¬αñ░ αñòαñ╛αñ¼αÑé αñ¬αñ╛αñ»αñ╛αÑñ\n2:16\n2 minutes, 16 seconds\nαññαÑçαñ▓αñéαñùαñ╛αñ¿αñ╛ αñòαÑç αñ░αÑçαñíαÑìαñíαÑÇ αñ«αÑçαñé αñÅαñ»αñ░ αñçαñéαñíαñ┐αñ»αñ╛ αñòαÑÇ αñ¼αñ╕ αñ«αÑçαñé αñ▓αñùαÑÇ αñåαñùαÑñ αñ¼αñ╕ αñ╕αÑç αñ╕αñ¡αÑÇ αñ╕αÑüαñ░αñòαÑìαñ╖αñ┐αññ αñ¿αñ┐αñòαñ╛αñ▓αÑç αñùαñÅαÑñ αñ¼αñ╕ αñ«αÑçαñé αñåαñù αñ▓αñùαñ¿αÑç αñòαÑÇ αñ╡αñ£αñ╣ αñ╢αÑëαñ░αÑìαñƒ αñ╕αñ░αÑìαñòαñ┐αñƒ αñ¼αññαñ╛αñê αñ£αñ╛ αñ░αñ╣αÑÇ αñ╣αÑêαÑñ\n2:26\n2 minutes, 26 seconds\nαñ«αñºαÑìαñ» αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñ¬αñ¿αÑìαñ¿αñ╛ αñ«αÑçαñé αñ¿αñ┐αñ░αÑìαñ«αñ╛αñúαñ╛αñºαÑÇαñ¿ αñòαÑüαñÅαñé αñ«αÑçαñé αñ«αñ┐αñƒαÑìαñƒαÑÇ αñºαñ╕αñ¿αÑç αñ╕αÑç αñªαñ░αÑìαñªαñ¿αñ╛αñò αñ╣αñ╛αñªαñ╕αñ╛αÑñ αñ«αñ┐αñƒαÑìαñƒαÑÇ αñ«αÑçαñé αñªαñ¼αñòαñ░ αñ¬αñ╛αñéαñÜ αñ«αñ£αñªαÑéαñ░αÑïαñé αñòαÑÇ αñ«αÑîαññαÑñ\n2:32\n2 minutes, 32 seconds\nαñ╣αñ╛αñªαñ╕αÑç αñ╕αÑç αñùαñ╛αñéαñ╡ αñ«αÑçαñé αñ¬αñ╕αñ░αñ╛ αñ«αñ╛αññαñ«αÑñ\n2:37\n2 minutes, 37 seconds\nαñ«αñ╣αñ╛αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░ αñòαÑç αñ¿αñ╛αñ╕αñ┐αñò αñ«αÑçαñé αñ¬αÑìαñ»αñ╛αñ£ αñëαññαÑìαñ¬αñ╛αñªαñò αñòαñ┐αñ╕αñ╛αñ¿αÑïαñé αñòαñ╛ αñ¬αÑìαñ░αñªαñ░αÑìαñ╢αñ¿αÑñ αñ¬αÑìαñ»αñ╛αñ£ αñòαÑÇ αñòαÑÇαñ«αññαÑïαñé αñ«αÑçαñé αñ¡αñ╛αñ░αÑÇ αñùαñ┐αñ░αñ╛αñ╡αñƒ αñ╕αÑç αñòαñ┐αñ╕αñ╛αñ¿αÑïαñé αñòαÑç αñ╕αñ╛αñ«αñ¿αÑç αñùαñ╣αñ░αñ╛αñ»αñ╛ αñåαñ░αÑìαñÑαñ┐αñò αñ╕αñéαñòαñƒαÑñ αñ╣αñ╛αñêαñ╡αÑç αñ£αñ╛αñ« αñòαñ░ αñ¬αÑìαñ»αñ╛αñ£ αñòαÑç αñªαñ╛αñ«αÑïαñé αñòαÑï αñ¼αñóαñ╝αñ╛αñ¿αÑç αñòαÑÇ αñ«αñ╛αñéαñù αñòαÑÇ αñùαñêαÑñ\n2:50\n2 minutes, 50 seconds\nαñåαñ£ αñòαÑçαñéαñªαÑìαñ░αÑÇαñ» αñ«αñéαññαÑìαñ░αÑÇ αñ╢αñ┐αñ╡αñ░αñ╛αñ£ αñ╕αñ┐αñéαñ╣ αñÜαÑîαñ╣αñ╛αñ¿ αñòαÑÇ αñûαñ┐αññαñ╛αñ¼ αñàαñ¬αñ¿αñ╛αñ¬αñ¿ αñòαñ╛ αñªαñ┐αñ▓αÑìαñ▓αÑÇ αñ«αÑçαñé αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛ αñ╡αñ┐αñ«αÑïαñÜαñ¿αÑñ αñ¬αÑÇαñÅαñ« αñ«αÑïαñªαÑÇ αñòαÑç αñ╕αñ╛αñÑ αñàαñ¬αñ¿αÑç 35 αñ╕αñ╛αñ▓αÑïαñé\n2:57\n2 minutes, 57 seconds\nαñòαÑç αñàαñ¿αÑüαñ¡αñ╡ αñòαÑï αñòαñ┐αñ»αñ╛αÑñ αñ╢αñ┐αñ╡αñ░αñ╛αñ£ αñ╕αñ┐αñéαñ╣ αñÜαÑîαñ╣αñ╛αñ¿ αñ¿αÑç αñ╕αñ╛αñ¥αñ╛ αñòαñ╣αñ╛ αñ«αÑêαñéαñ¿αÑç αñ«αñ╣αñ╕αÑéαñ╕ αñòαñ┐αñ»αñ╛ αñëαñ¿αñòαñ╛ αñòαñ░αÑìαñ« αñ»αÑïαñùαÑÇ αñ╕αÑìαñ╡αñ¡αñ╛αñ╡αÑñ\n3:11\n3 minutes, 11 seconds\nαñÅαñ¼αÑÇαñ¬αÑÇ αñ¿αÑìαñ»αÑéαñ£αñ╝ αñåαñ¬αñòαÑï αñ░αñûαÑç αñåαñùαÑçαÑñ	f	2026-05-27 03:09:12.668701
26	UCRWFSbif-RFENbBrSiez1DA	National	General	Transcript\nSearch transcript\n0:02\n2 seconds\nαñ¬αñ╢αÑìαñÜαñ┐αñ« αñ¼αñéαñùαñ╛αñ▓ αñòαÑç αñ╣αÑüαñùαñ▓αÑÇ αñ«αÑçαñé αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ╕αñ╛αñéαñ╕αñª αñòαñ▓αÑìαñ»αñ╛αñú αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñ¬αñ░ αñ╣αñ«αñ▓αñ╛αÑñ αñòαñ▓αÑìαñ»αñ╛αñú αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñòαÑï αñªαÑçαñûαñòαñ░ αñÜαÑïαñ░αñÜαÑïαñ░ αñòαÑç αñ¿αñ╛αñ░αÑç αñ▓αñùαñ╛αñÅ αñùαñÅαÑñ\n0:07\n7 seconds\nαñòαñ╛αñ░αÑìαñ»αñòαñ░αÑìαññαñ╛αñôαñé αñòαÑï αñ¢αÑüαñíαñ╝αñ╛αñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ αñ¬αñ╣αÑüαñéαñÜαÑç αñÑαÑç αñòαñ▓αÑìαñ»αñ╛αñú αñ¼αñ¿αñ░αÑìαñ£αÑÇαÑñ\n0:14\n14 seconds\nαñ¬αñ╢αÑìαñÜαñ┐αñ« αñ¼αñéαñùαñ╛αñ▓ αñòαÑç αñ╕αÑïαñ▓αñ╛αñ░αñ╛αñ¿αñ¬αÑüαñ░ αñ«αÑçαñé αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ╕αñ╛αñéαñ╕αñª αñàαñ¡αñ┐αñ╖αÑçαñò αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñ¬αñ░ αñ╣αñ«αñ▓αñ╛ αñ╣αÑüαñåαÑñ αñÜαÑüαñ¿αñ╛αñ╡ αñòαÑç αñ¼αñ╛αñª αñ╣αÑüαñê αñ╣αñ┐αñéαñ╕αñ╛ αñòαÑÇ αñ¬αÑÇαñíαñ╝αñ┐αññαÑïαñé αñ╕αÑç αñ«αñ┐αñ▓αñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ αñ¬αñ╣αÑüαñéαñÜαÑç αñ╣αÑüαñÅ αñÑαÑç αñàαñ¡αñ┐αñ╖αÑçαñòαÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ¬αñ╛αñéαñÜ αñåαñ░αÑïαñ¬αñ┐αñ»αÑïαñé αñòαÑï αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛ αñ╣αÑêαÑñ\n0:27\n27 seconds\nαñàαñ¡αñ┐αñ╖αÑçαñò αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñ¿αÑç αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñ¬αñ░ αñ▓αñùαñ╛αñ»αñ╛ αñ╣αñ«αñ▓αñ╛ αñòαñ░αñ╛αñ¿αÑç αñòαñ╛ αñåαñ░αÑïαñ¬αÑñ αñòαñ╣αñ╛ αñ«αÑêαñé αñ«αÑêαñªαñ╛αñ¿ αñ¢αÑïαñíαñ╝αñòαñ░ αñ¿αñ╣αÑÇαñé αñ¡αñ╛αñùαÑéαñéαñùαñ╛ αñÿαñƒαñ¿αñ╛ αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñ£αñ╛αñèαñéαñùαñ╛ αñòαÑïαñ░αÑìαñƒαÑñ\n0:38\n38 seconds\nαñ¡αññαÑÇαñ£αÑç αñàαñ¡αñ┐αñ╖αÑçαñò αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñ¬αñ░ αñ╣αÑüαñÅ αñ╣αñ«αñ▓αÑç αñòαÑï αñ▓αÑçαñòαñ░αÑñ\n0:40\n40 seconds\nαñ«αñ«αññαñ╛ αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñòαñ╛ αñ¼αñ»αñ╛αñ¿αÑñ αñòαñ╣αñ╛ αñ╢αñ╛αñ╕αñò αñ¼αñ¿ αñùαñÅ αñ╣αÑêαñé αñ╣αññαÑìαñ»αñ╛αñ░αÑçαÑñ αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñ¬αÑüαñ▓αñ┐αñ╕ αñàαñùαñ░ αñàαñ¡αñ┐αñ╖αÑçαñò αñòαÑï αñ╣αÑçαñ▓αñ«αÑçαñƒ αñ¿αñ╣αÑÇαñé αñªαÑçαññαÑÇ αññαÑï αñ╣αññαÑìαñ»αñ╛ αñ╣αÑï αñ£αñ╛αññαÑÇαÑñ\n0:51\n51 seconds\nαñªαñ┐αñ▓αÑìαñ▓αÑÇ αñòαÑç αñ╕αñ╛αñòαÑçαññ αñ«αÑçαñé αñùαñ┐αñ░αÑÇ αñ¬αñ╛αñéαñÜ αñ«αñéαñ£αñ┐αñ▓αñ╛ αñçαñ«αñ╛αñ░αññαÑñ αñ╣αñ╛αñªαñ╕αÑç αñ«αÑçαñé αñªαÑï αñ▓αÑïαñùαÑïαñé αñòαÑÇ αñ«αÑîαññαÑñ αñòαñ░αÑÇαñ¼ 10 αñ▓αÑïαñùαÑïαñé αñòαÑï αñ╕αÑüαñ░αñòαÑìαñ╖αñ┐αññ αñ¿αñ┐αñòαñ╛αñ▓αñ╛ αñùαñ»αñ╛αÑñ αñ░αñ╛αñ╣αññ αñöαñ░ αñ¼αñÜαñ╛αñ╡ αñòαñ╛ αñòαñ╛αñ« αñ£αñ╛αñ░αÑÇαÑñ\n1:02\n1 minute, 2 seconds\nαñªαñ┐αñ▓αÑìαñ▓αÑÇ αñòαÑç αñ¼αñ╣αñ░αÑîαñ▓αÑÇ αñ«αÑçαñé αñ¼αñ┐αñ▓αÑìαñíαñ┐αñéαñù αñùαñ┐αñ░αñ¿αÑç αñ╡αñ╛αñ▓αÑÇ αñ£αñùαñ╣ αñòαñ╛ αñ╕αÑÇαñÅαñ« αñ░αÑçαñûαñ╛ αñùαÑüαñ¬αÑìαññαñ╛ αñ¿αÑç αñªαÑîαñ░αñ╛ αñòαñ┐αñ»αñ╛αÑñ\n1:06\n1 minute, 6 seconds\nαñòαñ╣αñ╛ αñ╕αñ¡αÑÇ αñ¼αñ┐αñ¿αñ╛ αñçαñ£αñ╛αñ£αññ αñ╡αñ╛αñ▓αÑÇ αñ¼αñ┐αñ▓αÑìαñíαñ┐αñéαñù αñöαñ░ αñ£αñ┐αñ«αÑìαñ«αÑçαñªαñ╛αñ░ αñàαñºαñ┐αñòαñ╛αñ░αñ┐αñ»αÑïαñé αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñ▓αñ┐αñ»αñ╛ αñ£αñ╛αñÅαñùαñ╛ αñÅαñòαÑìαñ╢αñ¿αÑñ\n1:15\n1 minute, 15 seconds\nαñ╕αÑéαñ░αÑìαñ» αñ╣αññαÑìαñ»αñ╛αñòαñ╛αñéαñí αñòαñ╛ αñ«αÑüαñûαÑìαñ» αñåαñ░αÑïαñ¬αÑÇ αñàαñ╕αñª αñùαñ╛αñ£αñ┐αñ»αñ╛αñ¼αñ╛αñª αñ«αÑçαñé αñÅαñ¿αñòαñ╛αñëαñéαñƒαñ░ αñ«αÑçαñé αñóαÑçαñ░ αñ╣αÑüαñåαÑñ\n1:18\n1 minute, 18 seconds\nαñ¬αÑüαñ▓αñ┐αñ╕ αñòαñ╛αñéαñ╕αÑìαñƒαÑçαñ¼αñ▓ αñÿαñ╛αñ»αñ▓ αñ╣αÑüαñå αñ╣αÑêαÑñ αñªαÑïαñ¿αÑïαñé αñôαñ░ αñ╕αÑç αñÜαñ▓αÑÇ αñòαñ░αÑÇαñ¼ 10 αñ░αñ╛αñëαñéαñí αñùαÑïαñ▓αñ┐αñ»αñ╛αñéαÑñ\n1:25\n1 minute, 25 seconds\nαñåαñ░αÑïαñ¬αÑÇ αñàαñ╕αñª αñòαÑç αñÅαñ¿αñòαñ╛αñëαñéαñƒαñ░ αñòαÑç αñ¼αñ╛αñª αñ¼αÑïαñ▓αÑÇ αñ╕αÑéαñ░ αñòαÑÇ αñ«αñ╛αñéαñùαÑñ αñòαñ╣αñ╛ αñ¬αÑüαñ▓αñ┐αñ╕ αñòαÑÇ αñòαñ╛αñ░αÑìαñ»αñ╡αñ╛αñ╣αÑÇ αñ╕αÑç αñ╕αñéαññαÑüαñ╖αÑìαñƒαÑñ\n1:30\n1 minute, 30 seconds\nαñ╕αñ¡αÑÇ αñ╕αñ╛αññαÑïαñé αñåαñ░αÑïαñ¬αñ┐αñ»αÑïαñé αñòαÑç αñÅαñ¿αñòαñ╛αñëαñéαñƒαñ░ αñöαñ░ αñÿαñ░αÑïαñé αñ¬αñ░ αñÜαñ▓αÑç αñ¼αÑüαñ▓αñíαÑïαñ£αñ░αÑñ\n1:36\n1 minute, 36 seconds\nαñªαñ┐αñ▓αÑìαñ▓αÑÇ αñòαÑç αñ╢αñ╛αñ▓αÑÇαñ«αñ╛αñ░ αñ¼αñ╛αñù αñ«αÑçαñé αñ¼αÑüαñ▓αñíαÑïαñ£αñ░ αñÅαñòαÑìαñ╢αñ¿ αñ╣αÑüαñåαÑñ αñ╣αñ╛αñê αñòαÑïαñ░αÑìαñƒ αñòαÑç αñåαñªαÑçαñ╢ αñòαÑç αñ¼αñ╛αñª αñºαÑìαñ╡αñ╕αÑìαññ αñòαñ┐αñÅ αñ£αñ╛ αñ░αñ╣αÑç αñ╣αÑêαñé αñÿαñ░αÑñ 157 αñÿαñ░αÑïαñé αñòαÑï αñ¼αÑüαñ▓αñíαÑïαñ£αñ░ αñ╕αÑç αññαÑïαñíαñ╝αñ╛ αñ£αñ╛ αñ░αñ╣αñ╛ αñ╣αÑêαÑñ αñ¬αÑéαñ░αñ╛ αñçαñ▓αñ╛αñòαñ╛ αñ¢αñ╛αñ╡αñ¿αÑÇ αñ«αÑçαñé αññαñ¼αÑìαñªαÑÇαñ▓ αñ╣αÑüαñåαÑñ\n1:48\n1 minute, 48 seconds\nαñ£αñ«αÑìαñ«αÑé αñòαñ╢αÑìαñ«αÑÇαñ░ αñòαÑç αñ░αñ╛αñ£αÑïαñ░αÑÇ αñ«αÑçαñé αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñ¼αñ▓αÑïαñé αñòαÑç αñÿαñ¿αÑç αñ£αñéαñùαñ▓αÑïαñé αñ«αÑçαñé αñæαñ¬αñ░αÑçαñ╢αñ¿ αñ▓αñùαñ╛αññαñ╛αñ░ αñ£αñ╛αñ░αÑÇ αñ╣αÑêαÑñ\n1:53\n1 minute, 53 seconds\nαñåαññαñéαñòαñ┐αñ»αÑïαñé αñòαÑç αññαñ▓αñ╛αñ╢ αñ«αÑçαñé αñ£αÑüαñƒαÑç αñ╣αÑüαñÅ αñ╣αÑêαñé αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñ¼αñ▓αÑñ\n1:58\n1 minute, 58 seconds\nαñ«αñ╣αñ╛αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░ αñòαÑç αñ¢αññαÑìαñ░αñ¬αññαñ┐ αñ╕αñéαñ¡αñ╛αñ£αÑÇ αñ¿αñùαñ░ αñ«αÑçαñé αñÅαñ¿αñåαñêαñÅ αñòαÑÇ αñòαñ╛αñ░αÑìαñ»αñ╡αñ╛αñ╣αÑÇαÑñ αñåαññαñéαñòαÑÇ αñ╕αñéαñùαñáαñ¿ αñ╕αÑç αñ£αÑüαñíαñ╝αÑç αñ╣αÑïαñ¿αÑç αñòαÑç αñ╢αñò αñ«αÑçαñé αñÅαñò αñ╡αÑìαñ»αñòαÑìαññαñ┐ αñòαÑï αñ╣αñ┐αñ░αñ╛αñ╕αññ αñ«αÑçαñé αñ▓αñ┐αñ»αñ╛ αñùαñ»αñ╛ αñ╣αÑêαÑñ αñ╕αñ░αÑìαñÜ αñæαñ¬αñ░αÑçαñ╢αñ¿ αñÜαñ▓αñ╛αñòαñ░ αñòαñê αñ▓αÑïαñùαÑïαñé αñ╕αÑç αñ¬αÑéαñ¢αññαñ╛αñ¢αÑñ\n2:12\n2 minutes, 12 seconds\nαñ«αñ╣αñ╛αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░ αñòαÑç αñ╡αñ╕αñê αñ«αÑçαñé αñåαñ¼αñòαñ╛αñ░αÑÇ αñ╡αñ┐αñ¡αñ╛αñù αñöαñ░ αñ¬αÑüαñ▓αñ┐αñ╕ αñƒαÑÇαñ« αñ«αÑçαñé αñàαñ╡αÑêαñº αñ½αÑêαñòαÑìαñƒαÑìαñ░αÑÇ αñ«αÑçαñé αñ«αñ╛αñ░αñ╛ αñ¢αñ╛αñ¬αñ╛αÑñ 1 αñ▓αñ╛αñû αñ╕αÑç αñ£αÑìαñ»αñ╛αñªαñ╛ αñòαñ╛ αñ«αñ╛αñ▓ αñ£αñ¼αÑìαññ αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛αÑñ αñ╢αñ░αñ╛αñ¼ αñ¼αñ¿αñ╛αñ¿αÑç αñòαñ╛ αñ╕αñ╛αñ«αñ╛αñ¿ αñ¡αÑÇ αñ»αñ╣αñ╛αñé αñ╕αÑç αñ£αñ¼αÑìαññ αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛αÑñ\n2:25\n2 minutes, 25 seconds\nαñ«αñ╣αñ╛αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░ αñòαÑç αñ¬αÑüαñúαÑç αñ«αÑçαñé αÑ¢αñ╣αñ░αÑÇ αñ╢αñ░αñ╛αñ¼ αñòαñ╛αñéαñí αñ«αÑçαñé αñ«αÑîαññ αñòαñ╛ αñåαñéαñòαñíαñ╝αñ╛ 23 αñ¬αñ╣αÑüαñéαñÜαñ╛αÑñ αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñàαñ¼ αññαñò 52 αñ▓αÑïαñùαÑïαñé αñòαÑÇ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░αÑÇ αñ╣αÑüαñê αñ╣αÑêαÑñ\n2:30\n2 minutes, 30 seconds\nαñ¬αÑìαñ░αñ╢αñ╛αñ╕αñ¿ αñ¿αÑç αñ▓αñùαñ╛αññαñ╛αñ░ αñàαñ╡αÑêαñº αñ╢αñ░αñ╛αñ¼ αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñ¢αñ╛αñ¬αÑçαñ«αñ╛αñ░αÑÇ αñÜαñ▓αñ╛αñê αñ╣αÑêαÑñ\n2:38\n2 minutes, 38 seconds\nαñ«αñ╣αñ╛αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░ αñòαÑç αñ£αñ╛αñ▓αñ¿αñ╛ αñ«αÑçαñé αñºαñ░αñ¿αÑç αñ¬αñ░ αñ¼αÑêαñáαÑç αñ«αñ¿αÑïαñ£ αñ░αñ╛αñéαñùαÑç αñ¿αÑç αñ¬αñ╛αñ¿αÑÇ αñ¬αÑÇαñòαñ░ αññαÑïαñíαñ╝αñ╛ αñàαñ¿αñ╢αñ¿αÑñ\n2:41\n2 minutes, 41 seconds\nαñ«αñ░αñ╛αñáαñ╛ αñåαñ░αñòαÑìαñ╖αñú αñòαÑï αñ▓αÑçαñòαñ░ αñ░αñ╛αñ£αÑìαñ» αñ╕αñ░αñòαñ╛αñ░ αñöαñ░ αñ«αñ¿αÑïαñ£ αñ░αñ╛αñéαñùαÑç αñ«αÑçαñé αñòαñê αñ«αÑüαñªαÑìαñªαÑïαñé αñ¬αñ░ αñ╕αñ╣αñ«αññαñ┐ αñ¼αñ¿αÑÇαÑñ\n2:50\n2 minutes, 50 seconds\nαñ£αñ¿αñ░αñ▓ αñÅαñ¿ αñÅαñ╕ αñ░αñ╛αñ£αñ╛ αñ╕αÑüαñ¼αÑìαñ░αñ«αñúαñ┐ αñ¿αÑç αñ¡αñ╛αñ░αññ αñòαÑç αñ¿αñÅ αñÜαÑÇαñ½ αñæαñ½ αñíαñ┐αñ½αÑçαñéαñ╕ αñ╕αÑìαñƒαñ╛αñ½ αñòαÑç αñ░αÑéαñ¬ αñ«αÑçαñé αñòαñ╛αñ░αÑìαñ»αñ¡αñ╛αñ░ αñ╕αñéαñ¡αñ╛αñ▓αñ╛αÑñ αñ¿αñÅ αñ╕αÑÇαñíαÑÇαñÅαñ╕ αñ£αñ¿αñ░αñ▓ αñ╕αÑüαñ¼αÑìαñ░αñ«αñú αñùαñ╛αñ░αÑìαñí αñæαÑ₧ αñæαñ¿αñ░ αñëαñ¿αñòαÑï αñªαñ┐αñ»αñ╛ αñùαñ»αñ╛αÑñ\n3:02\n3 minutes, 2 seconds\nαñ¬αÑìαñ░αñºαñ╛αñ¿αñ«αñéαññαÑìαñ░αÑÇ αñ¿αñ░αÑçαñéαñªαÑìαñ░ αñ«αÑïαñªαÑÇ αñ¿αÑç αñ«αñ¿ αñòαÑÇ αñ¼αñ╛αññ αñòαñ╛αñ░αÑìαñ»αñòαÑìαñ░αñ« αñ«αÑçαñé αñ░αñ╛αñ£αÑìαñ» αñ«αÑçαñé αñ¿αÑçαñ╢αñ¿αñ▓ αñ╕αÑÇαñ¿αñ┐αñ»αñ░ αñÅαñÑαñ▓αÑçαñƒαñ┐αñòαÑìαñ╕ αñ½αÑçαñíαñ░αÑçαñ╢αñ¿ αñ¬αÑìαñ░αññαñ┐αñ»αÑïαñùαñ┐αññαñ╛ αñòαñ╛ αñ£αñ┐αñòαÑìαñ░ αñòαñ┐αñ»αñ╛αÑñ 100 αñ«αÑÇαñƒαñ░ αñòαÑÇ αñªαÑîαñíαñ╝ αñ«αÑçαñé αñÅαñÑαñ▓αÑÇαñƒ αñùαÑüαñ░αñ┐αñéαñªαñ░\n3:11\n3 minutes, 11 seconds\nαñ╡αÑÇαñ░ αñöαñ░ αñàαñ¿αñ┐αñ«αÑçαñ╢ αñòαÑï αñòαñê αñ¿αÑçαñ╢αñ¿αñ▓ αñ░αñ┐αñòαÑëαñ░αÑìαñí αñ¼αñ¿αñ╛αñ¿αÑç αñ¬αñ░ αñ¼αñºαñ╛αñê αñªαÑÇαÑñ\n3:18\n3 minutes, 18 seconds\nαñàαñ╕αñ« αñòαÑç αñ«αÑüαñûαÑìαñ»αñ«αñéαññαÑìαñ░αÑÇ αñ╣αÑçαñ«αñéαññ αñ╡αñ┐αñ╢αÑìαñ╡ αñ╢αñ░αÑìαñ«αñ╛ αñ¿αÑç αñ░αñòαÑìαñ╖αñ╛ αñ«αñéαññαÑìαñ░αÑÇ αñ░αñ╛αñ£αñ¿αñ╛αñÑ αñ╕αñ┐αñéαñ╣ αñ╕αÑç αñ«αÑüαñ▓αñ╛αñòαñ╛αññ αñòαÑÇαÑñ αñ¬αÑêαñ░ αñ¢αÑéαñòαñ░ αñ░αñ╛αñ£αñ¿αñ╛αñÑ αñ╕αñ┐αñéαñ╣ αñ╕αÑç αñåαñ╢αÑÇαñ░αÑìαñ╡αñ╛αñª αñ▓αñ┐αñ»αñ╛αÑñ\n3:29\n3 minutes, 29 seconds\nαñ¬αÑÇαñÅαñ« αñ«αÑïαñªαÑÇ αñòαÑÇ αñåαñ£ αñ╢αñ╛αñ« αñ░αñ╛αñ£αÑìαñ»αñ╕αñ¡αñ╛ αñÜαÑüαñ¿αñ╛αñ╡ αñòαÑï αñ▓αÑçαñòαñ░ αñàαñ╣αñ« αñ¼αÑêαñáαñò αñ╣αÑïαñ¿αÑç αñ╡αñ╛αñ▓αÑÇ αñ╣αÑêαÑñ αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñàαñºαÑìαñ»αñòαÑìαñ╖ αñ¿αñ┐αññαñ┐αñ¿ αñ¿αñ╡αÑÇαñ¿, αñùαÑâαñ╣ αñ«αñéαññαÑìαñ░αÑÇ αñàαñ«αñ┐αññ αñ╢αñ╛αñ╣, αñ£αÑçαñ¬αÑÇ αñ¿αñíαÑìαñíαñ╛ αñ╕αñ«αÑçαññ αñòαñê αñ¼αñíαñ╝αÑç αñ¿αÑçαññαñ╛ αñ╢αñ╛αñ«αñ┐αñ▓ αñ╣αÑïαñéαñùαÑçαÑñ\n3:42\n3 minutes, 42 seconds\nαñ»αÑéαñ¬αÑÇ αñòαÑç αñòαñê αñ╢αñ╣αñ░αÑïαñé αñ«αÑçαñé αñòαñíαñ╝αÑÇ αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñòαÑç αñ¼αÑÇαñÜ αñ»αÑéαñ¬αÑÇαñ¬αÑÇαñ╕αÑÇαñÅαñ╕ αñòαÑÇ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛αÑñ 1253 αñ¬αñªαÑïαñé αñòαÑç αñ▓αñ┐αñÅ αñ▓αñ╛αñûαÑïαñé αñàαñ¡αÑìαñ»αñ░αÑìαñÑαÑÇ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛ αñ«αÑçαñé αñ╢αñ╛αñ«αñ┐αñ▓ αñ╣αÑüαñÅαÑñ\n3:50\n3 minutes, 50 seconds\nαñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛ αñòαÑçαñéαñªαÑìαñ░αÑïαñé αñ¬αñ░ αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñ╕αñûαÑìαññ αñ╣αÑêαÑñ\n3:55\n3 minutes, 55 seconds\nαñÅαñ«αñ¬αÑÇ αñòαÑç αñ¼αÑüαñ░αñ╣αñ╛αñ¿αñ¬αÑüαñ░ αñ«αÑçαñé αñ░αñ╕αÑìαñ╕αÑÇ αñòαÑç αñùαÑïαñªαñ╛αñ« αñ«αÑçαñé αñ¡αÑÇαñ╖αñú αñåαñù αñ▓αñùαÑÇαÑñ αñ½αñ╛αñ»αñ░ αñ¼αÑìαñ░αñ┐αñùαÑçαñí αñòαÑÇ αñƒαÑÇαñ« αñ¿αÑç αñåαñù αñ¬αñ░ αñòαñ╛αñ¼αÑé αñ¬αñ╛ αñ▓αñ┐αñ»αñ╛αÑñ αñåαñù αñ▓αñùαñ¿αÑç αñòαÑÇ αñ╡αñ£αñ╣ αñàαñ¡αÑÇ αññαñò αñ╕αñ╛αñ½ αñ¿αñ╣αÑÇαñé αñ╣αÑêαÑñ\n4:05\n4 minutes, 5 seconds\nαñ╣αñ░αñ┐αñ»αñ╛αñúαñ╛ αñòαÑç αñùαÑüαñ░αÑüαñùαÑìαñ░αñ╛αñ« αñ«αÑçαñé αñ½αÑêαñòαÑìαñƒαÑìαñ░αÑÇ αñ«αÑçαñé αñåαñù αñ▓αñùαÑÇαÑñ αñ½αñ╛αñ»αñ░ αñ¼αÑìαñ░αñ┐αñùαÑçαñí αñòαÑÇ αñƒαÑÇαñ« αñ¿αÑç αñåαñù αñ¬αñ░ αñòαñ╛αñ¼αÑé αñ¬αñ╛ αñ▓αñ┐αñ»αñ╛αÑñ αñåαñù αñ╕αÑç αñ¼αñíαñ╝αÑç αñ¿αÑüαñòαñ╕αñ╛αñ¿ αñòαÑÇ αñåαñ╢αñéαñòαñ╛ αñ╣αÑêαÑñ\n4:13\n4 minutes, 13 seconds\nαñ╣αñ┐αñ«αñ╛αñÜαñ▓ αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñÜαñéαñ¼αñ╛ αñòαÑç αñÜαÑüαñ░αñ╛ αñ«αÑçαñé αñªαñ░αÑìαñªαñ¿αñ╛αñò αñ╣αñ╛αñªαñ╕αñ╛ αñ╣αÑüαñåαÑñ 500 αñ«αÑÇαñƒαñ░ αñùαñ╣αñ░αÑÇ αñûαñ╛αñê αñ«αÑçαñé αñùαñ┐αñ░αÑÇ αñòαñ╛αñ░αÑñ αñòαñ╛αñ░ αñ«αÑçαñé αñ╕αñ╡αñ╛αñ░ αñ¬αñ╛αñéαñÜ αñ▓αÑïαñùαÑïαñé αñòαÑÇ αñ«αÑîαññαÑñ αñ«αÑîαñòαÑç αñ¬αñ░ αñ░αÑçαñ╕αÑìαñòαÑìαñ»αÑé αñòαñ╛αñ░αÑìαñ» αñ£αñ╛αñ░αÑÇαÑñ\n4:24\n4 minutes, 24 seconds\n21 αñ░αñ╛αñ£αÑìαñ»αÑïαñé αñ«αÑçαñé αñåαñéαñºαÑÇ, αñ¼αñ╛αñ░αñ┐αñ╢ αñöαñ░ αññαÑéαñ½αñ╛αñ¿ αñòαñ╛ αñàαñ▓αñ░αÑìαñƒ αñ╣αÑêαÑñ αñ«αÑîαñ╕αñ« αñ╡αñ┐αñ¡αñ╛αñù αñ¿αÑç αñ£αñ╛αñ░αÑÇ αñòαñ┐αñ»αñ╛ αñ╣αÑê αñàαñ▓αñ░αÑìαñƒαÑñ 10 αñ░αñ╛αñ£αÑìαñ»αÑïαñé αñòαÑç αñ▓αñ┐αñÅ αññαÑéαñ½αñ╛αñ¿ αñòαÑÇ αñÜαÑçαññαñ╛αñ╡αñ¿αÑÇ αñ£αñ╛αñ░αÑÇαÑñ\n4:33\n4 minutes, 33 seconds\nαñ«αÑüαñéαñ¼αñê αñöαñ░ αñåαñ╕αñ¬αñ╛αñ╕ αñòαÑç αñçαñ▓αñ╛αñòαÑïαñé αñ«αÑçαñé αñ¼αñªαñ▓αñ╛ αñ«αÑîαñ╕αñ«αÑñ\n4:35\n4 minutes, 35 seconds\nαññαÑçαñ£ αñ╣αñ╡αñ╛αñôαñé αñòαÑç αñ╕αñ╛αñÑ αñ╣αÑüαñê αñ¼αñ╛αñ░αñ┐αñ╢αÑñ αñ▓αÑïαñùαÑïαñé αñòαÑï αñùαñ░αÑìαñ«αÑÇ αñ╕αÑç αñ░αñ╛αñ╣αññ αñ«αñ┐αñ▓αÑÇαÑñ αñåαñ¿αÑç αñ£αñ╛αñ¿αÑç αñ╡αñ╛αñ▓αÑç αñ▓αÑïαñùαÑïαñé αñòαÑï αñÑαÑïαñíαñ╝αÑÇ αñ╕αÑÇ αñªαñ┐αñòαÑìαñòαññαÑïαñé αñòαñ╛ αñ╕αñ╛αñ«αñ¿αñ╛ αñòαñ░αñ¿αñ╛ αñ¬αñíαñ╝αñ╛αÑñ\n4:44\n4 minutes, 44 seconds\nαñ░αñ╛αñ£αñ╕αÑìαñÑαñ╛αñ¿ αñòαÑç αñ£αñ»αñ¬αÑüαñ░ αñ«αÑçαñé αñ¼αñªαñ▓αñ╛ αñ«αÑîαñ╕αñ« αñòαñ╛ αñ«αñ┐αñ£αñ╛αñ£αÑñ αñòαñê αñ╢αñ╣αñ░αÑïαñé αñ«αÑçαñé αññαÑçαñ£ αñ¼αñ╛αñ░αñ┐αñ╢ αñ╣αÑüαñêαÑñ\n4:49\n4 minutes, 49 seconds\nαññαñ╛αñ¬αñ«αñ╛αñ¿ αñ«αÑçαñé αñ¡αÑÇ αñùαñ┐αñ░αñ╛αñ╡αñƒ αñ╣αÑêαÑñ αñ▓αÑïαñùαÑïαñé αñòαÑï αñùαñ░αÑìαñ«αÑÇ αñ╕αÑç αñ░αñ╛αñ╣αññ αñ«αñ┐αñ▓αÑÇαÑñ\n4:54\n4 minutes, 54 seconds\nαñ░αñ╛αñ£αñ╕αÑìαñÑαñ╛αñ¿ αñòαÑÇ αñ¬αñ╛αñ▓αÑÇ αñ«αÑçαñé αñåαñéαñºαÑÇ αñ¼αñ╛αñ░αñ┐αñ╢ αñòαÑÇ αñ╡αñ£αñ╣ αñ╕αÑç αñ¡αñ╛αñ░αÑÇ αññαñ¼αñ╛αñ╣αÑÇ αñ╣αÑüαñê αñ╣αÑêαÑñ αñ¬αÑçαñíαñ╝ αñùαñ┐αñ░αñ¿αÑç αñ╕αÑç αñÅαñò αñ╡αÑìαñ»αñòαÑìαññαñ┐ αñòαÑÇ αñ«αÑîαññ αñ╣αÑï αñùαñêαÑñ αñ¼αñ╛αñçαñò αñ╕αñ╡αñ╛αñ░ αñ¡αÑÇ αñÿαñ╛αñ»αñ▓ αñ╣αÑüαñåαÑñ αñ¼αñ┐αñ£αñ▓αÑÇ αñòαÑç αñûαñéαñ¡αÑç αñùαñ┐αñ░αñ¿αÑç αñ╕αÑç αñ¼αññαÑìαññαÑÇ αñ╣αÑêαÑñ\n5:07\n5 minutes, 7 seconds\nαñ«αÑüαñéαñ¼αñê αñòαÑÇ αñ¼αñ╛αñ░αñ┐αñ╢ αñòαÑç αñÜαñ▓αññαÑç αñòαñê αñ╡αñ╛αñ╣αñ¿ αñ╣αñ╛αñªαñ╕αÑç αñòαñ╛ αñ╢αñ┐αñòαñ╛αñ░ αñ╣αÑüαñÅ αñ╣αÑêαñéαÑñ αñƒαÑìαñ░αñò αñöαñ░ αñ¼αñ╕ αñ«αÑçαñé αñƒαñòαÑìαñòαñ░ αñ╣αÑï αñùαñêαÑñ αñ╣αñ╛αñªαñ╕αÑç αñ«αÑçαñé αñòαñê αñ▓αÑïαñù αñÿαñ╛αñ»αñ▓ αñ¼αññαñ╛αñÅ αñ£αñ╛ αñ░αñ╣αÑç αñ╣αÑêαñéαÑñ\n5:15\n5 minutes, 15 seconds\nαñùαÑüαñ£αñ░αñ╛αññ αñòαÑç αñåαñ¿αñéαñª αñ«αÑçαñé αñÅαñò αñ¿αñ┐αñ░αÑìαñ«αñ╛αñúαñ╛αñºαÑÇαñ¿ αñ░αÑçαñ▓αñ╡αÑç αñòαñ╛ αñôαñ╡αñ░αñ¼αñ┐αñ£ αñùαñ┐αñ░αñ╛αÑñ αñªαÑï αñ¬αñ┐αñ▓αñ░ αñòαÑç αñ¼αÑÇαñÜ αñòαñ╛ αñ╣αñ┐αñ╕αÑìαñ╕αñ╛ αñùαñ┐αñ░αñ¿αÑç αñ╕αÑç αñ╣αñ╛αñªαñ╕αñ╛ αñ╣αÑüαñåαÑñ αñùαñ¿αÑÇαñ«αññ αñ»αñ╣ αñ░αñ╣αÑÇ αñòαñ┐ αñ╣αñ╛αñªαñ╕αÑç αñòαÑç αñ╡αñòαÑìαññ αñòαÑïαñê αñ╡αñ╣αñ╛αñé αñ¬αñ░ αñ«αÑîαñ£αÑéαñª αñ¿αñ╣αÑÇαñé αñÑαñ╛αÑñ\n5:27\n5 minutes, 27 seconds\nαñùαÑüαñ£αñ░αñ╛αññ αñòαÑç αñ£αñ╛αñ«αñ¿αñùαñ░ αñ«αÑçαñé αñ╕αñíαñ╝αñò αñ¬αñ░ αñùαñ┐αñ░αñ╛ αñ▓αÑïαñ╣αÑç αñòαñ╛ αñÅαñéαñùαñ▓αÑñ αññαÑçαñ£ αñ╣αñ╡αñ╛αñôαñé αñòαÑç αñÜαñ▓αññαÑç αñàαñÜαñ╛αñ¿αñò αñ╕αÑç αñƒαÑéαñƒ αñòαñ░ αñùαñ┐αñ░αñ╛αÑñ αñ╣αñ╛αñªαñ╕αÑç αñ«αÑçαñé αñ¼αñ╛αñ▓-αñ¼αñ╛αñ▓ αñ¼αñÜαÑç αñ░αñ╛αñ╣ αñòαÑÇαÑñ\n5:36\n5 minutes, 36 seconds\nαñùαÑüαñ£αñ░αñ╛αññ αñòαÑç αñ«αñ╣αÑÇαñ╕αñ╛αñùαñ░ αñ«αÑçαñé αññαÑçαñ£ αñ╣αñ╡αñ╛αñôαñé αñòαÑç αñ╕αñ╛αñÑ αñ«αÑéαñ╕αñ▓αñ╛αñºαñ╛αñ░ αñ¼αñ╛αñ░αñ┐αñ╢αÑñ αñåαñªαñ┐ αñòαÑç αñÜαñ▓αññαÑç αñƒαÑéαñƒαÑç αñ¼αñ┐αñ£αñ▓αÑÇ αñòαÑç αññαñ╛αñ░αÑñ αñòαñê αñçαñ▓αñ╛αñòαÑïαñé αñ«αÑçαñé αñ¼αñ┐αñ£αñ▓αÑÇ αñòαÑüαñ▓ αñ╣αÑêαÑñ\n5:45\n5 minutes, 45 seconds\nαñëαññαÑìαññαñ░αñ╛αñûαñéαñí αñ«αÑçαñé αñ¼αñ╛αñ░αñ┐αñ╢ αñòαÑç αñ¼αñ╛αñª αñ¿αÑêαñ¿αÑÇαññαñ╛αñ▓ αñòαÑÇ αñ¥αÑÇαñ▓ αñ«αÑçαñé αñƒαñòαñ░αñ╛αñê αñûαñ╛αñ▓αÑÇ αñ¿αñ╛αñ╡αÑñ αñùαñ░αÑìαñ«αÑÇ αñòαÑç αñ«αÑîαñ╕αñ« αñ«αÑçαñé αñ¥αÑÇαñ▓ αñ╕αÑç αñëαñáαññαñ╛ αñªαñ┐αñûαñ╛ αñ¼αñíαñ╝αÑÇ αñ«αñ╛αññαÑìαñ░αñ╛ αñ«αÑçαñé αñòαÑïαñ╣αñ░αñ╛αÑñ\n5:55\n5 minutes, 55 seconds\nαñªαÑçαñ╢ αñ¡αñ░ αñ«αÑçαñé αñ«αÑîαñ╕αñ« αñòαÑç αñ¼αñªαñ▓αññαÑç αñ«αñ┐αñ£αñ╛αñ£ αñòαÑç αñ¼αÑÇαñÜαÑñ\n5:57\n5 minutes, 57 seconds\nαñ╣αñ┐αñ«αñ╛αñÜαñ▓ αñ«αÑçαñé αñëαñ«αñíαñ╝αÑç αñ¬αñ░αÑìαñ»αñƒαñòαÑñ αñòαÑüαñ▓αÑìαñ▓αÑé αñ«αñ¿αñ╛αñ▓αÑÇ αñ«αÑçαñé αñ¼αñíαñ╝αÑÇ αñ╕αñéαñûαÑìαñ»αñ╛ αñ«αÑçαñé αñ¬αñ╣αÑüαñéαñÜ αñ░αñ╣αÑç αñ╣αÑêαñé αñƒαÑéαñ░αñ┐αñ╕αÑìαñƒαÑñ αñƒαÑìαñ░αÑêαñ½αñ┐αñò αñòαÑï αñ▓αÑçαñòαñ░ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ╕αñéαñ¡αñ╛αñ▓αñ╛ αñ«αÑïαñ░αÑìαñÜαñ╛αÑñ\n6:05\n6 minutes, 5 seconds\nαñ░αñ╛αñ£αñ╕αÑìαñÑαñ╛αñ¿ αñòαÑç αñÜαÑïαñ░αÑé αñ╕αñ«αÑçαññ αñòαñê αñ╢αñ╣αñ░αÑïαñé αñ«αÑçαñé αñ░αÑçαññαÑÇαñ▓αñ╛ αññαÑéαñ½αñ╛αñ¿ αñå αñùαñ»αñ╛αÑñ αñÿαñ░αÑïαñé αñ«αÑçαñé αñ¡αñ░αÑÇ αñºαÑéαñ▓αÑñ\n6:09\n6 minutes, 9 seconds\nαñªαñ┐αñ¿ αñ«αÑçαñé αñ¢αñ╛αñ»αñ╛ αñàαñéαñºαÑçαñ░αñ╛αÑñ αñÜαñ╛αñ░αÑïαñé αñôαñ░ αñªαñ┐αñûαñ╛ αñ░αÑçαññ αñòαñ╛ αñ¼αñ╡αñéαñíαñ░αÑñ\n6:14\n6 minutes, 14 seconds\nαñ░αñ╛αñ£αñ╕αÑìαñÑαñ╛αñ¿ αñòαÑç αñ╣αñ¿αÑüαñ«αñ╛αñ¿αñùαñóαñ╝ αñ«αÑçαñé αñ¡αÑÇ αñ░αÑçαññαÑÇαñ▓αñ╛ αñ¼αñ╡αñéαñíαñ░ αñå αñùαñ»αñ╛αÑñ αñºαÑéαñ▓ αñòαÑç αñùαÑüαñ¼αñ╛αñ░ αñòαÑÇ αñ╡αñ£αñ╣ αñ╕αÑç αñªαñ┐αñ¿ αñ«αÑçαñé αñ¢αñ╛αñ»αñ╛ αñòαñ╛αñ▓αñ╛ αñàαñéαñºαÑçαñ░αñ╛αÑñ 60 αñ╕αÑç 80 αñòαñ┐.αñ«αÑÇ./ αñÿαñéαñƒαÑç αñòαÑÇ αñ░αñ½αÑìαññαñ╛αñ░ αñ╕αÑç αñÜαñ▓αÑÇ αñ╣αñ╡αñ╛αñÅαñéαÑñ\n6:25\n6 minutes, 25 seconds\nαñ░αñ╛αñ£αñ╕αÑìαñÑαñ╛αñ¿ αñòαÑç αñ╢αÑìαñ░αÑÇαñùαñéαñùαñ╛αñ¿αñùαñ░ αñ«αÑçαñé αñ¡αÑÇ αñ¬αñ╛αñòαñ┐αñ╕αÑìαññαñ╛αñ¿ αñòαÑÇ αñôαñ░ αñ╕αÑç αñåαñ»αñ╛ αñ░αÑçαññ αñòαñ╛ αñ¼αñéαñªαñ░αÑñ αññαÑéαñ½αñ╛αñ¿ αñ¿αÑç 30 αñ«αñ┐αñ¿αñƒ αññαñò αñòαñ╣αñ░ αñ¼αñ░αñ¬αñ╛αñ»αñ╛αÑñ αñ«αÑîαñ╕αñ« αñ«αÑçαñé αñ¼αñªαñ▓αñ╛αñ╡ αñ╕αÑç 8┬░ αññαñò αñùαñ┐αñ░αñ╛ αññαñ╛αñ¬αñ«αñ╛αñ¿αÑñ\n6:37\n6 minutes, 37 seconds\nαñ¬αÑìαñ░αñºαñ╛αñ¿αñ«αñéαññαÑìαñ░αÑÇ αñ¿αñ░αÑçαñéαñªαÑìαñ░ αñ«αÑïαñªαÑÇ αñ¿αÑç αñªαÑçαñ╢αñ╡αñ╛αñ╕αñ┐αñ»αÑïαñé αñòαÑï αñùαñ░αÑìαñ«αÑÇ αñ╕αÑç αñ¼αñÜαñ¿αÑç αñòαÑÇ αñ╕αñ▓αñ╛αñ╣ αñªαÑÇ αñ╣αÑêαÑñ αñëαñ¿αÑìαñ╣αÑïαñéαñ¿αÑç αñòαñ╣αñ╛ αñ╕αñ░αñòαñ╛αñ░ αñòαÑÇ αñùαñ╛αñçαñíαñ▓αñ╛αñçαñéαñ╕ αñòαñ╛ αñ¬αñ╛αñ▓αñ¿ αñòαñ░αÑçαñéαÑñ αñªαÑçαñ╢ αñòαÑç αñ▓αÑïαñùαÑïαñé αñ╕αÑç αñºαÑìαñ»αñ╛αñ¿ αñ░αñûαñ¿αÑç αñòαÑÇ αñàαñ¬αÑÇαñ▓ αñòαÑÇ αñ╣αÑêαÑñ\n6:47\n6 minutes, 47 seconds\nαñ»αÑéαñ¬αÑÇ αñòαÑç αñòαñ╛αñ¿αñ¬αÑüαñ░ αñ«αÑçαñé αñ¼αÑÇαñÅαñí αñòαÑÇ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛ αñªαÑçαñ¿αÑç αñ¬αñ╣αÑüαñéαñÜαÑç αñàαñ¡αÑìαñ»αñ░αÑìαñÑαÑÇ αñ¿αñ╛αñ▓αÑç αñ«αÑçαñé αñùαñ┐αñ░αÑçαÑñ αñ¬αññαÑìαñÑαñ░ αñƒαÑéαñƒαñ¿αÑç αñ╕αÑç αñ»αñ╣ αñ╣αñ╛αñªαñ╕αñ╛ αñ╣αÑï αñùαñ»αñ╛αÑñ αñåαñ╕αñ¬αñ╛αñ╕ αñ«αÑîαñ£αÑéαñª αñ▓αÑïαñùαÑïαñé αñ¿αÑç αñàαñ¡αÑìαñ»αñ░αÑìαñÑαñ┐αñ»αÑïαñé αñòαÑï αñ¼αñ╛αñ╣αñ░ αñ¿αñ┐αñòαñ╛αñ▓αñ╛αÑñ\n6:56\n6 minutes, 56 seconds\nαñ¼αñ┐αñ╣αñ╛αñ░ αñòαÑç αñ«αÑüαñ£αñ½αÑìαñ½αñ░αñ¬αÑüαñ░ αñ«αÑçαñé αñ╕αñ╛αñéαñ╕αñª αñ╡αÑÇαñúαñ╛ αñªαÑçαñ╡αÑÇ αñòαÑÇ αñ«αÑîαñ£αÑéαñªαñùαÑÇ αñ«αÑçαñé αñ╡αñ┐αñºαñ╛αñ»αñò αñöαñ░ αñÅαñ▓αñ£αÑçαñ¬αÑÇ αñ░αñ╛αñ«αñ╡αñ┐αñ▓αñ╛αñ╕ αñòαÑç αñ£αñ┐αñ▓αñ╛ αñàαñºαÑìαñ»αñòαÑìαñ╖ αñ«αÑçαñé αñ¿αÑïαñòαñ¥αÑïαñéαñòαÑñ αñ╢αÑìαñ░αÑçαñ» αñòαÑç αñÜαñòαÑìαñòαñ░ αñ«αÑçαñé αñåαñ¬αñ╕ αñ«αÑçαñé αñ¡αñ┐αñíαñ╝αÑç αñªαÑïαñ¿αÑïαñéαÑñ\n7:09\n7 minutes, 9 seconds\nαñ¼αñ┐αñ╣αñ╛αñ░ αñòαÑç αñ¿αñ╛αñ▓αñéαñªαñ╛ αñ«αÑçαñé αñ¼αñÜαÑìαñÜαÑïαñé αñòαÑç αñ╡αñ┐αñ╡αñ╛αñª αñ«αÑçαñé αñàαñºαÑçαñíαñ╝ αñ╡αÑìαñ»αñòαÑìαññαñ┐ αñòαÑÇ αñ¬αÑÇαñƒ-αñ¬αÑÇαñƒ αñòαñ░ αñ╣αññαÑìαñ»αñ╛ αñòαñ░ αñªαÑÇ αñùαñê αñ╣αÑêαÑñ αñÿαñƒαñ¿αñ╛ αñ╕αÑç αñçαñ▓αñ╛αñòαÑç αñ«αÑçαñé αñ╕αñ¿αñ╕αñ¿αÑÇ αñ½αÑêαñ▓αÑÇ αñ╣αÑüαñê αñ╣αÑêαÑñ αñ£αñ╛αñéαñÜ αñ¬αñíαñ╝αññαñ╛αñ▓ αñòαñ░ αñ░αñ╣αÑÇ αñ╣αÑê αñ¬αÑüαñ▓αñ┐αñ╕αÑñ\n7:19\n7 minutes, 19 seconds\nαñ«αñ╣αñ╛αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░ αñòαÑç αñ╕αññαñ╛αñ░αñ╛ αñ«αÑçαñé 95 αñùαÑìαñ░αñ╛αñ« αñíαÑìαñ░αñùαÑìαñ╕ αñòαÑç αñ╕αñ╛αñÑ αññαÑÇαñ¿ αñåαñ░αÑïαñ¬αÑÇ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñÅ αñùαñÅ αñ╣αÑêαñéαÑñ\n7:23\n7 minutes, 23 seconds\nαñòαñ░αÑÇαñ¼ 3 αñ▓αñ╛αñû αñ¼αññαñ╛αñê αñ£αñ╛ αñ░αñ╣αÑÇ αñ╣αÑê αñ¬αñòαñíαñ╝αÑç αñùαñÅ αñíαÑìαñ░αñùαÑìαñ╕ αñòαÑÇ αñòαÑÇαñ«αññαÑñ\n7:29\n7 minutes, 29 seconds\nαñ»αÑéαñ¬αÑÇ αñòαÑç αñ╣αñ«αÑÇαñ░αñ¬αÑüαñ░ αñ«αÑçαñé αñ¬αÑüαñ▓ αñ¬αñ░ αñ╕αñ┐αñ»αñ╛αñ╕αÑÇ αñÿαñ«αñ╛αñ╕αñ╛αñ¿ αñ£αñ╛αñ░αÑÇ αñ╣αÑêαÑñ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñòαñ╛ 14 αñ╕αñªαñ╕αÑìαñ» αñ¬αÑìαñ░αññαñ┐αñ¿αñ┐αñºαñ┐ αñ«αñéαñíαñ▓ αñ¬αÑüαñ▓ αñòαÑÇ αñ£αñ╛αñéαñÜ αñòαñ░αñ¿αÑç αñ¬αñ╣αÑüαñéαñÜαñ╛αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñòαÑç αñ╕αÑìαñ▓αÑêαñ¼ αñöαñ░ αñ¬αñ┐αñ▓αñ░ αñ╕αÑç αñëαñûαñ╛αñíαñ╝αÑÇ αñòαñéαñòαÑìαñ░αÑÇαñƒαÑñ\n7:42\n7 minutes, 42 seconds\nαñåαñëαñƒ αñæαñ½ αñªαñ┐αñ▓αÑìαñ▓αÑÇ αñòαÑç αñ¼αñòαñ░αñ╡αñ╛αñ▓αñ╛ αñ░αÑéαñƒ αñ¬αñ░ αñ¬αÑüαñ▓αñ┐αñ╕ αñöαñ░ αñ¼αñªαñ«αñ╛αñ╢ αñòαÑç αñ¼αÑÇαñÜ αñ«αÑüαñáαñ¡αÑçαñíαñ╝ αñ╣αÑüαñê αñ╣αÑêαÑñ αñòαñê αñ░αñ╛αñëαñéαñí αñ½αñ╛αñ»αñ░αñ┐αñéαñù αñòαÑç αñ¼αñ╛αñª αñªαñ¼αÑïαñÜαñ╛ αñùαñ»αñ╛ αñòαÑüαñûαÑìαñ»αñ╛αññ αñàαñ¬αñ░αñ╛αñºαÑÇαÑñ\n7:48\n7 minutes, 48 seconds\nαñÜαñ╛αñ░ αñ«αñ╛αñ«αñ▓αÑïαñé αñ«αÑçαñé αñ╡αñ╛αñéαñƒαÑçαñí αñÜαñ▓ αñ░αñ╣αñ╛ αñÑαñ╛ αñ¼αñªαñ«αñ╛αñ╢ αñåαñ╢αÑÇαñ╖ αñ¼αñòαñ░αñ╡αñ╛αñ▓αñ╛αÑñ\n7:55\n7 minutes, 55 seconds\nαñ»αÑéαñ¬αÑÇ αñòαÑÇ αñ░αñ╛αñ£αñºαñ╛αñ¿αÑÇ αñ▓αñûαñ¿αñè αñ«αÑçαñé αñ«αÑüαñáαñ¡αÑçαñíαñ╝ αñ«αÑçαñé αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ¼αñªαñ«αñ╛αñ╢ αñ╕αñ¿αÑÇ αñ»αñ╛αñªαñ╡ αñòαÑï αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛ αñ╣αÑêαÑñ αñàαñ¬αñ░αñ╛αñºαÑÇ αñòαÑç αñ¬αñ╛αñ╕ αñ╕αÑç αñÅαñò αñàαñ╡αÑêαñº αññαñ«αñéαñÜαñ╛ αñ¼αñ░αñ╛αñ«αñª αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛αÑñ αñ╣αññαÑìαñ»αñ╛ αñòαÑç αñ¬αÑìαñ░αñ»αñ╛αñ╕ αñòαñ╛ αñåαñ░αÑïαñ¬αÑÇ αñ╣αÑê αñ¼αñªαñ«αñ╛αñ╢αÑñ\n8:06\n8 minutes, 6 seconds\nαñ»αÑéαñ¬αÑÇ αñòαÑç αñ«αñè αñ«αÑçαñé αñàαñ¬αñ░αñ╛αñºαñ┐αñ»αÑïαñé αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñ¬αÑüαñ▓αñ┐αñ╕ αñòαñ╛ αñÅαñòαÑìαñ╢αñ¿αÑñ αñ╢αñ╛αññαñ┐αñ░ αñàαñ¬αñ░αñ╛αñºαÑÇ αñ░αñ┐αñòαÑìαñòαÑÇ αñûαñ╛αñ¿ αñòαÑï αñíαÑüαñùαñíαÑüαñùαÑÇ αñ¼αñ£αñ╡αñ╛αñòαñ░ αñ£αñ┐αñ▓αñ╛ αñ¼αñªαñ░ αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛αÑñ 4 αñ«αñ╣αÑÇαñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ αñ£αñ┐αñ▓αÑç αñ╕αÑç αñ¼αñ╛αñ╣αñ░ αñ¿αñ┐αñòαñ╛αñ▓αñ╛ αñùαñ»αñ╛αÑñ\n8:19\n8 minutes, 19 seconds\nαñ»αÑéαñ¬αÑÇ αñòαÑç αñ¥αñ╛αñéαñ╕αÑÇ αñ«αÑçαñé αñÜαÑïαñ░ αñ¿αÑç αñªαÑüαñòαñ╛αñ¿ αñ«αÑçαñé αñÿαÑüαñ╕αñòαñ░ αñòαÑêαñ╢ αñ¬αñ░ αñ╣αñ╛αñÑ αñ╕αñ╛αñ½ αñòαñ┐αñ»αñ╛αÑñ αñÜαÑïαñ░αÑÇ αñòαÑÇ αñ¬αÑéαñ░αÑÇ αñÿαñƒαñ¿αñ╛ αñ╕αÑÇαñ╕αÑÇαñƒαÑÇαñ╡αÑÇ αñòαÑêαñ«αñ░αÑç αñ«αÑçαñé αñ░αñ┐αñòαÑëαñ░αÑìαñí αñ╣αÑï αñùαñê αñ╣αÑêαÑñ\n8:25\n8 minutes, 25 seconds\nαñ¬αÑüαñ▓αñ┐αñ╕ αñòαÑï αñÜαÑïαñ░αÑïαñé αñòαÑÇ αññαñ▓αñ╛αñ╢ αñ╣αÑêαÑñ\n8:32\n8 minutes, 32 seconds\nαñ«αÑüαñéαñ¼αñê αñ«αÑçαñé αñ¬αññαÑìαñ¿αÑÇ αñ╕αÑç αñ¼αÑçαñ░αñ╣αñ«αÑÇ αñòαñ░αñ¿αÑç αñòαÑç αñåαñ░αÑïαñ¬ αñ«αÑçαñé αñ¬αññαñ┐ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñ╣αÑüαñå αñ╣αÑêαÑñ αñåαñ░αÑïαñ¬αÑÇ αñ¿αÑç αñ¬αññαÑìαñ¿αÑÇ αñ¬αñ░ αñÅαñ╕αñ┐αñí αñàαñƒαÑêαñò αñòαñ┐αñ»αñ╛αÑñ 4 αñÿαñéαñƒαÑç αññαñò αñ«αÑüαñ░αÑìαñùαñ╛ αñ¼αñ¿αñ╛αñ»αñ╛αÑñ αñ¬αññαÑìαñ¿αÑÇ αñ¬αñ░ αñÜαñ╛αñòαÑé αñ╕αÑç αñ╣αñ«αñ▓αñ╛ αñ¡αÑÇ αñòαñ┐αñ»αñ╛αÑñ\n8:43\n8 minutes, 43 seconds\nαñ╣αñ░αñ┐αñ»αñ╛αñúαñ╛ αñòαÑç αñ╕αñ┐αñ░αñ╕αñ╛ αñ«αÑçαñé αñ»αÑéαñ░αñ┐αñ»αñ╛ αñòαÑÇ αñòαñ╛αñ▓αñ╛αñ¼αñ╛αñ£αñ╛αñ░αÑÇ αñòαñ╛ αñ¡αñéαñíαñ╛αñ½αÑïαñíαñ╝ αñ╣αÑüαñå αñ╣αÑêαÑñ αñòαñ┐αñ╕αñ╛αñ¿αÑïαñé αñòαñ╛ αñåαñ░αÑïαñ¬ αñ╣αÑê αñ¬αÑêαñòαñ┐αñéαñù αñ¼αñªαñ▓αñòαñ░ αñ»αÑéαñ░αñ┐αñ»αñ╛ αñ¡αÑçαñ£αÑÇ αñ£αñ╛ αñ░αñ╣αÑÇ αñÑαÑÇ αñ░αñ╛αñ£αñ╕αÑìαñÑαñ╛αñ¿αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ¢αñ╛αñ¬αÑçαñ«αñ╛αñ░αÑÇ αñòαñ░ αñ»αÑéαñ░αñ┐αñ»αñ╛ αñòαÑÇ αñ¼αñ░αñ╛αñ«αñªαÑñ\n8:54\n8 minutes, 54 seconds\nαñåαñùαñ░αñ╛ αñ«αÑçαñé αññαÑÇαñ¿ αñ«αñéαñ£αñ┐αñ▓αñ╛ αñ¼αñ┐αñ▓αÑìαñíαñ┐αñéαñù αñ«αÑçαñé αñåαñù αñ▓αñùαÑÇαÑñ\n8:57\n8 minutes, 57 seconds\nαñ╣αñ╛αñ▓αñ╛αñéαñòαñ┐ αñåαñù αñ¬αñ░ αñòαñ╛αñ¼αÑé αñ¬αñ╛ αñ▓αñ┐αñ»αñ╛ αñùαñ»αñ╛αÑñ αñ¼αñ┐αñ▓αÑìαñíαñ┐αñéαñù αñ«αÑçαñé αñ«αÑîαñ£αÑéαñª αñ╕αñ¡αÑÇ αñ▓αÑïαñùαÑïαñé αñòαÑï αñ╕αÑüαñ░αñòαÑìαñ╖αñ┐αññ αñ¼αñ╛αñ╣αñ░ αñ¿αñ┐αñòαñ╛αñ▓ αñ▓αñ┐αñ»αñ╛ αñùαñ»αñ╛αÑñ αñ╢αÑëαñ░αÑìαñƒ αñ╕αñ░αÑìαñòαñ┐αñƒ αñ╕αÑç αñåαñù αñ▓αñùαñ¿αÑç αñòαÑÇ αñåαñ╢αñéαñòαñ╛ αñòαÑçαÑñ\n9:06\n9 minutes, 6 seconds\nαñªαñ┐αñ▓αÑìαñ▓αÑÇ αñ«αÑçαñé αñ½αÑêαñòαÑìαñƒαÑìαñ░αÑÇ αñ«αÑçαñé αñåαñù αñ╕αÑç αñ¼αñíαñ╝αñ╛ αñ¿αÑüαñòαñ╕αñ╛αñ¿ αñ╣αÑüαñå αñ╣αÑêαÑñ αñ«αñ╣αñ┐αñ¬αñ╛αñ▓ αñÅαñ░αñ┐αñ»αñ╛ αñòαÑÇ αñÅαñò αñ½αÑêαñòαÑìαñƒαÑìαñ░αÑÇ αñ«αÑçαñé αñ¡αÑÇαñ╖αñú αñåαñù αñ▓αñùαÑÇαÑñ αñ¬αñ╣αÑüαñéαñÜαÑÇ αñªαñ«αñòαñ▓ αñòαÑÇ αñùαñ╛αñíαñ╝αñ┐αñ»αÑïαñé αñ¿αÑç αñåαñù αñòαÑï αñ¼αÑüαñ¥αñ╛ αñ▓αñ┐αñ»αñ╛αÑñ\n9:15\n9 minutes, 15 seconds\nαñ»αÑéαñ¬αÑÇ αñòαÑç αñ░αñ╛αñ»αñ¼αñ░αÑçαñ▓αÑÇ αñ«αÑçαñé αñªαñ┐αñûαñ╛ αñåαñù αñòαñ╛ αññαñ╛αñéαñíαñ╡αÑñ\n9:17\n9 minutes, 17 seconds\nαñ¡αÑÇαñ╖αñú αñåαñù αñ╕αÑç αñòαñ¬αñíαñ╝αÑç αñòαÑÇ αñªαÑüαñòαñ╛αñ¿ αñ«αÑçαñé αñ¼αñíαñ╝αñ╛ αñ¿αÑüαñòαñ╕αñ╛αñ¿ αñ╣αÑüαñå αñ╣αÑêαÑñ αñ▓αñ╛αñûαÑïαñé αñòαñ╛ αñ╕αñ╛αñ«αñ╛αñ¿ αñ£αñ▓αñòαñ░ αñûαñ╛αñò αñ╣αÑüαñåαÑñ\n9:24\n9 minutes, 24 seconds\nαñ£αñ«αÑìαñ«αÑé αñòαñ╢αÑìαñ«αÑÇαñ░ αñòαÑç αñ¼αñ¿αñ┐αñ╣αñ╛αñ▓ αñ«αÑçαñé αñûαñ╛αñê αñ«αÑçαñé αñùαñ┐αñ░αñ╛ αñƒαÑìαñ░αñòαÑñ αñ╣αñ╛αñªαñ╕αÑç αñòαÑç αñ¼αñ╛αñª αñƒαÑìαñ░αñò αñ«αÑçαñé αñåαñù αñ¡αÑÇ αñ▓αñùαÑÇαÑñ αñªαÑï αñ▓αÑïαñùαÑïαñé αñòαÑç αñ«αñ╛αñ░αÑç αñ£αñ╛αñ¿αÑç αñòαÑÇ αñåαñ╢αñéαñòαñ╛ αñòαÑçαÑñ\n9:34\n9 minutes, 34 seconds\nαñ»αÑéαñ¬αÑÇ αñòαÑç αñëαñ¿αÑìαñ¿αñ╛αñ╡ αñ«αÑçαñé αñ░αñ┐αñéαñù αñ░αÑïαñí αñ¿αñ┐αñ░αÑìαñ«αñ╛αñú αñòαÑç αñ▓αñ┐αñÅ αñÜαñ▓αñ╛ αñ¼αÑüαñ▓αñíαÑïαñ£αñ░αÑñ αñ¼αñ┐αñ¿αñ╛ αñ«αÑüαñåαñ╡αñ£αñ╛ αñªαñ┐αñÅ αñ╣αÑüαñÅ αñ«αñòαñ╛αñ¿ αññαÑïαñíαñ╝αñ¿αÑç αñòαñ╛ αñåαñ░αÑïαñ¬ αñ▓αñùαñ╛αñ»αñ╛ αñùαñ»αñ╛αÑñ αñùαñ╛αñéαñ╡ αñ╡αñ╛αñ▓αÑïαñé αñ¿αÑç αñòαñ┐αñ»αñ╛ αñ£αñ¼αñ░αñªαñ╕αÑìαññ αñ╣αñéαñùαñ╛αñ«αñ╛αÑñ\n9:44\n9 minutes, 44 seconds\nαñ»αÑéαñ¬αÑÇ αñòαÑç αñ╣αñ«αÑÇαñ░αñ¬αÑüαñ░ αñ«αÑçαñé αñ╕αñ½αñ╛αñê αñòαñ░αÑìαñ«αñÜαñ╛αñ░αÑÇ αñƒαÑëαñ░αÑìαñÜ αñòαÑÇ αñ░αÑïαñ╢αñ¿αÑÇ αñ«αÑçαñé αñ«αñ░αÑÇαñ£ αñòαÑï αñƒαñ╛αñéαñòαÑç αñ▓αñùαñ╛ αñ░αñ╣αñ╛αÑñ\n9:48\n9 minutes, 48 seconds\nαñ╡αÑÇαñíαñ┐αñ»αÑï αñ╡αñ╛αñ»αñ░αñ▓ αñ╣αÑïαñ¿αÑç αñòαÑç αñ¼αñ╛αñª αñ╕αñ╡αñ╛αñ▓αÑïαñé αñ«αÑçαñé αñ╕αÑìαñ╡αñ╛αñ╕αÑìαñÑαÑìαñ» αñ╡αñ┐αñ¡αñ╛αñù αñ╕αÑüαñ«αÑçαñ░αñ¬αÑüαñ░ αñ╕αñ╛αñ«αÑüαñªαñ╛αñ»αñ┐αñò αñ╕αÑìαñ╡αñ╛αñ╕αÑìαñÑαÑìαñ» αñòαÑçαñéαñªαÑìαñ░ αñòαñ╛ αñ»αÑç αñ«αñ╛αñ«αñ▓αñ╛ αñ╣αÑêαÑñ\n9:56\n9 minutes, 56 seconds\nαñ▓αñûαñ¿αñè αñòαÑç αñ¬αñ¬αñ░αñ╕αñ¿ αñùαÑìαñ░αñ╛αñ«αñ¡αñ╛ αñ«αÑçαñé αñ¬αñ╛αñ¬αñíαñ╝ αñòαÑÇ αññαñ░αñ╣ αñëαñûαñíαñ╝αÑÇ αñ╕αñíαñ╝αñòαÑñ αñ¿αñ┐αñ░αÑìαñ«αñ╛αñú αñòαÑÇ αñùαÑüαñúαñ╡αññαÑìαññαñ╛ αñ¬αñ░ αñûαñíαñ╝αÑç αñ╣αÑüαñÅ αñ╕αñ╡αñ╛αñ▓αÑñ αñ╡αÑÇαñíαñ┐αñ»αÑï αñ╕αÑïαñ╢αñ▓ αñ«αÑÇαñíαñ┐αñ»αñ╛ αñ¬αñ░ αñ╡αñ╛αñ»αñ░αñ▓ αñ╣αÑüαñåαÑñ αñàαñºαñ┐αñòαñ╛αñ░αñ┐αñ»αÑïαñé αñ«αÑçαñé αñ╣αñíαñ╝αñòαñéαñ¬ αñ«αñÜαñ╛ αñ╣αÑüαñå αñ╣αÑêαÑñ\n10:07\n10 minutes, 7 seconds\nαñ£αñ«αÑìαñ«αÑé αñòαñ╢αÑìαñ«αÑÇαñ░ αñòαÑç αñ¬αÑü αñ«αÑçαñé αñ«αñ┐αñ▓αñ╛ αñ£αñ┐αñéαñªαñ╛ αñ¬αñ╛αñòαñ┐αñ╕αÑìαññαñ╛αñ¿αÑÇ αñ«αÑïαñƒαñ╛αñ░ αñ╢αÑçαñ▓αÑñ αñ╕αÑçαñ¿αñ╛ αñ¿αÑç αñçαñ╕αÑç αñ¿αñ┐αñ╖αÑìαñòαÑìαñ░αñ┐αñ» αñòαñ┐αñ»αñ╛αÑñ αñÅαñò αñ¬αñ╛αñ░αÑìαñò αñ╕αÑç αñ¼αñ░αñ╛αñ«αñªαñùαÑÇ αñ╣αÑüαñê αñ╣αÑêαÑñ αñåαñ╕αñ¬αñ╛αñ╕ αñòαÑç αñçαñ▓αñ╛αñòαÑç αñ«αÑçαñé αñ╕αñ░αÑìαñÜ αñæαñ¬αñ░αÑçαñ╢αñ¿αÑñ\n10:19\n10 minutes, 19 seconds\nαñ╕αñ╛αññ αñªαñ┐αñ¿ αñòαÑç αñ▓αñ┐αñÅ αñªαñ┐αñ▓αÑìαñ▓αÑÇ αñ¬αÑüαñ▓αñ┐αñ╕ αñ╣αñ┐αñ░αñ╛αñ╕αññ αñ«αÑçαñé αñÜαñ╛αñ░ αñ╕αñéαñªαñ┐αñùαÑìαñº αñåαññαñéαñòαñ╡αñ╛αñªαÑÇαÑñ αñàαñ¼ αññαñò αñåαñêαñÅαñ╕αñåαñê, αñ«αÑüαñéαñ¼αñê αñàαñéαñíαñ░αñ¼αñ░αÑì αñ¿αÑçαñƒαñ╡αñ░αÑìαñò αñ╕αÑç αñ£αÑüαñíαñ╝αÑç αñ╣αÑüαñÅ αñòαÑüαñ▓ αñåαñá αñ▓αÑïαñù αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñÅ αñùαñÅ αñ╣αÑêαñéαÑñ αñåαñ░αÑïαñ¬αñ┐αñ»αÑïαñé αñ╕αÑç\n10:27\n10 minutes, 27 seconds\nαñ╣αñÑαñ┐αñ»αñ╛αñ░, αñùαÑïαñ▓αñ╛ αñ¼αñ╛αñ░αÑéαñª αñöαñ░ αñ╡αñ┐αñ╕αÑìαñ½αÑïαñƒαñò αñ¼αñ░αñ╛αñ«αñª αñ╣αÑüαñå αñÑαÑçαÑñ\n10:33\n10 minutes, 33 seconds\nαñ╕αÑéαñ░αññ αñ«αÑçαñé αñæαñ¿αñ▓αñ╛αñçαñ¿ αñ▓αÑëαñƒαñ░αÑÇ αñòαÑç αñ¿αñ╛αñ« αñ¬αñ░ αñ¬αñ╛αñòαñ┐αñ╕αÑìαññαñ╛αñ¿ αñ╕αÑç αñ╣αÑï αñ░αñ╣αÑÇ αñºαÑïαñûαñ╛αñºαñíαñ╝αÑÇ αñòαñ╛ αñûαÑüαñ▓αñ╛αñ╕αñ╛ αñ╣αÑüαñåαÑñ αñ╕αÑéαñ░αññ αñ╕αñ╛αñçαñ¼αñ░ αñòαÑìαñ░αñ╛αñçαñ« αñ╕αÑçαñ▓ αñ¿αÑç αñàαñ╕αñ« αñ╕αÑç αñ¬αñòαñíαñ╝αÑç αñªαÑï αñåαñ░αÑïαñ¬αÑÇαÑñ αñàαñ╕αñ« αñòαÑç αñûαñ╛αññαÑç αñ«αÑçαñé αñƒαÑìαñ░αñ╛αñéαñ╕αñ½αñ░ αñ╣αÑüαñÅ αñÑαÑç αñ¬αÑêαñ╕αÑçαÑñ\n10:45\n10 minutes, 45 seconds\nαñùαÑìαñ░αÑçαñƒ αñ¿αÑïαñÅαñíαñ╛ αñ«αÑçαñé αñ«αñ┐αñ▓αñ╛ αñ¿αñ╛αñçαñ£αÑÇαñ░αñ┐αñ»αñ╛ αñòαÑç αñ¿αñ╛αñùαñ░αñ┐αñò αñòαñ╛ αñ╢αñ╡αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ╢αñ╡ αñòαÑï αñòαñ¼αÑìαñ£αÑç αñ«αÑçαñé αñ▓αÑçαñòαñ░ αñ¬αÑïαñ╕αÑìαñƒαñ«αñ╛αñ░αÑìαñƒαñ« αñòαÑç αñ▓αñ┐αñÅ αñ¡αÑçαñ£αñ╛αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ╣αñ░ αñÅαñéαñùαñ▓ αñ╕αÑç αñòαñ░ αñ░αñ╣αÑÇ αñ╣αÑê αñ£αñ╛αñéαñÜ αñ¬αñíαñ╝αññαñ╛αñ▓αÑñ\n10:55\n10 minutes, 55 seconds\nαñ¬αñéαñ£αñ╛αñ¼ αñòαÑç αñ▓αÑüαñºαñ┐αñ»αñ╛αñ¿αñ╛ αñ«αÑçαñé αñ¼αÑüαñ£αÑüαñ░αÑìαñù αñªαñéαñ¬αññαñ┐ αñòαÑÇ αñ╕αñéαñªαñ┐αñùαÑìαñº αñ«αÑîαññαÑñ αñÿαñ░ αñ╕αÑç αñ«αñ┐αñ▓αÑç αñªαÑïαñ¿αÑïαñé αñòαÑç αñ╢αñ╡αÑñ αñ╕αñ┐αñ░ αñ¬αñ░ αñÜαÑïαñƒ αñòαÑç αñ¿αñ┐αñ╢αñ╛αñ¿ αñ¡αÑÇ αñ╣αÑêαñéαÑñ αñ╣αññαÑìαñ»αñ╛ αñòαÑÇ αñåαñ╢αñéαñòαñ╛αÑñ\n11:14\n11 minutes, 14 seconds\nαñÅαñ¼αÑÇαñ¬αÑÇ αñ¿αÑìαñ»αÑéαñ£αñ╝ αñåαñ¬αñòαÑï αñ░αñûαÑç αñåαñùαÑçαÑñ	f	2026-05-31 18:34:54.680794
27	UCRWFSbif-RFENbBrSiez1DA	National	General	Transcript\nSearch transcript\n0:03\n3 seconds\nαñ»αÑéαñ¬αÑÇ αñòαÑç αñ«αÑüαñ░αñ╛αñªαñ╛αñ¼αñ╛αñª αñ«αÑçαñé αñÅαñò αñùαÑïαñªαñ╛αñ« αñ«αÑçαñé αñ▓αñùαÑÇ αñ¡αÑÇαñ╖αñú αñåαñùαÑñ αñ½αñ╛αñ»αñ░ αñ¼αÑìαñ░αñ┐αñùαÑçαñí αñ¿αÑç αñåαñù αñ¬αñ░ αñòαñ╛αñ¼αÑé αñ¬αñ╛αñ»αñ╛αÑñ αñ▓αñ╛αñûαÑïαñé αñòαñ╛ αñ╕αñ╛αñ«αñ╛αñ¿ αñ£αñ▓αñòαñ░ αñ░αñ╛αñû αñ╣αÑüαñåαÑñ αñåαñù αñ╕αÑç αñçαñ▓αñ╛αñòαÑç αñ«αÑçαñé αñàαñ½αñ░αñ╛αññαñ½αñ░αÑÇ αñòαñ╛ αñ«αñ╛αñ╣αÑîαñ▓ αñ¼αñ¿ αñùαñ»αñ╛αÑñ\n0:15\n15 seconds\nαñ«αÑüαñéαñ¼αñê αñ«αÑçαñé αñàαñ╡αÑêαñº αñ«αñ£αñ╛αñ░ αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñÅαñòαÑìαñ╢αñ¿αÑñ αñ¡αñ╛αñ░αÑÇ αñ╕αñéαñûαÑìαñ»αñ╛ αñ«αÑçαñé αñ¬αÑüαñ▓αñ┐αñ╕ αñ¼αñ▓ αñòαÑÇ αñ«αÑîαñ£αÑéαñªαñùαÑÇ αñ«αÑçαñé αññαÑïαñíαñ╝αÑÇ αñ£αñ╛ αñ░αñ╣αÑÇ αñùαÑïαñ░αÑçαñùαñ╛αñéαñ╡ αñ«αÑçαñé αñ¼αñ¿αÑÇ αñàαñ╡αÑêαñº αñ«αñ£αñ╛αñ░αÑñ\n0:22\n22 seconds\nαñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñ¿αÑçαññαñ╛ αñòαñ┐αñ░αÑÇαñƒ αñ╕αÑïαñ«αÑêαñ»αñ╛ αñ¿αÑç αñëαñáαñ╛αñ»αñ╛ αñÑαñ╛ αñ«αñ╛αñ«αñ▓αñ╛αÑñ\n0:29\n29 seconds\nαñªαñ┐αñ▓αÑìαñ▓αÑÇ αñòαÑç αñ«αÑüαñòαÑüαñéαñªαñ¬αÑüαñ░ αñçαñ▓αñ╛αñòαÑç αñ«αÑçαñé αñÅαñò αñ¼αñ┐αñ▓αÑìαñíαñ┐αñéαñù αñ«αÑçαñé αñ╕αñ┐αñ▓αÑçαñéαñíαñ░ αñ¼αÑìαñ▓αñ╛αñ╕αÑìαñƒ αñ╣αÑüαñåαÑñ αñ«αñ▓αñ╡αÑç αñ«αÑçαñé αñªαñ¼αÑç αñòαÑüαñ¢ αñ▓αÑïαñùαÑñ αñ½αñ╛αñ»αñ░ αñ¼αÑìαñ░αñ┐αñùαÑçαñí αñòαÑÇ αñƒαÑÇαñ« αñ¿αÑç αñ▓αÑïαñùαÑïαñé αñòαñ╛ αñ░αÑçαñ╕αÑìαñòαÑìαñ»αÑé αñòαñ┐αñ»αñ╛αÑñ\n0:39\n39 seconds\nαñªαñ┐αñ▓αÑìαñ▓αÑÇ αñòαÑç αñ¿αÑìαñ»αÑé αñëαñ╕αÑìαñ«αñ╛αñ¿αñ¬αÑüαñ░ αñ«αÑçαñé 17 αñ╕αñ╛αñ▓ αñòαÑç αñ▓αñíαñ╝αñòαÑç αñòαÑÇ αñÜαñ╛αñòαÑé αñ«αñ╛αñ░αñòαñ░ αñ╣αññαÑìαñ»αñ╛αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αññαÑÇαñ¿ αñåαñ░αÑïαñ¬αñ┐αñ»αÑïαñé αñòαÑï αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛αÑñ αñ╕αÑÇαñ╕αÑÇαñƒαÑÇαñ╡αÑÇ αñ«αÑçαñé αñòαÑêαñª αñ╣αÑê αñ╡αñ╛αñ░αñªαñ╛αññαÑñ\n0:50\n50 seconds\nαñëαññαÑìαññαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñ¼αñ╛αñùαñ¬αññ αñ«αÑçαñé αñ»αÑüαñ╡αñò αñ¬αñ░ αññαñ▓αñ╡αñ╛αñ░ αñ╕αÑç αñ╣αñ«αñ▓αñ╛αÑñ αñ╣αñ«αñ▓αÑç αñòαñ╛ αñ╕αÑÇαñ╕αÑÇαñƒαÑÇαñ╡αÑÇ αñ╡αÑÇαñíαñ┐αñ»αÑï αñåαñ»αñ╛ αñ╣αÑê αñ╕αñ╛αñ«αñ¿αÑçαÑñ αñ«αÑçαñé αñ╣αñ«αñ▓αñ╛αñ╡αñ░ αñ«αÑîαñòαÑç αñ╕αÑç αñ½αñ░αñ╛αñ░ αñ╣αÑüαñåαÑñ\n0:56\n56 seconds\nαñ«αñ╛αñ«αñ▓αÑç αñòαÑÇ αñ£αñ╛αñéαñÜ αñ¬αñíαñ╝αññαñ╛αñ▓ αñ«αÑçαñé αñ£αÑüαñƒαÑÇ αñ╣αÑê αñ¬αÑüαñ▓αñ┐αñ╕αÑñ\n1:03\n1 minute, 3 seconds\nαñªαñ┐αñ▓αÑìαñ▓αÑÇ αñòαÑç αñªαÑìαñ╡αñ╛αñ░αñòαñ╛ αñ«αÑçαñé αñùαÑïαñ▓αÑÇαñ¼αñ╛αñ░αÑÇ αñ╕αÑç αñçαñ▓αñ╛αñòαÑç αñ«αÑçαñé αñªαñ╣αñ╢αññ αñ½αÑêαñ▓ αñùαñêαÑñ αñ«αñ╣αñ╛αñ╡αÑÇαñ░ αñ¼αñ┐αñ▓αÑìαñíαñ░ αñòαÑç αñÿαñ░ αñòαÑç αñ¼αñ╛αñ╣αñ░ αñåαñá αñ╕αñ╛αñëαñéαñí αñ½αñ╛αñ»αñ░αñ┐αñéαñù αñ╣αÑüαñêαÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñòαÑï αñåαñ░αÑïαñ¬αñ┐αñ»αÑïαñé αñòαÑÇ αññαñ▓αñ╛αñ╢ αñ╣αÑêαÑñ αñ░αñéαñùαñªαñ╛αñ░αÑÇ αñ«αñ╛αñéαñùαñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ αñåαñÅ αñÑαÑç αñåαñ░αÑïαñ¬αÑÇαÑñ\n1:15\n1 minute, 15 seconds\nαñëαññαÑìαññαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñåαñùαñ░αñ╛ αñ«αÑçαñé αñ«αñ╛αñ¿αñ╕αÑéαñ¿ αñ╕αÑç αñ¬αñ╣αñ▓αÑç αñ£αñ▓ αñ¿αñ┐αñùαñ« αñòαÑÇ αñ¬αÑïαñ▓ αñûαÑüαñ▓αÑÇαÑñ αñ¼αñ╛αñ░αñ┐αñ╢ αñòαÑç αñ¼αñ╛αñª αñ╕αÑÇαñ╡αñ░ αñ▓αñ╛αñçαñ¿ αñ¬αÑìαñ░αÑïαñ£αÑçαñòαÑìαñƒ αñ╕αÑç αñºαñ╕αÑÇ αñòαñ░αÑÇαñ¼ 15 αñ½αÑÇαñƒ αñ╕αñíαñ╝αñòαÑñ\n1:22\n1 minute, 22 seconds\nαñÅαñò αñêαñéαñƒαÑïαñé αñ╕αÑç αñ▓αñªαÑÇ αñ╣αÑüαñê αñƒαÑìαñ░αÑêαñòαÑìαñƒαñ░ αñƒαÑìαñ░αÑëαñ▓αÑÇ αñùαñíαÑìαñóαÑç αñ«αÑçαñé αñ£αñùαÑÇαÑñ\n1:30\n1 minute, 30 seconds\nαñ«αñ╣αñ╛αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░ αñòαÑç αñåαñ░αÑìαñ»αñ¿ αñ¿αñùαñ░ αñ«αÑçαñé αñ¬αñ╛αñ░αÑìαñò αñ«αÑçαñé αñ¿αñ«αñ╛αñ£ αñ¬αñóαñ╝αñ¿αÑç αñòαñ╛ αñ╡αÑÇαñíαñ┐αñ»αÑï αñ╡αñ╛αñ»αñ░αñ▓ αñ╣αÑï αñ░αñ╣αñ╛ αñ╣αÑêαÑñ\n1:33\n1 minute, 33 seconds\nαñ╣αñ┐αñéαñªαÑé αñ╕αñéαñùαñáαñ¿αÑïαñé αñ¿αÑç αñ¬αñ╛αñ░αÑìαñò αñ«αÑçαñé αñ╣αñ¿αÑüαñ«αñ╛αñ¿ αñÜαñ╛αñ▓αÑÇαñ╕αñ╛ αñòαñ╛ αñ¬αñ╛αñá αñòαñ░ αñ╢αÑüαñªαÑìαñºαñ┐αñòαñ░αñú αñòαñ┐αñ»αñ╛αÑñ αñòαñ╛αñ░αñ╡αñ╛αñê αñòαÑÇ αñ«αñ╛αñéαñù αñëαñáαñ╛αñêαÑñ\n1:41\n1 minute, 41 seconds\nαñëαññαÑìαññαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñòαñ╛αñ¿αñ¬αÑüαñ░ αñ«αÑçαñé αñàαñéαñùαÑìαñ░αÑçαñ£αÑïαñé αñòαÑç αñ£αñ«αñ╛αñ¿αÑç αñ«αÑçαñé αñ¼αñ¿αñ╛ αñ╣αÑüαñå αñ£αñ£αñ░ αñ¬αÑüαñ▓αÑñ αñ¬αñ╛αñ¿αÑÇ αñòαÑç αññαÑçαñ£ αñ¼αñ╣αñ╛αñ╡ αñ«αÑçαñé αñóαñ╣αñ╛αÑñ αñªαÑï αñ╣αñ┐αñ╕αÑìαñ╕αÑïαñé αñ«αÑçαñé αñ¼αñÜαñ╛ αñ¬αÑüαñ▓αÑñ\n1:48\n1 minute, 48 seconds\nαñ¿αñ┐αñ░αÑìαñ«αñ╛αñúαñ╛αñºαÑÇαñ¿ αñ¬αÑüαñ▓ αñ╕αÑç αñ╢αÑüαñ░αÑé αñ╣αÑüαñê αñåαñ╡αñ╛αñ£αñ╛αñ╣αÑÇαÑñ\n1:52\n1 minute, 52 seconds\nαñ¼αñéαñùαñ╛αñ▓ αñ«αÑçαñé αñ«αñ«αññαñ╛ αñòαÑÇ αñ¬αñ╛αñ░αÑìαñƒαÑÇ αñ«αÑçαñé αñƒαÑéαñƒ αñòαñ╛ αñûαññαñ░αñ╛ αñ¼αñóαñ╝αñ╛αÑñ αñ¿αñ┐αñ╖αÑìαñòαñ╛αñ╕αñ┐αññ αñ╡αñ┐αñºαñ╛αñ»αñòαÑïαñé αñ╕αÑç αñ«αñ┐αñ▓αÑç αñ¬αñ╛αñ░αÑìαñƒαÑÇ αñòαÑç αñ¢αñ╣ αñÅαñ«αñÅαñ▓αñÅαÑñ αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ«αÑçαñé αñƒαÑéαñƒ αñòαÑÇ αñàαñƒαñòαñ¿αÑïαñé αñ¬αñ░αÑñ αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñ¿αÑç αñòαñ╣αñ╛ αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ╡αñ╛αñ▓αÑïαñé αñòαÑç αñ▓αñ┐αñÅ αñªαñ░αñ╡αñ╛αñ£αÑç αñ¼αñéαñªαÑñ\n2:04\n2 minutes, 4 seconds\nαñ¬αñ╢αÑìαñÜαñ┐αñ« αñ¼αñéαñùαñ╛αñ▓ αñòαÑç 24 αñëαññαÑìαññαñ░ αñ¬αñ░αñùαñ¿αñ╛ αñ╕αÑç αñÅαñò αñöαñ░ αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ¿αÑçαññαñ╛ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░αÑñ αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ¬αñ╛αñ░αÑìαñ╖αñª αñ¬αñ░ αñ£αñ¼αñ░αñ¿ αñ╡αñ╕αÑéαñ▓αÑÇ αñöαñ░ αñºαñ«αñòαÑÇ αñªαÑçαñ¿αÑç αñòαñ╛ αñåαñ░αÑïαñ¬ αñ╣αÑêαÑñ\n2:11\n2 minutes, 11 seconds\nαñ▓αÑïαñùαÑïαñé αñ¿αÑç αñ▓αñùαñ╛αñÅ αñÜαÑïαñ░ αñÜαÑïαñ░ αñòαÑç αñ¿αñ╛αñ░αÑçαÑñ αñÿαñ░ αñ«αÑçαñé αññαÑïαñíαñ╝αñ½αÑïαñíαñ╝ αñ¡αÑÇ αñòαÑÇαÑñ\n2:16\n2 minutes, 16 seconds\nαñ¬αñ╢αÑìαñÜαñ┐αñ« αñ¼αñéαñùαñ╛αñ▓ αñòαÑç αñ╕αñ┐αñùαÑìαñ¿αÑçαñÜαñ░ αñÿαÑïαñƒαñ╛αñ▓αñ╛ αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñ╕αÑÇαñåαñêαñíαÑÇ αñòαÑÇ αñ£αñ╛αñéαñÜ αññαÑçαñ£ αñ╣αÑï αñùαñê αñ╣αÑêαÑñ αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñòαÑç 13 αñ╡αñ┐αñºαñ╛αñ»αñòαÑïαñé αñòαÑç αñ¼αñ»αñ╛αñ¿ αñªαñ░αÑìαñ£ αñòαñ┐αñÅ αñùαñÅαÑñ\n2:23\n2 minutes, 23 seconds\nαñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ¬αñ░ αñ½αñ░αÑìαñ£αÑÇ αñªαñ╕αÑìαññαñûαññ αñòαÑÇ αñÜαñ┐αñƒαÑìαñáαÑÇ αñ¡αÑçαñ£αñ¿αÑç αñòαñ╛ αñåαñ░αÑïαñ¬ αñ╣αÑêαÑñ αñàαñ¡αñ┐αñ╖αÑçαñò αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñòαÑï αñ╕αÑÇαñåαñêαñíαÑÇ αñ¿αÑç αññαñ▓αñ¼ αñòαñ┐αñ»αñ╛αÑñ\n2:31\n2 minutes, 31 seconds\nαñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñ¢αÑïαñíαñ╝αñ¿αÑç αñòαÑÇ αñàαñƒαñòαñ▓αÑïαñé αñòαÑç αñ¼αÑÇαñÜ αñ¼αÑÇαñÅαñ▓ αñ╕αñéαññαÑïαñ╖αÑïαñé αñ╕αÑç αñ«αñ┐αñ▓αÑç αññαñ«αñ┐αñ▓αñ¿αñ╛αñíαÑü αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñòαÑç αñ¬αÑéαñ░αÑìαñ╡ αñàαñºαÑìαñ»αñòαÑìαñ╖ αñòαÑç αñàαñ¿αÑìαñ¿αñ╛αñ«αñ▓αñ╛αñêαÑñ αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñ«αÑüαñûαÑìαñ»αñ╛αñ▓αñ» αñ«αÑçαñé αñëαñ¿αñòαÑÇ αñ«αÑüαñ▓αñ╛αñòαñ╛αññ αñ╣αÑüαñêαÑñ\n2:41\n2 minutes, 41 seconds\nαñ¼αñ┐αñ╣αñ╛αñ░ αñ«αÑçαñé αñ╕αñ░αñòαñ╛αñ░ αñ╕αÑç αñàαñ¿αÑüαñªαñ╛αñ¿ αñ¬αñ╛αñ¿αÑç αñ╡αñ╛αñ▓αÑç αñ«αñªαñ░αñ╕αÑïαñé αñòαÑç αñòαñ╛αñ«αñòαñ╛αñ£ αñòαÑÇ αñ£αñ╛αñéαñÜ αñ╣αÑïαñùαÑÇαÑñ αñ╕αñ«αÑìαñ░αñ╛αñƒ αñ╕αñ░αñòαñ╛αñ░ αñ¿αÑç αñ£αñ┐αñ▓αñ╛ αñ╢αñ┐αñòαÑìαñ╖αñ╛ αñ¬αñªαñ╛αñºαñ┐αñòαñ╛αñ░αñ┐αñ»αÑïαñé αñòαÑï αñ¿αñ┐αñ░αÑìαñªαÑçαñ╢ αñªαñ┐αñ»αñ╛αÑñ\n2:50\n2 minutes, 50 seconds\nαñ╕αÑüαñ¬αÑìαñ░αÑÇαñ« αñòαÑïαñ░αÑìαñƒ αñòαÑï αñ«αñ┐αñ▓αÑç αñ╣αÑêαñé αñ¬αñ╛αñéαñÜ αñ¿αñÅ αñ£αñ£αÑñ\n2:53\n2 minutes, 53 seconds\nαñ╕αÑüαñ¬αÑìαñ░αÑÇαñ« αñòαÑïαñ░αÑìαñƒ αñ«αÑçαñé αñ£αñ£αÑçαñ╕ αñòαÑÇ αñ╕αñéαñûαÑìαñ»αñ╛ αñàαñ¼ 37 αñ╣αÑï αñùαñê αñ╣αÑêαÑñ αñ£αñ╕αÑìαñƒαñ┐αñ╕ αñ╢αÑÇαñ▓ αñ¿αñ╛αñùαÑé, αñ£αñ╕αÑìαñƒαñ┐αñ╕ αñÜαñéαñªαÑìαñ░αñ╢αÑçαñûαñ░, αñ£αñ╕αÑìαñƒαñ┐αñ╕ αñ╕αñéαñ£αÑÇαñ╡ αñ╕αñÜαñªαÑçαñ╡, αñ£αñ╕αÑìαñƒαñ┐αñ╕\n3:00\n3 minutes\nαñàαñ░αÑüαñú αñ¬αñ▓αÑìαñ▓αÑÇ αñöαñ░ αñ╡αÑÇ αñ«αÑïαñ╣αñ¿αñ╛ αñòαÑï αñÜαÑÇαñ½ αñ£αñ╕αÑìαñƒαñ┐αñ╕ αñ╕αÑéαñ░αÑìαñ»αñòαñ╛αñéαññ αñ¿αÑç αñ╢αñ¬αñÑ αñùαÑìαñ░αñ╣αñú αñòαñ░αñ╛αñêαÑñ\n3:06\n3 minutes, 6 seconds\nαñ▓αñéαñ¼αÑç αñçαñéαññαñ£αñ╛αñ░ αñòαÑç αñ¼αñ╛αñª αñ╕αÑÇαñ¼αÑÇαñÅαñ╕αñê αñòαñ╛ αñ¬αÑïαñ░αÑìαñƒαñ▓ 2 αñ£αÑéαñ¿ αñ»αñ╛αñ¿αÑÇ αñòαñ┐ αñåαñ£ αñ╕αÑüαñ¼αñ╣ αñ╕αÑç αñ╢αÑüαñ░αÑé αñ╣αÑï αñùαñ»αñ╛ αñ╣αÑêαÑñ\n3:11\n3 minutes, 11 seconds\nαñ╕αÑÇαñ¼αÑÇαñÅαñ╕αñê αñ¿αÑç αñòαñ╣αñ╛ αñàαñ¼ αñáαÑÇαñò αñ╕αÑç αñòαñ╛αñ« αñòαñ░ αñ░αñ╣αñ╛ αñ╣αÑê αñ¬αÑïαñ░αÑìαñƒαñ▓αÑñ αñ¢αñ╛αññαÑìαñ░ αñåαñ╕αñ╛αñ¿αÑÇ αñ╕αÑç αñåαñ╡αÑçαñªαñ¿ αñòαñ░ αñ╕αñòαññαÑç αñ╣αÑêαñéαÑñ\n3:18\n3 minutes, 18 seconds\nαñ«αñ╣αñ╛αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░ αñòαÑç αñ¼αÑÇαñíαñ╝ αñ«αÑçαñé αñ¿αÑÇαñƒ αñ¬αÑçαñ¬αñ░ αñ▓αÑÇαñò αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñåαñ░αÑïαñ¬αÑÇ αñ¬αÑÇαñ╡αÑÇ αñòαÑüαñ▓αñòαñ░αÑìαñúαÑÇ αñòαÑç αñ¿αñ┐αñ░αÑìαñ«αñ╛αñúαñ╛αñºαÑÇαñ¿ αñ¼αñéαñùαñ¿αÑç αñ¬αñ░ αñ¼αÑüαñ▓αñíαÑïαñ£αñ░ αñÜαñ▓αñ╛αÑñ αñÅαñò αñ╣αñ½αÑìαññαÑç αñ¬αñ╣αñ▓αÑç αñ¿αÑïαñƒαñ┐αñ╕ αñªαÑçαñòαñ░ αñ░αÑüαñòαñ╡αñ╛αñ»αñ╛ αñùαñ»αñ╛ αñÑαñ╛\n3:25\n3 minutes, 25 seconds\nαñ¿αñ┐αñ░αÑìαñ«αñ╛αñú αñòαñ╛αñ░αÑìαñ»αÑñ αñòαÑüαñ▓αñòαñ░αÑìαñúαÑÇ αñ¬αñ░ αñàαñ╡αÑêαñº αñ¿αñ┐αñ░αÑìαñ«αñ╛αñú αñòαñ░αñ╛αñ¿αÑç αñòαñ╛ αñåαñ░αÑïαñ¬ αñ╣αÑêαÑñ\n3:31\n3 minutes, 31 seconds\nαñ¿αÑÇαñƒ, αñ╕αÑÇαñ¼αÑÇαñÅαñ╕αñê αñöαñ░ αñªαÑéαñ╕αñ░αÑÇ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛αñôαñé αñ«αÑçαñé αñùαñíαñ╝αñ¼αñíαñ╝αÑÇ αñòαñ╛ αñ╡αñ┐αñ░αÑïαñº αñ╣αÑï αñ░αñ╣αñ╛ αñ╣αÑêαÑñ αñ╢αñ┐αñòαÑìαñ╖αñ╛ αñ«αñéαññαÑìαñ░αñ╛αñ▓αñ» αñòαÑç αñ¼αñ╛αñ╣αñ░ αñæαñ▓ αñçαñéαñíαñ┐αñ»αñ╛ αñ╕αÑìαñƒαÑéαñíαÑçαñéαñƒαÑìαñ╕ αñÅαñ╕αÑïαñ╕αñ┐αñÅαñ╢αñ¿ αñ¿αÑç αñ¬αÑìαñ░αñªαñ░αÑìαñ╢αñ¿ αñòαñ┐αñ»αñ╛αÑñ αñ«αñ╛αñéαñùαñ╛ αñòαÑçαñéαñªαÑìαñ░αÑÇαñ» αñ╢αñ┐αñòαÑìαñ╖αñ╛ αñ«αñéαññαÑìαñ░αÑÇ αñºαñ░αÑìαñ«αÑçαñéαñªαÑìαñ░ αñ¬αÑìαñ░αñºαñ╛αñ¿ αñòαñ╛ αñçαñ╕αÑìαññαÑÇαñ½αñ╛αÑñ\n3:44\n3 minutes, 44 seconds\nαñ¬αÑìαñ░αñ»αñ╛αñùαñ░αñ╛αñ£ αñ¬αÑçαñ¬αñ░ αñ▓αÑÇαñò αñòαÑç αñ«αÑüαñªαÑìαñªαÑç αñ¬αñ░ αñ╕αñéαñ£αñ» αñ╕αñ┐αñéαñ╣ αñÅαñíαÑÇαñÅαñ« αñ╕αñ┐αñƒαÑÇ αñ╕αÑç αñ¡αñ┐αñíαñ╝ αñùαñÅαÑñ αññαÑÇαñûαÑÇ αñ¿αÑïαñòαñ¥αÑïαñéαñò αñ╣αÑüαñêαÑñ αñ«αÑÇαñƒαñ┐αñéαñù αñòαÑï αñ░αÑïαñòαñ¿αÑç αñ¬αñ░ αñòαñ╣αñ╛ αñ╕αñ░αÑìαñòαñ┐αñƒ αñ╣αñ╛αñëαñ╕ αñ«αÑÇαñƒαñ┐αñéαñù αñòαÑç αñ▓αñ┐αñÅ αñçαñ£αñ╛αñ£αññ αñòαÑÇ αñòαÑïαñê αñ£αñ░αÑéαñ░αññ αñ¿αñ╣αÑÇαñéαÑñ\n3:57\n3 minutes, 57 seconds\n5 αñ╕αÑç 21 αñ£αÑéαñ¿ αññαñò αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñªαÑçαñ╢ αñ¡αñ░ αñ«αÑçαñé αñÜαñ▓αñ╛αñÅαñùαÑÇ αñàαñ¡αñ┐αñ»αñ╛αñ¿αÑñ αñ╕αÑéαññαÑìαñ░αÑïαñé αñòαÑç αñàαñ¿αÑüαñ╕αñ╛αñ░ αñùαñ╛αñéαñ╡ αñòαñ╛ αñªαÑîαñ░αñ╛ αñòαñ░αÑçαñéαñùαÑç αñ╕αñ╛αñéαñ╕αñª, αñ╡αñ┐αñºαñ╛αñ»αñò αñöαñ░ αñ«αñéαññαÑìαñ░αÑÇαÑñ 12 αñ╕αñ╛αñ▓ αñ«αÑçαñé αñ£αñ¿αñ╣αñ┐αññ αñ«αÑçαñé αñ▓αñ┐αñÅ αñùαñÅ αñ½αÑêαñ╕αñ▓αÑïαñé αñòαÑÇ αñªαÑçαñéαñùαÑç αñ£αñ╛αñ¿αñòαñ╛αñ░αÑÇαÑñ\n4:08\n4 minutes, 8 seconds\nαñùαñ╛αñ» αñòαÑï αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αÑÇαñ» αñ¬αñ╢αÑü αñÿαÑïαñ╖αñ┐αññ αñòαñ░αñ¿αÑç αñòαÑÇ αñ«αñ╛αñéαñù αñòαñ░ αñ░αñ╣αÑç αñ«αÑîαñ▓αñ╛αñ¿αñ╛αñôαñé αñ¬αñ░ αñ¼αñ░αñ╕αÑç αñ╕αÑÇαñÅαñ« αñ»αÑïαñùαÑÇ αñòαñ╣αñ╛ αñùαÑî αñ╣αñ«αñ╛αñ░αÑÇ αñ«αñ╛αññαñ╛ αñ╣αÑêαÑñ αñ£αñ¿αÑìαñ« αñ£αñ¿αÑìαñ«αñ╛αñéαññαñ░ αñòαñ╛ αñ¿αñ╛αññαñ╛ αñ╣αÑêαÑñ\n4:16\n4 minutes, 16 seconds\nαñòαÑìαñ»αñ╛ αñ╣αÑê αñ«αñ╛αñé αñöαñ░ αñ¬αÑüαññαÑìαñ░ αñòαÑç αñ¼αÑÇαñÜ αñòαÑüαñ¢ αñÿαÑïαñ╖αñ┐αññ αñòαñ░αñ¿αÑç αñòαÑÇ αñ£αñ░αÑéαñ░αññ αñ¿αñ╣αÑÇαñéαÑñ\n4:22\n4 minutes, 22 seconds\nαñùαÑî αñ«αñ╛αññαñ╛ αñòαÑç αñ«αÑüαñªαÑìαñªαÑç αñ¬αñ░ αñ╕αñ«αñ╛αñ£αñ╡αñ╛αñªαÑÇ αñ¬αñ╛αñ░αÑìαñƒαÑÇ αñ¿αÑç αñ╕αÑÇαñÅαñ« αñ»αÑïαñùαÑÇ αñòαÑï αñÿαÑçαñ░αñ╛αÑñ αñòαñ╣αñ╛ αñòαñ┐ αñ╡αÑïαñƒ αñòαÑç αñ▓αñ┐αñÅ αñùαñ╛αñ» αñòαÑï αñ«αÑüαñªαÑìαñªαñ╛ αñ¼αñ¿αñ╛αñ»αñ╛ αñùαñ»αñ╛αÑñ αñ«αÑüαñûαÑìαñ»αñ«αñéαññαÑìαñ░αÑÇ αñ£αÑÇ αñ»αñ╣ αñ¼αññαñ╛αñÅαñé αñòαñ┐ αñ¬αÑìαñ░αñªαÑçαñ╢ αñ«αÑçαñé αñòαñ¼ αñ░αÑüαñòαÑçαñùαÑÇ αñùαÑî αññαñ╕αÑìαñòαñ░αÑÇ?\n4:36\n4 minutes, 36 seconds\nαñùαñ╛αñ» αñòαÑç αñ«αÑüαñªαÑìαñªαÑç αñ¬αñ░ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñòαñ╛ αñ╣αñ«αñ▓αñ╛αÑñ αñòαñ╣αñ╛ αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñ¿αñ╣αÑÇαñé αñÿαÑïαñ╖αñ┐αññ αñòαñ░ αñ╕αñòαññαÑÇ αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αÑÇαñ» αñ¬αñ╢αÑü αñòαÑìαñ»αÑïαñéαñòαñ┐ αñûαññαÑìαñ« αñ╣αÑï αñ£αñ╛αñÅαñùαÑÇαÑñ αñëαñ¿αñòαÑÇ αñ░αñ╛αñ£αñ¿αÑÇαññαñ┐ αñªαÑüαñ░αÑìαñ¡αñ╛αñùαÑìαñ» αñ╣αÑê αñòαñ┐ αñ╕αñéαñ╡αñ┐αñºαñ╛αñ¿ αñòαÑÇ αñ╢αñ¬αñÑ αñ▓αÑçαñ¿αÑç αñ╡αñ╛αñ▓αÑç αñ╕αÑÇαñÅαñ« αñ╢αñ╕αÑìαññαÑìαñ░ αñëαñáαñ╛αñ¿αÑç αñòαÑÇ αñ¼αñ╛αññ αñòαñ░αññαÑç αñ╣αÑêαñéαÑñ\n4:49\n4 minutes, 49 seconds\nαñ╢αñ┐αñ░αÑïαñ«αñúαñ┐ αñàαñòαñ╛αñ▓αÑÇ αñªαñ▓ αñòαÑç αñ¿αÑçαññαñ╛ αñ╡αñ┐αñòαÑìαñ░αñ« αñ╕αñ┐αñéαñ╣ αñ«αñ£αÑÇαñáαñ┐αñ»αñ╛ αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñ¬αñéαñ£αñ╛αñ¼ αñ¬αÑüαñ▓αñ┐αñ╕ αñòαñ╛ αñ▓αÑëαñòαñåαñë αñ╕αñ░αÑìαñòαÑüαñ▓αñ░αÑñ αñàαñ¼ αñªαÑçαñ╢ αñ¢αÑïαñíαñ╝αñòαñ░ αñ¿αñ╣αÑÇαñé αñ£αñ╛ αñ╕αñòαÑçαñéαñùαÑç αñ«αñ£αÑÇαñáαñ┐αñ»αñ╛αÑñ αñÑαñ╛αñ¿αñ╛ αñ¬αñ░αñ┐αñ╕αñ░ αñ«αÑçαñé αñ╣αÑüαñê αñÿαñƒαñ¿αñ╛ αñòαÑç αñ¼αñ╛αñª αñ╕αÑç αñ«αñ£αÑÇαñáαñ┐αñ»αñ╛ αñ½αñ░αñ╛αñ░ αñ╣αÑêαñéαÑñ\n5:01\n5 minutes, 1 second\nαñ¬αÑÇαñÅαñ« αñ«αÑïαñªαÑÇ αñ╕αÑç αñ«αñ┐αñ▓αÑç αñ«αÑìαñ»αñ╛αñéαñ«αñ╛αñ░ αñòαÑç αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ¬αññαñ┐αÑñ αñ¼αÑêαñáαñò αñòαÑç αñªαÑîαñ░αñ╛αñ¿ αñòαñ╣αñ╛ αñòαñ┐ αñ¿αñ╣αÑÇαñé αñ╣αÑïαñ¿αÑç αñªαÑçαñéαñùαÑç αñ¡αñ╛αñ░αññ αñòαÑç αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñ╣αñ┐αññαÑïαñé αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñ«αÑìαñ»αñ╛αñéαñ«αñ╛αñ░ αñòαÑç αñçαñ▓αñ╛αñòαÑç αñòαñ╛ αñçαñ╕αÑìαññαÑçαñ«αñ╛αñ▓αÑñ\n5:12\n5 minutes, 12 seconds\nαñ«αÑìαñ»αñ╛αñéαñ«αñ╛αñ░ αñòαÑç αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ¬αññαñ┐, αñ¬αñ╛αñéαñÜ αñòαÑêαñ¼αñ┐αñ¿αÑçαñƒ αñ«αñéαññαÑìαñ░αÑÇ αñöαñ░ αñëαñÜαÑìαñÜ αñ╕αÑìαññαñ░αÑÇαñ» αñ¬αÑìαñ░αññαñ┐αñ¿αñ┐αñºαñ┐αñ«αñéαñíαñ▓ αñòαñ╛ αñ¡αñ╛αñ░αññ αñªαÑîαñ░αñ╛αÑñ αñ╡αñ┐αñªαÑçαñ╢ αñ«αñéαññαÑìαñ░αñ╛αñ▓αñ» αñòαÑç αñ«αÑüαññαñ╛αñ¼αñ┐αñò αñªαÑìαñ╡αñ┐αñ¬αñòαÑìαñ╖αÑÇαñ» αñ«αÑüαñªαÑìαñªαÑïαñé αñ¬αñ░ αñ╡αñ┐αñ╕αÑìαññαñ╛αñ░ αñ╕αÑç αñ╣αÑüαñê αñ╣αÑê αñÜαñ░αÑìαñÜαñ╛αÑñ αñ╕αñéαñ¬αñ░αÑìαñò αñ¼αñóαñ╝αñ╛αñ¿αÑç αñ¬αñ░ αñ£αÑïαñ░ αñªαñ┐αñ»αñ╛ αñùαñ»αñ╛αÑñ\n5:24\n5 minutes, 24 seconds\nαñëαññαÑìαññαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñ«αñéαññαÑìαñ░αÑÇ αñ£αÑçαñ¬αÑÇαñÅαñ╕ αñ░αñ╛αñáαÑîαñ░ αñòαÑÇ αñàαñ¬αñ░αñ╛αñºαñ┐αñ»αÑïαñé αñòαÑï αñÜαÑçαññαñ╛αñ╡αñ¿αÑÇαÑñ αñòαñ╣αñ╛ αñÅαñ¿αñòαñ╛αñëαñéαñƒαñ░ αñ╕αÑç αñ¼αñÜαñ¿αñ╛ αñ╣αÑê αññαÑï αñòαñ░ αñªαÑçαñé αñ╕αñ░αÑçαñéαñíαñ░αÑñ αñ«αÑüαñáαñ¡αÑçαñíαñ╝ αñ«αÑçαñé αñ¬αÑüαñ▓αñ┐αñ╕αñòαñ░αÑìαñ«αÑÇ αñ¡αÑÇ αñÿαñ╛αñ»αñ▓ αñ╣αÑïαññαÑç αñ╣αÑêαñéαÑñ\n5:35\n5 minutes, 35 seconds\nαñëαññαÑìαññαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñ¼αñ┐αñ£αñ▓αÑÇ αñëαñ¬αñ¡αÑïαñòαÑìαññαñ╛αñôαñé αñòαÑï 10 αñêαñéαñºαñ¿ αñ╕αñ░αÑìαñÜ αñ╕αÑç αñ«αÑüαñòαÑìαññαñ┐ αñ«αñ┐αñ▓αÑÇαÑñ αñ╡αñ┐αñªαÑìαñ»αÑüαññ αñ¿αñ┐αñ»αñ╛αñ«αñò αñåαñ»αÑïαñù αñ¿αÑç αñ»αÑéαñ¬αÑÇαñ¬αÑÇαñ╕αÑÇαñÅαñ▓ αñòαÑç αñ½αÑêαñ╕αñ▓αÑç αñ¬αñ░ αñ╕αñ╡αñ╛αñ▓\n5:42\n5 minutes, 42 seconds\nαñëαñáαñ╛αñ»αñ╛αÑñ 10% αñàαñºαñ┐αñ¡αñ╛αñ░ αñ¼αñóαñ╝αñ╛αñ¿αÑç αñòαÑï αñ¼αññαñ╛αñ»αñ╛ αñùαÑêαñ░αñòαñ╛αñ¿αÑéαñ¿αÑÇαÑñ\n5:50\n5 minutes, 50 seconds\nαñ£αñ«αÑìαñ«αÑé αñòαñ╢αÑìαñ«αÑÇαñ░ αñòαÑç αñ░αñ╛αñ£αÑîαñ░αÑÇ αñ«αÑçαñé αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñ¼αñ▓αÑïαñé αñòαñ╛ αñåαññαñéαñòαñ╡αñ╛αñª αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñæαñ¬αñ░αÑçαñ╢αñ¿αÑñ αñ╢αÑçαñ░αñ╡αñ╛αñ▓αÑÇ αñ£αñ╛αñ░αÑÇ αñ╣αÑêαÑñ αñ£αñéαñùαñ▓αÑÇ αñçαñ▓αñ╛αñòαÑïαñé αñ«αÑçαñé αñåαññαñéαñòαñ┐αñ»αÑïαñé αñòαÑÇ αññαñ▓αñ╛αñ╢ αññαÑçαñ£ αñòαÑÇ αñùαñêαÑñ αñÜαñ¬αÑìαñ¬αÑç-αñÜαñ¬αÑìαñ¬αÑç αñ¬αñ░ αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñ¼αñ▓αÑïαñé αñòαÑÇ αññαÑêαñ¿αñ╛αññαÑÇ αñ╣αÑêαÑñ\n6:03\n6 minutes, 3 seconds\nαñëαññαÑìαññαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñòαñ╛αñ¿αñ¬αÑüαñ░ αñ«αÑçαñé αñ╕αÑïαñ╢αñ▓ αñ«αÑÇαñíαñ┐αñ»αñ╛ αñçαñ¿αÑìαñ½αÑìαñ▓αÑüαñÅαñéαñ╕αñ░αñ░ αñ«αñ╛αñ¿αñ╕αÑÇ αñòαÑÇ αñ«αÑîαññ αñòαñ╛ αñ«αñ╛αñ«αñ▓αñ╛αÑñ\n6:07\n6 minutes, 7 seconds\nαñ¿αÑìαñ»αñ╛αñ» αñòαÑÇ αñ«αñ╛αñéαñù αñòαÑï αñ▓αÑçαñòαñ░ αñ¬αñ░αñ┐αñ╡αñ╛αñ░ αñöαñ░ αñ¬αñ░αñ┐αñ£αñ¿αÑïαñé αñòαñ╛ αñ¬αÑìαñ░αñªαñ░αÑìαñ╢αñ¿ αñ╣αÑüαñåαÑñ\n6:12\n6 minutes, 12 seconds\nαñùαñ╛αñ£αñ┐αñ»αñ╛αñ¼αñ╛αñª αñòαÑÇ αñÅαñò αñ«αñ▓αÑìαñƒαÑÇ αñ╕αÑìαñƒαÑïαñ░αÑÇ αñ¼αñ┐αñ▓αÑìαñíαñ┐αñéαñù αñ«αÑçαñé αñåαñù αñ▓αñùαÑÇαÑñ αñ▓αÑïαñùαÑïαñé αñòαÑï αñ╕αÑÇαñóαñ╝αñ┐αñ»αÑïαñé αñòαÑç αñ╕αñ╣αñ╛αñ░αÑç αñ¿αñ┐αñòαñ╛αñ▓αñ╛ αñùαñ»αñ╛ αñ¼αñ╛αñ╣αñ░αÑñ αñåαñù αñ¬αñ░ αñ½αñ╛αñ»αñ░ αñ¼αÑìαñ░αñ┐αñùαÑçαñí αñòαÑÇ αñªαÑï αñùαñ╛αñíαñ╝αñ┐αñ»αÑïαñé αñ¿αÑç αñòαñ╛αñ¼αÑé αñ¬αñ╛αñ»αñ╛αÑñ\n6:23\n6 minutes, 23 seconds\nαñ»αÑéαñ¬αÑÇ αñòαÑç αñ¼αñ▓αñ░αñ╛αñ«αñ¬αÑüαñ░ αñ«αÑçαñé αññαÑçαñ£ αñ░αñ½αÑìαññαñ╛αñ░ αñ¬αñ┐αñòαñàαñ¬ αñ¿αÑç αñ¼αñ╛αñçαñò αñòαÑï αñƒαñòαÑìαñòαñ░ αñ«αñ╛αñ░αÑÇαÑñ αñ╣αñ╛αñªαñ╕αÑç αñ«αÑçαñé αñ¼αñ╛αñçαñò αñ╕αñ╡αñ╛αñ░ αñòαÑÇ αñªαñ░αÑìαñªαñ¿αñ╛αñò αñ«αÑîαññ αñ╣αÑï αñùαñêαÑñ αñ«αñ╛αñ«αñ▓αÑç αñòαÑÇ αñ£αñ╛αñéαñÜ αñ«αÑçαñé αñ£αÑüαñƒαÑÇ αñ╣αÑê αñ¬αÑüαñ▓αñ┐αñ╕αÑñ\n6:32\n6 minutes, 32 seconds\nαñ░αñ╛αñ£αñ╕αÑìαñÑαñ╛αñ¿ αñòαÑç αñ¼αñ╛αñ░αñ╛ αñ«αÑçαñé αñ╣αñ╛αñêαñ╡αÑç αñ¬αñ░ αñ«αñÜαÑÇ αñÜαÑÇαñû αñ¬αÑüαñòαñ╛αñ░αÑñ αñ»αñ╛αññαÑìαñ░αñ┐αñ»αÑïαñé αñ╕αÑç αñ¡αñ░αÑÇ αñ╕αÑìαñ▓αÑÇαñ¬αñ░ αñ¼αñ╕ αñ¬αñ▓αñƒαÑÇαÑñ αñ╣αñ╛αñªαñ╕αÑç αñ«αÑçαñé αñÅαñò αñ¼αñÜαÑìαñÜαÑÇ αñ╕αñ«αÑçαññ αñªαÑï αñòαÑÇ αñ«αÑîαññ αñ╣αÑï αñùαñêαÑñ\n6:39\n6 minutes, 39 seconds\nαñòαñ░αÑÇαñ¼ 12 αñ»αñ╛αññαÑìαñ░αÑÇ αñÿαñ╛αñ»αñ▓ αñ╣αÑüαñÅαÑñ\n6:42\n6 minutes, 42 seconds\nαñëαññαÑìαññαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñ¥αñ╛αñéαñ╕αÑÇ αñ«αÑçαñé αñàαñ¿αñ┐αñ»αñéαññαÑìαñ░αñ┐αññ αñ╣αÑïαñòαñ░ αñòαÑüαñÅαñé αñ«αÑçαñé αñùαñ┐αñ░αñ╛ αñÜαñ╛αñ▓αñò αñòαÑç αñ╕αñ╛αñÑ αñƒαÑìαñ░αÑêαñòαÑìαñƒαñ░αÑñ\n6:47\n6 minutes, 47 seconds\nαñòαñ¿ αñòαÑÇ αñ«αñªαñª αñ╕αÑç αñƒαÑìαñ░αÑêαñòαÑìαñƒαñ░ αñòαÑï αñ¼αñ╛αñ╣αñ░ αñ¿αñ┐αñòαñ╛αñ▓αñ╛ αñùαñ»αñ╛αÑñ αñÜαñ╛αñ▓αñò αñ╣αñ╛αñªαñ╕αÑç αñ«αÑçαñé αñ¼αñ╛αñ▓-αñ¼αñ╛αñ▓ αñ¼αñÜαñ╛αÑñ\n6:54\n6 minutes, 54 seconds\nαñëαññαÑìαññαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñòαñ╛αñ¿αñ¬αÑüαñ░ αñªαÑçαñ╣αñ╛αññ αñ«αÑçαñé αñ╕αñ░αñòαñ╛αñ░αÑÇ αñòαÑêαñéαñƒαÑÇαñ¿ αñÜαñ▓αñ╛αñ¿αÑç αñ╡αñ╛αñ▓αÑç αñ»αÑüαñ╡αñò αñ¿αÑç αñåαññαÑìαñ«αñªαñ╣αñ╛ αñòαñ╛ αñ¬αÑìαñ░αñ»αñ╛αñ╕ αñòαñ┐αñ»αñ╛αÑñ αñ¼αÑêαñ¿αñ░ αñ▓αÑçαñòαñ░ αñ»αÑüαñ╡αñò αñ¬αñ╣αÑüαñéαñÜ αñùαñ»αñ╛\n7:01\n7 minutes, 1 second\nαñ╡αñ┐αñòαñ╛αñ╕ αñ¡αñ╡αñ¿αÑñ 4 αñ╕αñ╛αñ▓ αñ╕αÑç αñ▓αñéαñÜ αñ¬αÑêαñòαÑçαñƒ αñòαÑç αñ▓αñ┐αñÅ αñ¿αñ╣αÑÇαñé αñ╣αÑüαñå αñ¡αÑüαñùαññαñ╛αñ¿αÑñ\n7:07\n7 minutes, 7 seconds\nαñùαñ╛αñ£αÑÇαñ¬αÑüαñ░ αñ«αÑçαñé αñ╕αñ░αñòαñ╛αñ░αÑÇ αñ╕αñ┐αñ╕αÑìαñƒαñ« αñòαÑÇ αñ¿αñ╛αñòαñ╛αñ«αÑÇ αñ╕αÑç αñûαñ½αñ╡αñ╛ αñ»αÑüαñ╡αñò αñƒαñ╛αñ╡αñ░ αñ¬αñ░ αñÜαñóαñ╝αñ╛αÑñ αñ£αñ«αÑÇαñ¿ αñ╡αñ┐αñ╡αñ╛αñª αñ«αÑçαñé αñçαñéαñ╕αñ╛αñ½ αñ¿αñ╛ αñ«αñ┐αñ▓αñ¿αÑç αñ¬αñ░ αñ¿αñ╛αñ░αñ╛αñ£ αñÑαñ╛ αñ»αÑüαñ╡αñòαÑñ αñ¬αÑìαñ░αñ╢αñ╛αñ╕αñ¿ αñòαÑç αñòαñ╛αñ½αÑÇ αñ╕αñ«αñ¥αñ╛αñ¿αÑç αñòαÑç αñ¼αñ╛αñª αñƒαñ╛αñ╡αñ░ αñ╕αÑç αñ»αÑüαñ╡αñò αñ¿αÑÇαñÜαÑç αñëαññαñ░αñ╛αÑñ\n7:19\n7 minutes, 19 seconds\nαñ«αÑüαñ╣αñ░αÑìαñ░αñ« αñòαÑï αñ▓αÑçαñòαñ░ αñ▓αñûαñ¿αñè αñ¬αÑüαñ▓αñ┐αñ╕ αñòαÑÇ αññαÑêαñ»αñ╛αñ░αñ┐αñ»αñ╛αñéαÑñ\n7:22\n7 minutes, 22 seconds\nαñíαÑÇαñ╕αÑÇαñ¬αÑÇ αñ¬αñ╢αÑìαñÜαñ┐αñ« αñòαñ«αñ▓αÑçαñ╢ αñªαÑÇαñòαÑìαñ╖αñ┐αññ αñ¿αÑç αñ╣αÑüαñ╕αÑêαñ¿αñ╛αñ¼αñ╛αñª αñ«αÑçαñé αñ¬αÑêαñªαñ▓ αñùαñ╢αÑìαññ αñòαÑÇαÑñ αñ¼αñíαñ╝αÑç αñçαñ«αñ╛αñ«αñ¼αñ╛αñíαñ╝αñ╛ αñöαñ░ αñ¢αÑïαñƒαÑç αñçαñ«αñ╛αñ«αñ¼αñ╛αñíαñ╝αñ╛ αñòαñ╛ αñ¿αñ┐αñ░αÑÇαñòαÑìαñ╖αñú αñòαñ┐αñ»αñ╛αÑñ αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñ╡αÑìαñ»αñ╡αñ╕αÑìαñÑαñ╛αñôαñé αñòαñ╛ αñ£αñ╛αñ»αñ£αñ╛ αñ▓αñ┐αñ»αñ╛αÑñ\n7:34\n7 minutes, 34 seconds\nαñàαñ╣αñ«αñªαñ╛αñ¼αñ╛αñª αñ«αÑçαñé αñùαÑüαñ£αñ░αñ╛αññ αñ╕αñ░αñòαñ╛αñ░ αñ«αÑçαñé αñ«αñéαññαÑìαñ░αÑÇ αñïαñ╖αñ┐αñòαÑçαñ╢ αñ¬αñƒαÑçαñ▓ αñòαÑç αñ¿αÑçαññαÑâαññαÑìαñ╡ αñ«αÑçαñé αñ╕αñ╛αñ¼αñ░αñ«αññαÑÇ αñ¿αñªαÑÇ αñòαÑÇ αñ╕αñ½αñ╛αñê αñòαÑÇ αñùαñêαÑñ αñ«αñ╛αñ¿αñ╕αÑéαñ¿ αñ╕αÑç αñ¬αñ╣αñ▓αÑç αñ¿αñªαÑÇ αñòαÑç αñåαñ╕αñ¬αñ╛αñ╕ αñÜαñ▓αñ╛αñ»αñ╛ αñùαñ»αñ╛ αñ╕αñ½αñ╛αñê αñàαñ¡αñ┐αñ»αñ╛αñ¿αÑñ\n7:46\n7 minutes, 46 seconds\nαññαñ«αñ┐αñ▓αñ¿αñ╛αñíαÑü αñ«αÑçαñé αñ╕αñíαñ╝αñò αñ¬αñ░ αñëαññαñ░αÑç αñòαñ┐αñ╕αñ╛αñ¿αÑñ αñ╡αÑçαñ▓αÑîαñ░ αñ«αÑçαñé αñòαñ░αÑÇαñ¼ 600 αñòαñ┐αñ╕αñ╛αñ¿αÑïαñé αñ¿αÑç αñ¬αÑìαñ░αñªαñ░αÑìαñ╢αñ¿ αñòαñ┐αñ»αñ╛αÑñ αñ¬αÑéαñ░αñ╛ αñòαñ░αÑìαñ£ αñ«αñ╛αñ½ αñòαñ░αñ¿αÑç αñòαÑÇ αñ«αñ╛αñéαñù αñòαÑÇαÑñ\n7:55\n7 minutes, 55 seconds\nαñ«αñºαÑìαñ» αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñ«αñèαñùαñéαñ£ αñ«αÑçαñé αñ¿αÑÇαñƒ αñ░αÑÇ αñÅαñùαÑìαñ£αñ╛αñ« αñ╕αÑç αñ¬αñ╣αñ▓αÑç αñ╣αÑÇ αñ¢αñ╛αññαÑìαñ░αñ╛ αñ¿αÑç αñåαññαÑìαñ«αñ╣αññαÑìαñ»αñ╛ αñòαÑÇαÑñ\n8:00\n8 minutes\nαñ╕αÑüαñ╕αñ╛αñçαñí αñ¿αÑïαñƒ αñ«αÑçαñé αñ▓αñ┐αñûαñ╛ αñªαÑïαñ¼αñ╛αñ░αñ╛ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛ αñªαÑçαñ¿αÑç αñòαÑÇ αñ╣αñ┐αñ«αÑìαñ«αññ αñ¿αñ╣αÑÇαñé αñ╣αÑêαÑñ αñ¿αñ╛αñùαñ¬αÑüαñ░ αñ«αÑçαñé αñ¿αÑÇαñƒ αñòαÑÇ αññαÑêαñ»αñ╛αñ░αÑÇ αñòαñ░ αñ░αñ╣αÑÇ αñÑαÑÇ αñ¢αñ╛αññαÑìαñ░αñ╛αÑñ\n8:08\n8 minutes, 8 seconds\nαñòαÑçαñªαñ╛αñ░αñ¿αñ╛αñÑ αñºαñ╛αñ« αñ«αÑçαñé αñàαñ¼ αññαñò 10 αñ▓αñ╛αñû αñ╕αÑç αñàαñºαñ┐αñò αñ╢αÑìαñ░αñªαÑìαñºαñ╛αñ▓αÑüαñôαñé αñ¿αÑç αñªαñ░αÑìαñ╢αñ¿ αñòαñ░ αñ▓αñ┐αñÅ αñ╣αÑêαñéαÑñ 22 αñàαñ¬αÑìαñ░αÑêαñ▓ αñ╕αÑç αñ╢αÑüαñ░αÑé αñ╣αÑüαñê αñÑαÑÇ αñòαÑçαñªαñ╛αñ░αñ¿αñ╛αñÑ αñºαñ╛αñ« αñòαÑÇ αñ»αñ╛αññαÑìαñ░αñ╛αÑñ αñ¼αñ╛αñ¼αñ╛ αñòαÑçαñªαñ╛αñ░ αñòαÑç αñ¡αñòαÑìαññαÑïαñé αñ«αÑçαñé αñëαññαÑìαñ╕αñ╛αñ╣ αñ╣αÑêαÑñ\n8:18\n8 minutes, 18 seconds\nαñ«αñ╣αÑïαñ¼αñ╛ αñ«αÑçαñé αñ╕αñ░αñòαñ╛αñ░αÑÇ αñùαñ╛αñíαñ╝αÑÇ αñ¢αÑïαñíαñ╝ αñ¼αÑêαñ▓αñùαñ╛αñíαñ╝αÑÇ αñ¬αñ░ αñ╕αñ╡αñ╛αñ░ αñ╣αÑüαñÅ αñ╕αÑÇαñô αñ░αñ╡αñ┐αñòαñ╛αñéαññ αñùαñíαÑñ αñ╡αñ░αÑìαñªαÑÇ αñ«αÑçαñé αñ¼αÑêαñ▓αñùαñ╛αñíαñ╝αÑÇ αñÜαñ▓αñ╛αññαÑç αñ╕αÑÇαñô αñòαñ╛ αñ╡αÑÇαñíαñ┐αñ»αÑï αñ╡αñ╛αñ»αñ░αñ▓ αñ╣αÑï αñ░αñ╣αñ╛ αñ╣αÑêαÑñ\n8:29\n8 minutes, 29 seconds\nαñòαÑçαñ░αñ▓αñ« αñòαÑç αñ╡αñ╛αñ»αñ¿αñ╛αñƒ αñ«αÑçαñé αñ╡αñ¿ αñ╡αñ┐αñ¡αñ╛αñù αñòαÑÇ αñƒαÑÇαñ« αñ¿αÑç αñÅαñò αñ╣αñ┐αñ░αñ¿ αñòαÑç αñ¼αñÜαÑìαñÜαÑç αñòαñ╛ αñ╡αÑÇαñíαñ┐αñ»αÑï αñ£αñ╛αñ░αÑÇ αñòαñ┐αñ»αñ╛ αñ╣αÑêαÑñ\n8:34\n8 minutes, 34 seconds\nαñ£αñ┐αñ╕αñ«αÑçαñé αñªαÑï αñ«αñ╣αñ┐αñ▓αñ╛ αñ╡αñ¿αñòαñ░αÑìαñ«αÑÇ αñ¼αñÜαÑìαñÜαÑç αñòαÑï αñ¼αÑïαññαñ▓ αñ╕αÑç αñªαÑéαñº αñ¬αñ┐αñ▓αñ╛αññαÑÇ αñ╣αÑüαñê αñ¿αñ£αñ░ αñå αñ░αñ╣αÑÇ αñ╣αÑêαñéαÑñ αñàαñ¬αñ¿αÑÇ αñ«αñ╛αñé αñ╕αÑç αñ¼αñ┐αñ¢αñíαñ╝ αñùαñ»αñ╛ αñ╣αÑê αñ╣αñ┐αñ░αñú αñòαñ╛ αñ»αñ╣ αñ¼αñÜαÑìαñÜαñ╛αÑñ\n8:43\n8 minutes, 43 seconds\nαñëαññαÑìαññαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñ¼αñ╣αñ░αñ╛αñçαñÜ αñ«αÑçαñé αñ░αñ┐αñ╣αñ╛αñçαñ╢αÑÇ αñçαñ▓αñ╛αñòαÑç αñ«αÑçαñé αñàαñ£αñùαñ░ αñ╕αÑç αñ½αÑêαñ▓αÑÇ αñªαñ╣αñ╢αññαÑñ αñàαñ£αñùαñ░ αñªαñ┐αñûαñ¿αÑç αñ╕αÑç αñùαÑìαñ░αñ╛αñ«αÑÇαñúαÑïαñé αñ«αÑçαñé αñ«αñÜαñ╛ αñ╣αñíαñ╝αñòαñéαñ¬αÑñ αñ╕αÑéαñÜαñ¿αñ╛ αñ¬αñ╛αñòαñ░ αñ«αÑîαñòαÑç αñ¬αñ░ αñ¬αñ╣αÑüαñéαñÜαÑÇ αñ╡αñ¿ αñ╡αñ┐αñ¡αñ╛αñù αñòαÑÇ αñƒαÑÇαñ«αÑñ αñàαñ£αñùαñ░ αñòαñ╛ αñ░αÑçαñ╕αÑìαñòαÑìαñ»αÑé αñòαñ░ αñ£αñéαñùαñ▓ αñ«αÑçαñé αñ¢αÑïαñíαñ╝αñ╛αÑñ\n8:57\n8 minutes, 57 seconds\nαñàαñ╕αñ« αñòαÑç αñ¿αñ▓αñ¼αñ╛αñíαñ╝αÑÇ αñ«αÑçαñé αñ¢αñ╛αññαÑìαñ░ αñ╕αñéαñÿ αñ¿αÑçαññαñ╛ αñòαÑÇ αñ╣αññαÑìαñ»αñ╛ αñòαñ╛ αñåαñ░αÑïαñ¬αÑÇ αñ«αÑüαñáαñ¡αÑçαñíαñ╝ αñ«αÑçαñé αñóαÑçαñ░αÑñ αñåαñ░αÑïαñ¬αÑÇ αñ¿αÑç αñ«αÑâαñªαÑü αñ╡αñ░αÑìαñºαñ¿ αñ¼αñ░αÑìαñ«αñ¿ αñöαñ░ αñëαñ¿αñòαÑÇ αñ¼αñ╣αñ¿ αñ¬αñ░ αñòαñ┐αñ»αñ╛ αñÑαñ╛\n9:05\n9 minutes, 5 seconds\nαñ╣αñ«αñ▓αñ╛αÑñ αñ╣αñ«αñ▓αÑç αñ«αÑçαñé αñ¼αñ░αÑìαñ«αñ¿ αñòαÑÇ αñ╣αÑüαñê αñÑαÑÇ αñ«αÑîαññαÑñ αñ¼αñ╣αñ¿ αñòαñ╛ αñçαñ▓αñ╛αñ£ αñ╣αÑê αñ£αñ╛αñ░αÑÇαÑñ\n9:12\n9 minutes, 12 seconds\nαñªαñ┐αñ▓αÑìαñ▓αÑÇ αñòαÑç αñ«αÑüαñûαñ░αÑìαñ£αÑÇ αñ¿αñùαñ░ αñ«αÑçαñé αñûαÑéαñ¿αÑÇ αñ╡αñ╛αñ░αñªαñ╛αññ, αñùαñªαÑìαñªαÑç αñòαÑÇ αñªαÑüαñòαñ╛αñ¿ αñ«αÑçαñé αñ╕αñ╛αñÑ αñòαñ╛αñ« αñòαñ░αñ¿αÑç αñ╡αñ╛αñ▓αÑç αñ╢αñûαÑìαñ╕ αñ¿αÑç αñàαñ¬αñ¿αÑç αñ╕αñ╣αñòαñ░αÑìαñ«αÑÇ αñòαÑÇ αñòαÑêαñéαñÜαÑÇ αñ╕αÑç αñ╣αñ«αñ▓αñ╛ αñòαñ░ αñ£αñ╛αñ¿ αñ▓αÑç αñ▓αÑÇαÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñåαñ░αÑïαñ¬αÑÇ αñàαñ╢αñ½αñ╛αñò αñòαÑï αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛ αñ╣αÑêαÑñ\n9:24\n9 minutes, 24 seconds\nαñ¼αñ┐αñ╣αñ╛αñ░ αñòαÑç αñòαñ┐αñ╢αñ¿αñùαñéαñ£ αñ«αÑçαñé αñ╕αñéαñªαñ┐αñùαÑìαñº αñ╕αÑìαñÑαñ┐αññαñ┐ αñ«αÑçαñé αñ╕αñ╛αññαñ╡αÑÇαñé αñòαÑìαñ▓αñ╛αñ╕ αñòαÑÇ αñ¢αñ╛αññαÑìαñ░αñ╛ αñòαÑÇ αñ«αÑîαññ αñ╣αÑï αñùαñêαÑñ\n9:28\n9 minutes, 28 seconds\nαñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ¬αñ░αñ┐αñ£αñ¿αÑïαñé αñòαÑÇ αñ╢αñ┐αñòαñ╛αñ»αññ αñ¬αñ░ αñòαÑçαñ╕ αñªαñ░αÑìαñ£ αñòαñ┐αñ»αñ╛αÑñ αñ£αñ╛αñéαñÜ αñ¬αñíαñ╝αññαñ╛αñ▓ αñòαÑÇ αñ£αñ╛ αñ░αñ╣αÑÇ αñ╣αÑêαÑñ\n9:36\n9 minutes, 36 seconds\nαñëαññαÑìαññαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñÜαñ┐αññαÑìαñ░αñòαÑéαñƒ αñ«αÑçαñé 12 αñ╕αñ╛αñ▓ αñòαÑç αñ¼αñÜαÑìαñÜαÑç αñòαÑÇ αñ╣αññαÑìαñ»αñ╛αÑñ αñ╡αñ╛αñ░αñªαñ╛αññ αñ╕αÑç αñ¬αñ░αñ┐αñ£αñ¿αÑïαñé αñòαñ╛ αñ░αÑï-αñ░αÑï αñòαñ░ αñ¼αÑüαñ░αñ╛ αñ╣αñ╛αñ▓ αñ╣αÑêαÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ«αñ╛αñ«αñ▓αÑç αñòαÑÇ αñ£αñ╛αñéαñÜ αñ¬αñíαñ╝αññαñ╛αñ▓ αñ«αÑçαñé αñ£αÑüαñƒαÑÇαÑñ\n9:47\n9 minutes, 47 seconds\nαñ░αñ╛αñ£αñºαñ╛αñ¿αÑÇ αñªαñ┐αñ▓αÑìαñ▓αÑÇ αñ«αÑçαñé αñ¼αñªαñ«αñ╛αñ╢αÑïαñé αñòαÑç αñ╣αÑîαñ╕αñ▓αÑç αñ¼αÑüαñ▓αñéαñª αñ╣αÑêαÑñ αñ¿αÑìαñ»αÑé αñëαñ╕αÑìαñ«αñ╛αñ¿αñ¬αÑüαñ░ αñçαñ▓αñ╛αñòαÑç αñ«αÑçαñé αñòαÑêαñÜαñ┐αñéαñù αñòαñ╛αñ░αÑïαñ¼αñ╛αñ░αÑÇ αñòαÑÇ αñªαÑüαñòαñ╛αñ¿ αñòαÑç αñ¼αñ╛αñ╣αñ░ αññαñ╛αñ¼αñíαñ╝αññαÑïαñíαñ╝ αñ½αñ╛αñ»αñ░αñ┐αñéαñù αñòαÑÇ αñùαñêαÑñ αñ╕αñíαñ╝αñò αñ╕αÑç αñùαÑüαñ£αñ░ αñ░αñ╣αÑç αñ¼αñÜαÑìαñÜαÑç αñòαÑï αñùαÑïαñ▓αÑÇ αñ▓αñùαÑÇαÑñ\n10:00\n10 minutes\nαñ«αÑüαñ░αñ╛αñªαñ╛αñ¼αñ╛αñª αñ«αÑçαñé αñ¼αñ╛αñçαñò αñ╕αñ╡αñ╛αñ░ αñ¼αñªαñ«αñ╛αñ╢αÑïαñé αñ¿αÑç αñòαÑÇ αññαñ╛αñ¼αñíαñ╝αññαÑïαñíαñ╝ αñ½αñ╛αñ»αñ░αñ┐αñéαñùαÑñ αñùαÑïαñ▓αÑÇ αñ▓αñùαñ¿αÑç αñ╕αÑç αñ»αÑüαñ╡αñò αñÿαñ╛αñ»αñ▓ αñ╣αÑï αñùαñ»αñ╛αÑñ αñªαÑïαñ¿αÑïαñé αñ¬αñòαÑìαñ╖αÑïαñé αñòαÑç αñ¼αÑÇαñÜ αñÜαñ▓ αñ░αñ╣αñ╛ αñ╣αÑê αñ╡αñ┐αñ╡αñ╛αñªαÑñ\n10:09\n10 minutes, 9 seconds\nαñ╕αñ╣αñ╛αñ░αñ¿αñ¬αÑüαñ░ αñ«αÑçαñé αñ╡αÑìαñ»αñ╛αñ¬αñ╛αñ░αÑÇ αñòαÑÇ αñ¬αññαÑìαñ¿αÑÇ αñòαÑÇ αñ╣αññαÑìαñ»αñ╛ αñ╕αÑç αñ╕αñ¿αñ╕αñ¿αÑÇ αñ½αÑêαñ▓αÑÇαÑñ αñ╡αñ╛αñ░αñªαñ╛αññ αñòαÑç αñ╕αñ«αñ» αñÿαñ░ αñ«αÑçαñé αñàαñòαÑçαñ▓αÑÇ αñÑαÑÇ αñ«αñ╣αñ┐αñ▓αñ╛αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ╢αÑüαñ░αÑé αñòαÑÇ αñ«αñ╛αñ«αñ▓αÑç αñòαÑÇ αñ¢αñ╛αñ¿αñ¼αÑÇαñ¿αÑñ\n10:19\n10 minutes, 19 seconds\nαñ»αÑéαñ¬αÑÇ αñòαÑç αñ½αññαÑçαñ╣αñ¬αÑüαñ░ αñ«αÑçαñé αñ¬αññαÑìαñ¿αÑÇ αñ¿αÑç αñ¬αññαñ┐ αñ¿αÑç αñ¬αññαÑìαñ¿αÑÇ αñòαÑç αñ¬αÑìαñ░αÑçαñ«αÑÇ αñòαÑï αññαñ╛αñ░αñ╛ αñ«αÑîαññ αñòαÑç αñÿαñ╛αñƒ αñÿαñ░ αñ¼αÑüαñ▓αñ╛αñòαñ░ αñ╣αññαÑìαñ»αñ╛ αñòαÑÇαÑñ αñ¬αññαÑìαñ¿αÑÇ αñ¿αÑç αñ¬αññαñ┐ αñòαñ╛ αñ«αñ░αÑìαñíαñ░ αñ«αÑçαñé αñ╕αñ╛αñÑ αñªαñ┐αñ»αñ╛αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñªαÑïαñ¿αÑïαñé αñòαÑï αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛αÑñ\n10:30\n10 minutes, 30 seconds\nαñ¿αÑïαñÅαñíαñ╛ αñòαÑç αñÅαñò αñ╣αÑïαñƒαñ▓ αñ«αÑçαñé αñÜαñ▓ αñ░αñ╣αÑç αñ£αÑüαñå αñ░αÑêαñòαÑçαñƒ αñòαñ╛ αñûαÑüαñ▓αñ╛αñ╕αñ╛ αñ╣αÑüαñå αñ╣αÑêαÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç 20 αñ╕αñƒαÑïαñ░αñ┐αñ»αÑïαñé αñòαÑïαñéαñùαÑç αñ╣αñ╛αñÑ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛αÑñ αñ▓αñ╛αñûαÑïαñé αñòαÑÇ αñ¿αñòαñªαÑÇ, αñ▓αñùαÑìαñ£αñ░αÑÇ αñùαñ╛αñíαñ╝αñ┐αñ»αñ╛αñé αñöαñ░ αñ«αÑïαñ¼αñ╛αñçαñ▓ αñ½αÑïαñ¿ αñ¼αñ░αñ╛αñ«αñªαÑñ\n10:43\n10 minutes, 43 seconds\nαñëαññαÑìαññαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñ«αñÑαÑüαñ░αñ╛ αñ«αÑçαñé αñ╡αÑâαñéαñªαñ╛αñ╡αñ¿ αñòαÑç αñ¬αñ░αñ┐αñòαÑìαñ░αñ«αñ╛ αñ«αñ╛αñ░αÑìαñù αñ¬αñ░ αñ«αñ╣αñ┐αñ▓αñ╛αñôαñé αñ╕αÑç αñ¢αÑçαñíαñ╝αñûαñ╛αñ¿αÑÇ αñòαñ░αñ¿αÑç αñ╡αñ╛αñ▓αñ╛ αñåαñ░αÑïαñ¬αÑÇ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ«αñ╣αñ┐αñ▓αñ╛αñôαñé αñ╕αÑç αñ«αñéαñùαñ╡αñ╛αñê αñ«αñ╛αñ½αÑÇαÑñ αñ╡αÑÇαñíαñ┐αñ»αÑï αñ╣αÑï αñ░αñ╣αñ╛ αñ╕αÑïαñ╢αñ▓ αñ«αÑÇαñíαñ┐αñ»αñ╛ αñ¬αñ░ αñ╡αñ╛αñ»αñ░αñ▓αÑñ\n10:55\n10 minutes, 55 seconds\nαñëαññαÑìαññαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñ╡αñ╛αñ░αñ╛αñúαñ╕αÑÇ αñÅαñ»αñ░αñ¬αÑïαñ░αÑìαñƒ αñ¬αñ░ αñòαñ╕αÑìαñƒαñ« αñ╡αñ┐αñ¡αñ╛αñù αñòαÑÇ αñ¼αñíαñ╝αÑÇ αñòαñ╛αñ░αñ╡αñ╛αñêαÑñ αñòαñ░αÑÇαñ¼ 20 αñòαñ░αÑïαñíαñ╝ αñòαñ╛ αñùαñ╛αñéαñ£αñ╛ αñ£αÑìαññ αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛αÑñ αñ¢αñ╣ αñ╡αñ┐αñªαÑçαñ╢αÑÇ αññαñ╕αÑìαñòαñ░ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░αÑñ αñ¼αÑêαñéαñòαÑëαñò αñ╕αÑç αñ╡αñ╛αñ░αñ╛αñúαñ╕αÑÇ αñåαñê αñÑαÑÇ αñ½αÑìαñ▓αñ╛αñçαñƒαÑñ\n11:06\n11 minutes, 6 seconds\nαñëαññαÑìαññαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñ«αÑüαñ£αñ½αÑìαñ½αñ░αñ¿αñùαñ░ αñ«αÑçαñé αñ«αÑüαñáαñ¡αÑçαñíαñ╝ αñ«αÑçαñé αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░αÑñ αñ¼αñªαñ«αñ╛αñ╢ αñ¿αÑç αñ¬αÑüαñ▓αñ┐αñ╕ αñ╕αÑç αñ«αñ╛αñéαñùαÑÇ αñ¼αÑÇαñíαñ╝αÑÇαÑñ αñùαÑïαñ▓αÑÇ αñ▓αñùαñ¿αÑç αñòαÑç αñ¼αñ╛αñª αñÿαñ╛αñ»αñ▓ αñ¼αñªαñ«αñ╛αñ╢ αñ¼αÑÇαñíαñ╝αÑÇ αñ«αñ╛αñéαñùαññαÑç αñ╣αÑüαñÅ αñ¿αñ£αñ░ αñåαñ»αñ╛αÑñ αñ╡αÑÇαñíαñ┐αñ»αÑï αñåαñ»αñ╛ αñ╕αñ╛αñ«αñ¿αÑçαÑñ\n11:17\n11 minutes, 17 seconds\nαñ╣αñ░αñ┐αñ»αñ╛αñúαñ╛ αñòαñ╛ αñ¬αÑìαñ░αñªαÑÇαñ¬ αñ╣αññαÑìαñ»αñ╛αñòαñ╛αñéαñíαÑñ αñ¡αñ┐αñ╡αñ╛αñ¿αÑÇ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ¢αñ╣ αñåαñ░αÑïαñ¬αñ┐αñ»αÑïαñé αñòαÑï αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛αÑñ αñ«αÑüαñûαÑìαñ» αñåαñ░αÑïαñ¬αÑÇ αñ¡αÑÇ αñàαñ░αÑçαñ╕αÑìαñƒ αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛αÑñ\n11:25\n11 minutes, 25 seconds\nαñ«αÑîαñ╕αñ« αñ╡αñ┐αñ¡αñ╛αñù αñ¿αÑç αñªαÑÇ αñ╣αÑê αñÅαñò αñ░αñ╛αñ╣αññ αñ¡αñ░αÑÇ αñûαñ¼αñ░αÑñ\n11:27\n11 minutes, 27 seconds\nαñàαñùαñ▓αÑç αñªαÑï αñ╕αÑç αññαÑÇαñ¿ αñªαñ┐αñ¿αÑïαñé αñ«αÑçαñé αñòαÑçαñ░αñ▓ αñ«αÑçαñé αñªαñòαÑìαñ╖αñ┐αñú αñ¬αñ╢αÑìαñÜαñ┐αñ« αñ«αñ╛αñ¿αñ╕αÑéαñ¿ αñòαÑç αñåαñ¿αÑç αñòαÑÇ αñëαñ«αÑìαñ«αÑÇαñª αñ╣αÑêαÑñ\n11:35\n11 minutes, 35 seconds\nαñ«αñºαÑìαñ» αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñëαñ£αÑìαñ£αÑêαñ¿ αñ«αÑçαñé αñåαñéαñºαÑÇ αññαÑéαñ½αñ╛αñ¿ αñòαÑç αñ╕αñ╛αñÑ αññαÑçαñ£ αñ¼αñ╛αñ░αñ┐αñ╢ αñ╣αÑüαñêαÑñ αñ«αÑîαñ╕αñ« αñòαÑÇ αñòαñ░αñ╡αñƒ αñ▓αÑçαñ¿αÑç αñ╕αÑç αññαñ╛αñ¬αñ«αñ╛αñ¿ αñ«αÑçαñé αñåαñê αñùαñ┐αñ░αñ╛αñ╡αñƒαÑñ αñ▓αÑïαñùαÑïαñé αñòαÑï αñÜαñ┐αñ▓αñÜαñ┐αñ▓αñ╛αññαÑÇ αñùαñ░αÑìαñ«αÑÇ αñ╕αÑç αñ░αñ╛αñ╣αññ αñ«αñ┐αñ▓αÑÇαÑñ\n11:47\n11 minutes, 47 seconds\nαñ«αñºαÑìαñ» αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñ¼αÑüαñ░αñ╣αñ╛αñ¿αñ¬αÑüαñ░ αñ«αÑçαñé αñ¡αÑÇ αñ«αÑîαñ╕αñ« αñ¿αÑç αñàαñÜαñ╛αñ¿αñò αñòαñ░αñ╡αñƒ αñ¼αñªαñ▓αÑÇαÑñ αñåαñéαñºαÑÇ αññαÑéαñ½αñ╛αñ¿ αñòαÑç αñ╕αñ╛αñÑ αñ╣αÑüαñê αñ¡αñ»αñéαñòαñ░ αñ¼αñ╛αñ░αñ┐αñ╢αÑñ αñ¬αñ╛αñ░αñ╛ αñùαñ┐αñ░αñ¿αÑç αñòαÑÇ αñ╡αñ£αñ╣ αñ╕αÑç αñ«αñ┐αñ▓αÑÇ αñùαñ░αÑìαñ«αÑÇ αñ╕αÑç αñ░αñ╛αñ╣αññαÑñ\n11:58\n11 minutes, 58 seconds\nαñ«αñºαÑìαñ» αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñ¿αÑÇαñ«αñÜ αñ«αÑçαñé αñ¡αÑÇ αñ╕αÑïαñ«αñ╡αñ╛αñ░ αñ╢αñ╛αñ« αñàαñÜαñ╛αñ¿αñò αñ╕αÑç αñ«αÑîαñ╕αñ« αñ¿αÑç αñòαñ░αñ╡αñƒ αñ¼αñªαñ▓αÑÇαÑñ αññαÑéαñ½αñ╛αñ¿ αñòαÑç αñ╕αñ╛αñÑ αñ¼αñ╛αñ░αñ┐αñ╢ αñ╣αÑüαñêαÑñ αññαÑéαñ½αñ╛αñ¿ αñòαÑÇ αñ╡αñ£αñ╣ αñ╕αÑç αñ«αñÜαÑÇ αñàαñ½αñ░αñ╛αññαñ½αñ░αÑÇαÑñ\n12:11\n12 minutes, 11 seconds\nαñ¿αÑêαñ¿αÑÇαññαñ╛αñ▓ αñ«αÑçαñé αñ¡αÑÇ αñ¼αñªαñ▓αñ╛ αñ«αÑîαñ╕αñ«αÑñ αñ¥αñ«αñ╛αñ¥αñ« αñ¼αñ╛αñ░αñ┐αñ╢ αñ╕αÑç αñ╕αÑüαñ╣αñ╛αñ╡αñ¿αñ╛ αñ╣αÑüαñå αñ«αÑîαñ╕αñ«αÑñ αñ╢αñ╣αñ░ αñòαÑç αñòαñê αñçαñ▓αñ╛αñòαÑïαñé αñ«αÑçαñé αñ╕αñíαñ╝αñòαÑïαñé αñ¬αñ░ αñ╣αÑüαñå αñ£αñ▓αñ¡αñ░αñ╛αñ╡αÑñ\n12:19\n12 minutes, 19 seconds\nαñ»αÑéαñ¬αÑÇ αñòαÑç αñ¼αñ▓αñ░αñ╛αñ«αñ¬αÑüαñ░ αñ«αÑçαñé αñ¡αÑÇαñ╖αñú αñùαñ░αÑìαñ«αÑÇ αñ╕αÑç αñ¼αñÜαñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ αñ¿αñªαÑÇ αñ«αÑçαñé αñ¿αñ╣αñ╛αññαÑç αñ¿αñ£αñ░ αñåαñÅ αñ╣αñ╛αñÑαÑÇαÑñ αñ¿αñªαÑÇ αñòαÑç αñòαñ┐αñ¿αñ╛αñ░αÑç αñ╣αñ╛αñÑαñ┐αñ»αÑïαñé αñ¿αÑç αñ£αñ«αñ╛αñ»αñ╛ αñíαÑçαñ░αñ╛αÑñ αñ╡αÑÇαñíαñ┐αñ»αÑï αñåαñ»αñ╛ αñ╕αñ╛αñ«αñ¿αÑçαÑñ\n12:28\n12 minutes, 28 seconds\nαñêαñ░αñ╛αñ¿ αñòαÑÇ αñ¿αÑçαñ╡αÑÇ αñòαñ╛ αñªαñ╛αñ╡αñ╛αÑñ αñôαñ«αñ╛αñ¿ αñ╕αñ╛αñùαñ░ αñ«αÑçαñé αñêαñ░αñ╛αñ¿αÑÇ αñ£αñ╣αñ╛αñ£ αñ▓αñ┐αñ»αñ╛αñ¿ αñ╕αÑìαñƒαñ╛αñ░ αñ¬αñ░ αñ╣αñ«αñ▓αÑç αñòαÑç αñ£αñ╡αñ╛αñ¼ αñ«αÑçαñé αñ¬αñ▓αñƒαñ╡αñ╛αñ░αÑñ αñ»αÑéαñÅαñ╕ αñçαñ£αñ░αñ╛αñçαñ▓ αñ╕αÑç αñ£αÑüαñíαñ╝αÑç αñ£αñ╣αñ╛αñ£ αñÅαñ«αñÅαñ╕αñ╕αÑÇ αñ╕αñ╛αñ░αñ╕αÑìαñòαñ╛ αñ¬αñ░ αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛ αñ£αñ╡αñ╛αñ¼αÑÇ αñàαñƒαÑêαñòαÑñ\n12:41\n12 minutes, 41 seconds\nαñçαñ░αñ╛αñò αñòαÑç αñ¬αñ╛αñ╕ αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñçαñ£αñ░αñ╛αñçαñ▓ αñ£αÑüαñíαñ╝αÑç αñ╣αÑüαñÅ αñ£αñ╣αñ╛αñ£ αñ¬αñ░ αñåαñêαñåαñ░αñ£αÑÇαñ╕αÑÇ αñòαñ╛ αñ╣αñ«αñ▓αñ╛αÑñ αñÅαñò αñ£αñ╣αñ╛αñ£ αñòαÑï αñ╣αñ«αñ▓αÑç αñòαÑç αñ¼αñ╛αñª αñòαñ¼αÑìαñ£αÑç αñ«αÑçαñé αñ¡αÑÇ αñ▓αñ┐αñ»αñ╛αÑñ\n12:50\n12 minutes, 50 seconds\nαñ½αñ╛αñ░αñ╕ αñòαÑÇ αñûαñ╛αñíαñ╝αÑÇ αñ«αÑçαñé αñ«αñ╛αñ▓αñ╡αñ╛αñ╣αñò αñ£αñ╣αñ╛αñ£ αñ¬αñ░ αñºαñ«αñ╛αñòαÑç αñòαÑÇ αñûαñ¼αñ░αÑñ αñçαñ░αñ╛αñò αñòαÑç αñëαñ« αñòαñ╛αñ╕αñ░ αñ¼αñéαñªαñ░αñùαñ╛αñ╣ αñòαÑç αñ¬αñ╛αñ╕ αñàαñƒαÑêαñò αñ╣αÑüαñåαÑñ αñ╢αÑüαñ░αÑüαñåαññαÑÇ αñ£αñ╛αñéαñÜ αñ«αÑçαñé αññαñòαñ¿αÑÇαñòαÑÇ αñûαñ░αñ╛αñ¼αÑÇ αñòαÑï αñòαñ╛αñ░αñú αñ¼αññαñ╛αñ»αñ╛ αñùαñ»αñ╛ αñ╣αÑêαÑñ\n13:02\n13 minutes, 2 seconds\nαñ▓αÑçαñ¼αñ¿αñ╛αñ¿ αñòαÑç αñ¼αÑìαñ»αÑéαñ½αÑïαñ░αÑìαñƒ αñòαÑêαñ╕αñ▓ αñòαÑç αñ¬αñ╛αñ╕ αñçαñ£αñ░αñ╛αñçαñ▓αÑÇ αñ¼αñéαñòαñ░ αñ¬αñ░ αñ╣αÑ¢αñ¼αÑüαñ▓αÑìαñ▓αñ╛ αñòαñ╛ αñ╣αñ«αñ▓αñ╛αÑñ αñ╣αÑ¢αñ¼αÑüαñ▓αÑìαñ▓αñ╛ αñ¿αÑç αñçαñ£αñ░αñ╛αñçαñ▓αÑÇ αñ╕αÑçαñ¿αñ╛ αñòαÑç αñ¼αñéαñòαñ░ αñòαÑï αñíαÑìαñ░αÑïαñ¿ αñ╕αÑç αñ¿αñ┐αñ╢αñ╛αñ¿αñ╛ αñ¼αñ¿αñ╛αñ»αñ╛αÑñ αñçαñ£αñ░αñ╛αñçαñ▓ αñ¿αÑç αñ▓αÑçαñ¼αñ¿αñ╛αñ¿αÑÇ αñòαñ┐αñ▓αÑç αñ¬αñ░ αñàαñ¬αñ¿αñ╛ αñ¥αñéαñíαñ╛ αñ½αñ╣αñ░αñ╛αñ»αñ╛ αñÑαñ╛αÑñ\n13:15\n13 minutes, 15 seconds\nαñêαñ░αñ╛αñ¿ αñ¿αÑç αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñòαÑç αñ╕αñ╛αñÑ αñ░αÑïαñòαÑÇ αñ¼αñ╛αññαñÜαÑÇαññαÑñ\n13:17\n13 minutes, 17 seconds\nαñ«αÑÇαñíαñ┐αñ»αñ╛ αñ░αñ┐αñ¬αÑïαñ░αÑìαñƒαÑìαñ╕ αñòαÑç αñ╣αñ╡αñ╛αñ▓αÑç αñ╕αÑç αñûαñ¼αñ░αÑñ αñ╕αñéαñÿαñ░αÑìαñ╖ αñ╡αñ┐αñ░αñ╛αñ« αñòαñ╛ αñ¼αñ╛αñ░-αñ¼αñ╛αñ░ αñëαñ▓αÑìαñ▓αñéαñÿαñ¿αÑñ αñçαñ£αñ░αñ╛αñçαñ▓ αñòαñ╛ αñ▓αÑçαñ¼αñ¿αñ╛αñ¿ αñ¬αñ░ αñ╣αñ«αñ▓αÑçαÑñ αñ╢αñ╛αñéαññαñ┐ αñ╡αñ╛αñ░αÑìαññαñ╛ αñ«αÑçαñé αñ¼αñ¿αñ╛ αñ¼αñíαñ╝αñ╛ αñ░αÑïαñíαñ╝αñ╛αÑñ\n13:27\n13 minutes, 27 seconds\nαñêαñ░αñ╛αñ¿ αñòαÑç αñ╕αñ╛αñÑ αñ¼αñ╛αññαñÜαÑÇαññ αñ╕αÑìαñÑαñùαñ┐αññ αñòαñ░αñ¿αÑç αñòαÑÇ αñûαñ¼αñ░αÑïαñé αñ¬αñ░ αñƒαÑìαñ░αñéαñ¬ αñ¿αÑç αñ¼αñ»αñ╛αñ¿ αñªαñ┐αñ»αñ╛ αñ╣αÑêαÑñ αñòαñ╣αñ╛ αñ╣αÑê αñòαñ┐ αñ╣αñ«αÑçαñé αñêαñ░αñ╛αñ¿ αñ╕αÑç αñòαÑïαñê αñ£αñ╡αñ╛αñ¼ αñ¿αñ╣αÑÇαñé αñ«αñ┐αñ▓αñ╛αÑñ αñÉαñ╕αÑç αñ╕αñ«αñ» αñ«αÑçαñé αñÜαÑüαñ¬ αñ░αñ╣αñ¿αñ╛ αñ╣αÑÇ αñ¼αÑçαñ╣αññαñ░ αñ╣αÑïαñùαñ╛αÑñ αñ╣αñ« αñòαñ░ αñ░αñ╣αÑç αñ╣αÑêαñé αñ¼αñ╣αÑüαññ αñ£αÑìαñ»αñ╛αñªαñ╛ αñ¼αñ╛αññαñÜαÑÇαññαÑñ\n13:40\n13 minutes, 40 seconds\nαñêαñ░αñ╛αñ¿ αñòαÑç αñ╕αñ╛αñÑ αñ╢αñ╛αñéαññαñ┐ αñ╡αñ╛αñ░αÑìαññαñ╛ αñ¬αñ░ αñíαÑïαñ¿αñ▓αÑìαñí αñƒαÑìαñ░αñéαñ¬ αñòαñ╛ αñÅαñò αñöαñ░ αñ¼αñíαñ╝αñ╛ αñ¼αñ»αñ╛αñ¿αÑñ αñòαñ╣αñ╛ αñ£αñ¼ αññαñò αñêαñ░αñ╛αñ¿ αñÜαñ╛αñ╣αÑç αñ╣αñ« αññαñ¼ αññαñò αñòαñ░ αñ╕αñòαññαÑç αñ╣αÑêαñé αñçαñéαññαñ£αñ╛αñ░αÑñ\n13:50\n13 minutes, 50 seconds\nαñ╕αÑìαñƒαÑçαñƒ αñæαñ½ αñ╣αÑëαñ░αÑìαñ«αÑéαñ╕ αñòαÑï αñ▓αÑçαñòαñ░ αñêαñ░αñ╛αñ¿ αñòαñ╛ αñªαñ╛αñ╡αñ╛ αñòαñ╣αñ╛ αñêαñ░αñ╛αñ¿ αñòαÑç αñ¿αñ┐αñ»αñéαññαÑìαñ░αñú αñ«αÑçαñé αñ╣αÑê αñ╣αÑëαñ░αÑìαñ«αÑéαñ╕ αñ╕αñ«αÑüαñªαÑìαñ░αÑÇ αñ¿αñ╛αñòαÑçαñ¼αñéαñªαÑÇ αñ░αñ╣αÑçαñùαÑÇ αñ£αñ╛αñ░αÑÇαÑñ αñêαñ░αñ╛αñ¿ αñòαÑç αñ╕αñ╢αñ╕αÑìαññαÑìαñ░ αñ¼αñ▓αÑïαñé αñòαÑç αñ╕αñ¼αÑìαñ░ αñòαÑÇ αñ¡αÑÇ αñ╕αÑÇαñ«αñ╛ αñ╣αÑêαÑñ\n14:00\n14 minutes\nαñ╣αÑëαñ░αÑìαñ«αÑéαñ╕ αñòαÑï αñ▓αÑçαñòαñ░ αñêαñ░αñ╛αñ¿αÑÇ αñ╕αÑçαñ¿αñ╛ αñòαñ╛ αñªαñ╛αñ╡αñ╛ αñòαñ╣αñ╛ αñ¼αÑÇαññαÑç 24 αñÿαñéαñƒαÑç αñòαÑç αñ¡αÑÇαññαñ░ αñ╣αÑëαñ░αñ░αÑìαñ«αÑéαñ╕ αñ╕αÑç αñ╣αÑïαñòαñ░ αñùαÑüαñ£αñ░αÑç αñÜαñ╛αñ░ αññαÑçαñ▓ αñƒαÑêαñéαñòαñ░ αñ╕αñ«αÑçαññ 15 αñ£αñ╣αñ╛αñ£αÑñ\n14:10\n14 minutes, 10 seconds\nαñ╕αÑìαñƒαÑçαñƒ αñæαñ½ αñ╣αÑëαñ░αÑìαñ«αÑéαñ╕ αñòαÑç αñ╕αñ╛αñÑ-αñ╕αñ╛αñÑ αñàαñ¼ αñ¼αñ╛αñ¼ αñàαñ▓αñ«αñéαñ£αÑçαñ¼ αñ╕αÑìαñƒαÑçαñƒ αñòαÑï αñ¡αÑÇ αñ¬αÑéαñ░αÑÇ αññαñ░αñ╣ αñ╕αÑç αñ¼αñéαñª αñòαñ░αñ¿αÑç αñ¬αñ░ αñ╣αÑï αñ░αñ╣αñ╛ αñ╣αÑê αñ╡αñ┐αñÜαñ╛αñ░αÑñ αñ»αñ«αñ¿ αñòαÑçαññαÑÇ αñ╡αñ┐αñªαÑìαñ░αÑïαñ╣αñ┐αñ»αÑïαñé αñòαÑç αñòαñéαñƒαÑìαñ░αÑïαñ▓ αñ«αÑçαñé αñ╣αÑê αñ¼αñ╛αñ¼ αñàαñ▓αñ«αñéαñíαÑçαñ¼ αñ╕αÑìαñƒαÑìαñ░αÑçαñƒαÑñ\n14:21\n14 minutes, 21 seconds\nαñªαñòαÑìαñ╖αñ┐αñúαÑÇ αñ▓αÑçαñ¼αñ¿αñ╛αñ¿ αñ«αÑçαñé αñçαñ£αñ░αñ╛αñçαñ▓αÑÇ αñ╕αÑçαñ¿αñ╛ αñòαñ╛ αñ╣αñ╡αñ╛αñê αñ╣αñ«αñ▓αñ╛αÑñ	f	2026-06-02 15:45:11.051739
28	UCRWFSbif-RFENbBrSiez1DA	National	General	Transcript\nSearch transcript\n0:02\n2 seconds\nαñêαñ░αñ╛αñ¿ αñòαÑÇ αñ¿αÑçαñ╡αÑÇ αñòαñ╛ αñªαñ╛αñ╡αñ╛ αñôαñ«αñ╛αñ¿ αñ╕αñ╛αñùαñ░ αñ«αÑçαñé αñêαñ░αñ╛αñ¿αÑÇ αñ£αñ╣αñ╛αñ£ αñ▓αñ┐αñ»αñ╛αñ¿ αñ╕αÑìαñƒαñ╛αñ░ αñ¬αñ░ αñ╣αñ«αñ▓αÑç αñòαÑç αñ£αñ╡αñ╛αñ¼ αñ«αÑçαñé αñ¬αñ▓αñƒαñ╡αñ╛αñ░ αñ»αÑéαñÅαñ╕ αñçαñ£αñ░αñ╛αñçαñ▓ αñ╕αÑç αñ£αÑüαñíαñ╝αÑç αñ£αñ╣αñ╛αñ£ αñÅαñ«αñÅαñ╕αñ╕αÑÇ\n0:10\n10 seconds\nαñ╕αñ░αñ╕ [αñ╕αñéαñùαÑÇαññ] αñ¬αñ░ αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛ αñ£αñ╡αñ╛αñ¼αÑÇ αñ╣αñ«αñ▓αñ╛ αñ¬αñ╛αñ░αñ╕ αñòαÑÇ αñûαñ╛αñíαñ╝αÑÇ αñ«αÑçαñé αñ«αñ╛αñ▓αñ╡αñ╛αñ╣αñò αñ£αñ╣αñ╛αñ£ αñ¬αñ░ αñºαñ«αñ╛αñòαÑç\n0:17\n17 seconds\nαñòαÑÇ αñûαñ¼αñ░ αñçαñ░αñ╛αñò αñòαÑç αñëαñ¿αñòαñ╛ αñàαñ╕αñ░ αñ¼αñéαñªαñ░αñùαñ╛αñ╣ αñ¬αñ░ αñ╣αÑüαñå αñ╣αñ╛αñªαñ╕αñ╛ αñ╢αÑüαñ░αÑüαñåαññαÑÇ αñ£αñ╛αñéαñÜ αñ«αÑçαñé αññαñòαñ¿αÑÇαñòαÑÇ [αñ╕αñéαñùαÑÇαññ] αñûαñ░αñ╛αñ¼αÑÇ αñòαÑï αñ¼αññαñ╛αñ»αñ╛ αñùαñ»αñ╛ αñ╣αÑê αñòαñ╛αñ░αñú\n0:26\n26 seconds\nαñ▓αÑçαñ¼αñ¿αñ╛αñ¿ αñòαÑç αñ¼αÑìαñ»αÑéαñ░αÑï αñ½αÑïαñ░αÑìαñƒ αñòαÑç αñ¬αñ╛αñ╕ αñçαñ£αñ░αñ╛αñçαñ▓αÑÇ αñ¼αñéαñòαñ░ αñ¬αñ░ αñòαñ╛ αñ╣αñ«αñ▓αñ╛ αñ╣αñ┐αñ£αñ¼αÑüαñ▓αÑìαñ▓αñ╛ αñ¿αÑç αñçαñ£αñ░αñ▓αÑÇ αñ╕αÑçαñ¿αñ╛ αñòαÑç αñ¼αñéαñòαñ░ αñòαÑï αñíαÑìαñ░αÑïαñ¿ αñ╕αÑç αñ¿αñ┐αñ╢αñ╛αñ¿αñ╛ αñ¼αñ¿αñ╛αñ»αñ╛αÑñ αñçαñ£αñ░αñ╛αñçαñ▓ αñ¿αÑç αñ▓αÑçαñ¼αñ¿αñ╛αñ¿αÑÇ αñòαñ┐αñ▓αÑç αñ¬αñ░ αñ½αñ╣αñ░αñ╛αñ»αñ╛ αñÑαñ╛ αñàαñ¬αñ¿αñ╛ αñ¥αñéαñíαñ╛αÑñ\n0:38\n38 seconds\nαñêαñ░αñ╛αñ¿ αñ¿αÑç αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñòαÑç αñ╕αñ╛αñÑ αñ░αÑïαñòαÑÇ αñ¼αñ╛αññαñÜαÑÇαññαÑñ\n0:40\n40 seconds\nαñ«αÑÇαñíαñ┐αñ»αñ╛ αñ░αñ┐αñ¬αÑïαñ░αÑìαñƒαÑìαñ╕ αñòαÑç αñ╣αñ╡αñ╛αñ▓αÑç αñ╕αÑç αñûαñ¼αñ░αÑñ αñ╕αñéαñÿαñ░αÑìαñ╖ αñ╡αñ┐αñ░αñ╛αñ« αñòαñ╛ αñ¼αñ╛αñ░-αñ¼αñ╛αñ░ αñëαñ▓αÑìαñ▓αñéαñÿαñ¿αÑñ αñçαñ£αñ░αñ╛αñçαñ▓ αñòαñ╛ [αñ╕αñéαñùαÑÇαññ] αñ▓αÑçαñ¼αñ¿αñ╛αñ¿ αñ¬αñ░ αñ╣αñ«αñ▓αÑçαÑñ αñ╢αñ╛αñéαññαñ┐ αñ╡αñ╛αñ░αÑìαññαñ╛ αñ«αÑçαñé αñ¼αñ¿ αñ░αñ╣αñ╛ αñ╣αÑê αñ░αÑïαñíαñ╝αñ╛αÑñ\n0:51\n51 seconds\nαñêαñ░αñ╛αñ¿ αñòαÑç αñ╕αñ╛αñÑ αñ¼αñ╛αññαñÜαÑÇαññ αñ╕αÑìαñÑαñùαñ┐αññ αñòαñ░αñ¿αÑç αñòαÑÇ αñûαñ¼αñ░αÑïαñé αñ¬αñ░ αñƒαÑìαñ░αñéαñ¬ αñ¿αÑç αñòαñ╣αñ╛ αñ╣αÑê αñòαñ┐ αñ╣αñ«αÑçαñé αñêαñ░αñ╛αñ¿ αñ╕αÑç αñòαÑïαñê αñ£αñ╡αñ╛αñ¼ αñ¿αñ╣αÑÇαñé αñ«αñ┐αñ▓αñ╛αÑñ αñÉαñ╕αÑç αñ╕αñ«αñ» αñ«αÑçαñé αñÜαÑüαñ¬ αñ░αñ╣αñ¿αñ╛ αñ╣αÑÇ\n0:58\n58 seconds\nαñ¼αÑçαñ╣αññαñ░ αñ╣αÑïαñùαñ╛αÑñ αñ╣αñ« αñòαñ░ αñ░αñ╣αÑç αñ╣αÑêαñé αñ¼αñ╣αÑüαññ αñ£αÑìαñ»αñ╛αñªαñ╛ αñ¼αñ╛αññαñÜαÑÇαññαÑñ\n1:04\n1 minute, 4 seconds\nαñêαñ░αñ╛αñ¿ αñòαÑç αñ╕αñ╛αñÑ αñ╢αñ╛αñéαññαñ┐ αñ╡αñ╛αñ░αÑìαññαñ╛ αñ¬αñ░ αñíαÑïαñ¿αñ▓αÑìαñí αñƒαÑìαñ░αñéαñ¬ αñòαñ╛ αñÅαñò αñöαñ░ αñ¼αñíαñ╝αñ╛ αñ¼αñ»αñ╛αñ¿αÑñ αñòαñ╣αñ╛ αñ£αñ¼ [αñ╕αñéαñùαÑÇαññ] αññαñò αñêαñ░αñ╛αñ¿ αñÜαñ╛αñ╣αÑç αñ╣αñ« αññαñ¼ αññαñò αñòαñ░ αñ╕αñòαññαÑç αñ╣αÑêαñé αñçαñéαññαñ£αñ╛αñ░αÑñ\n1:13\n1 minute, 13 seconds\nαñ╕αÑìαñƒαÑçαñƒ αñæαñ½ αñ╣αñ╛αñ░αÑìαñ«αÑéαñ╕ αñòαÑï αñ▓αÑçαñòαñ░ αñêαñ░αñ╛αñ¿ αñòαñ╛ αñªαñ╛αñ╡αñ╛αÑñ\n1:16\n1 minute, 16 seconds\nαñòαñ╣αñ╛ αñêαñ░αñ╛αñ¿ αñòαÑç αñ¿αñ┐αñ»αñéαññαÑìαñ░αñú [αñ╕αñéαñùαÑÇαññ] αñ«αÑçαñé αñ╣αÑê αñçαñ╕ αñ╡αñòαÑìαññ αñ╕αÑìαñƒαÑçαñƒ αñæαñ½ αñ╣αñ╛αñ░αÑìαñ«αÑéαÑñ αñ╕αñ«αÑüαñªαÑìαñ░αÑÇ αñ¿αñ╛αñòαÑçαñ¼αñéαñªαÑÇ αñ░αñ╣αÑçαñùαÑÇ αñ£αñ╛αñ░αÑÇαÑñ αñêαñ░αñ╛αñ¿ αñòαÑç αñ╕αñ╢αñ╕αÑìαññαÑìαñ░ αñ¼αñ▓αÑïαñé αñòαÑç αñ╕αñ¼αÑìαñ░ αñòαÑÇ αñ¡αÑÇ αñòαÑïαñê αñ╕αÑÇαñ«αñ╛ αñ╣αÑïαññαÑÇ αñ╣αÑêαÑñ\n1:25\n1 minute, 25 seconds\nαñ╣αÑëαñ░αÑìαñ«αÑéαñ╕ αñòαÑï αñ▓αÑçαñòαñ░ αñêαñ░αñ╛αñ¿αÑÇ αñ╕αÑçαñ¿αñ╛ αñòαñ╛ αñªαñ╛αñ╡αñ╛αÑñ αñ¼αÑÇαññαÑç 24 αñÿαñéαñƒαÑç αñòαÑç αñ¡αÑÇαññαñ░ αñ╣αÑëαñ░αÑìαñ«αÑéαñ╕ αñ╕αÑç αñ╣αÑïαñòαñ░ αñùαÑüαñ£αñ░αÑç αñÜαñ╛αñ░ αññαÑçαñ▓ αñƒαÑêαñéαñòαñ░ αñ╕αñ«αÑçαññ 15 αñ£αñ╣αñ╛αñ£αÑñ\n1:36\n1 minute, 36 seconds\nαñ╕αÑìαñƒαÑìαñ░αÑçαñƒ αñöαñ░ αñ½αñ╛αñ░αÑìαñ«αÑéαñ╕ αñòαÑç αñ╕αñ╛αñÑ-αñ╕αñ╛αñÑ αñàαñ¼ αñ¼αñ╛αñ¼αñ▓ αñ«αñéαñíαÑçαñ¼ αñ╕αÑìαñƒαÑçαñƒ αñòαÑï αñ¡αÑÇ αñ¬αÑéαñ░αÑÇ αññαñ░αñ╣ αñ╕αÑç αñ¼αñéαñª αñòαñ░αñ¿αÑç αñ¬αñ░ αñ╡αñ┐αñÜαñ╛αñ░ αñ╣αÑï αñ░αñ╣αñ╛ αñ╣αÑêαÑñ αñ»αñ«αñ¿ αñòαÑç αñ╣αÑïαññαÑÇ αñ╣αÑüαñê αñ╡αñ┐αñªαÑìαñ░αÑïαñ╣αÑÇ αñòαÑç αñòαñéαñƒαÑìαñ░αÑïαñ▓ αñ«αÑçαñé αñ╣αÑê αñ¼αñ╛αñ¼ αñàαñ▓αñ«αñéαñíαÑçαñ¼ αñ╕αÑìαñƒαÑçαñƒαÑñ\n1:47\n1 minute, 47 seconds\nαñªαñòαÑìαñ╖αñ┐αñúαÑÇ αñ▓αÑçαñ¼αñ¿αñ╛αñ¿ αñ«αÑçαñé αñçαñ£αñ░αñ╛αñçαñ▓αÑÇ αñ╕αÑçαñ¿αñ╛ αñòαñ╛ αñ╣αñ╡αñ╛αñê αñ╣αñ«αñ▓αñ╛αÑñ αñçαñ£αñ░αñ╛αñçαñ▓αÑÇ αñ╡αñ┐αñ«αñ╛αñ¿αÑïαñé αñ¿αÑç αñàαñ▓αñ«αñ░αñ╡αñ╛αñ¿αñ┐αñ»αñ╛ αñ╢αñ╣αñ░ αñ¬αñ░ αñòαñ┐αñÅ αñªαÑï αñ╣αñ╡αñ╛αñê αñ╣αñ«αñ▓αÑçαÑñ αñ╣αñ┐αñ£αñ¼αÑüαñ▓αÑìαñ▓αñ╛αñ╣ αñòαÑï αñƒαñ╛αñ░αñùαÑçαñƒ αñòαñ░ αñ╣αñ«αñ▓αÑç αñòαñ┐αñÅαÑñ\n1:57\n1 minute, 57 seconds\nαñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ¬αññαñ┐ αñíαÑïαñ¿αñ▓αÑìαñí αñƒαÑìαñ░αñéαñ¬ αñ¿αÑç αñ¿αÑçαññαñ¿ αñ»αñ╛αñ╣αÑé αñ¬αñ░ αñ▓αñùαñ╛αñ»αñ╛ αñ▓αÑçαñ¼αñ¿αñ╛αñ¿ αñ«αÑçαñé αñ╣αñ╛αñ▓αñ╛αññαÑïαñé αñòαÑï αñ¼αÑçαñ╡αñ£αñ╣ αññαÑéαñ▓ αñªαÑçαñ¿αÑç αñòαñ╛ αñåαñ░αÑïαñ¬αÑñ αñƒαÑìαñ░αñéαñ¬ αñ¿αÑç αñòαñ┐αñ»αñ╛ αñ¼αÑçαñ░αÑéαññ αñ¬αñ░ αñ¬αÑìαñ░αñ╕αÑìαññαñ╛αñ╡αñ┐αññ αñ╣αñ«αñ▓αÑç αñòαñ╛ αñ╡αñ┐αñ░αÑïαñºαÑñ\n2:09\n2 minutes, 9 seconds\nαñ«αÑÇαñíαñ┐αñ»αñ╛ αñ░αñ┐αñ¬αÑïαñ░αÑìαñƒαÑìαñ╕ αñòαÑç αñ╣αñ╡αñ╛αñ▓αÑç αñ╕αÑç αñûαñ¼αñ░αÑñ αñƒαÑìαñ░αñéαñ¬ αñ¿αÑç αñ½αÑïαñ¿ αñòαÑëαñ▓ αñòαÑç αñªαÑîαñ░αñ╛αñ¿ αñ¿αÑçαññαñ¿ αñ»αñ╛αÑé αñ¬αñ░ αñàαñ¬αñ¿αñ╛ αñùαÑüαñ╕αÑìαñ╕αñ╛ αñëαññαñ╛αñ░αñ╛αÑñ αñòαñ╣αñ╛ αñ«αÑêαñé αñ¿αñ╣αÑÇαñé αñ╣αÑïαññαñ╛ αññαÑï αñ£αÑçαñ▓ αñ«αÑçαñé αñ╣αÑïαññαÑç αñ¿αÑçαññαñ¿ αñ»αñ╛αñ╣αÑé αñ«αÑêαñé αñ╣αÑÇ αñ¼αñÜαñ╛ αñ░αñ╣αñ╛ αñ╣αÑéαñé αññαÑüαñ«αÑìαñ╣αñ╛αñ░αÑÇ αñ£αñ╛αñ¿αÑñ\n2:21\n2 minutes, 21 seconds\nαñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ¬αññαñ┐ αñƒαÑìαñ░αñéαñ¬ αñòαñ╛ αñªαñ╛αñ╡αñ╛ αñòαñ╣αñ╛ αñ¿αÑçαññαñ¿ αñ»αñ╛αñ╣αÑé αñ╕αÑç αñ¼αñ╛αññαñÜαÑÇαññ αñòαÑç αñ¼αñ╛αñª αñ¼αÑçαñ░αÑéαññ αñ«αÑçαñé αñ¼αñíαñ╝αñ╛ αñ╕αÑêαñ¿αÑìαñ» αñàαñ¡αñ┐αñ»αñ╛αñ¿ αñÜαñ▓αñ╛αÑñ αñ¼αÑÇαñÜ αñ░αñ╛αñ╕αÑìαññαÑç αñ╕αÑç αñ╡αñ╛αñ¬αñ╕ αñ¼αÑüαñ▓αñ╛ αñ▓αñ┐αñÅ αñùαñÅ αñ╕αÑêαñ¿αñ┐αñòαÑñ\n2:31\n2 minutes, 31 seconds\nαñíαÑëαñ¿αñ▓αÑìαñí αñƒαÑìαñ░αñéαñ¬ αñ¿αÑç αñòαñ┐αñ»αñ╛ αñ╣αÑê αñªαñ╛αñ╡αñ╛αÑñ αñëαñÜαÑìαñÜ αñ╕αÑìαññαñ░αÑÇαñ» αñ¬αÑìαñ░αññαñ┐αñ¿αñ┐αñºαñ┐αñ»αÑïαñé αñòαÑç αñ£αñ░αñ┐αñÅ αñ╕αÑìαñòαÑéαñ▓ αñ¿αÑçαññαñ╛αñôαñé αñ╕αÑç αñ╣αÑüαñê αñ╣αÑê αñàαñÜαÑìαñ¢αÑÇ αñ¼αñ╛αññαñÜαÑÇαññαÑñ αñªαÑïαñ¿αÑïαñé αñ¬αñòαÑìαñ╖ αñùαÑïαñ▓αÑÇαñ¼αñ╛αñ░αÑÇ αñ¼αñéαñª αñòαñ░αñ¿αÑç αñ¬αñ░ αñ╕αñ╣αñ«αññ αñ╣αÑüαñÅαÑñ αñÅαñò αñªαÑéαñ╕αñ░αÑç αñ¬αñ░ αñ╣αñ«αñ▓αñ╛ αñ¿αñ╛ αñòαñ░αñ¿αÑç αñ¬αñ░ αñ╕αñ╣αñ«αññ αñ╣αÑüαñÅ αñªαÑïαñ¿αÑïαñé αñ¬αñòαÑìαñ╖αÑñ\n2:43\n2 minutes, 43 seconds\nαñ▓αÑçαñ¼αñ¿αñ╛αñ¿ αñòαÑç αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ¬αññαñ┐ αñòαñ╛αñ░αÑìαñ»αñ╛αñ▓αñ» αñòαñ╛ αñ¼αñ»αñ╛αñ¿αÑñ\n2:45\n2 minutes, 45 seconds\nαñ╣αñ┐αñ£αñ¼αÑüαñ▓αÑìαñ▓αñ╛ αñ¿αÑç αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñòαÑç αñ¬αÑìαñ░αñ╕αÑìαññαñ╛αñ╡ αñ¬αñ░ αñ£αññαñ╛αñê αñ╕αñ╣αñ«αññαñ┐αÑñ αñ¼αÑêαñ░αÑéαññ αñòαÑç αñªαñòαÑìαñ╖αñ┐αñúαÑÇ αñëαñ¬αñ¿αñùαñ░αÑïαñé αñ¬αñ░ αñ╣αñ╡αñ╛αñê αñ╣αñ«αñ▓αÑçαÑñ αñ¼αñéαñª αñòαñ░αÑçαñùαñ╛ αñçαñ£αñ░αñ╛αñçαñ▓αÑñ αñ╣αñ┐αÑ¢αñ¼αÑüαñ▓αÑìαñ▓αñ╛ αñ¡αÑÇ αñçαñ£αñ░αñ╛αñçαñ▓ αñ¬αñ░ αñ¿αñ╣αÑÇαñé αñòαñ░αÑçαñùαñ╛ αñòαÑïαñê αñàαñƒαÑêαñòαÑñ\n2:56\n2 minutes, 56 seconds\nαñêαñ░αñ╛αñ¿ αñòαÑÇ αñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑï αñÜαÑçαññαñ╛αñ╡αñ¿αÑÇαÑñ αñ▓αÑçαñ¼αñ¿αñ╛αñ¿ αñ«αÑçαñé αñ╣αñ«αñ▓αÑç αñ¼αñ░αÑìαñªαñ╛αñ╢αÑìαññ αñ¿αñ╣αÑÇαñé αñòαñ░αÑçαñùαñ╛ αñêαñ░αñ╛αñ¿αÑñ αñ¼αÑÇαññαÑç [αñ╕αñéαñùαÑÇαññ] αñòαÑüαñ¢ αñªαñ┐αñ¿ αñ«αÑçαñé αñçαñ£αñ░αñ╛αñçαñ▓ αñ¿αÑç αñªαñòαÑìαñ╖αñ┐αñúαÑÇ αñ▓αÑçαñ¼αñ¿αñ╛αñ¿ αñ«αÑçαñé αññαÑçαñ£ αñòαñ┐αñÅ αñ╣αñ«αñ▓αÑçαÑñ\n3:05\n3 minutes, 5 seconds\nαñçαñ£αñ░αñ╛αñçαñ▓αÑÇ αñ¬αÑìαñ░αñºαñ╛αñ¿αñ«αñéαññαÑìαñ░αÑÇ αñªαÑçαññαñ¿ αñ»αñ╛αñ╣αÑé αñòαñ╛ αñ¼αñ»αñ╛αñ¿αÑñ\n3:08\n3 minutes, 8 seconds\nαñòαñ╣αñ╛ αñªαñòαÑìαñ╖αñ┐αñúαÑÇ αñ▓αÑçαñ¼αñ¿αñ╛αñ¿ αñ«αÑçαñé αñ¬αÑìαñ▓αñ╛αñ¿ αñòαÑç αñ«αÑüαññαñ╛αñ¼αñ┐αñò αñòαñ╛αñ« αñòαñ░αññαñ╛ αñ░αñ╣αÑçαñùαñ╛ αñçαñ£αñ░αñ╛αñçαñ▓αÑñ αñ╣αÑ¢αñ¼αÑüαñ▓αÑìαñ▓αñ╛ αñ¿αÑç αñ╣αñ«αñ▓αÑïαñé αñòαÑç αñ£αñ╡αñ╛αñ¼ αñ«αÑçαñé αñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑç αñ╣αñ«αñ▓αÑç αñ¡αÑÇ αñ£αñ╛αñ░αÑÇ αñ░αñ╣αÑçαñéαñùαÑçαÑñ\n3:16\n3 minutes, 16 seconds\nαñªαñòαÑìαñ╖αñ┐αñúαÑÇ αñ▓αÑçαñ¼αñ¿αñ╛αñ¿ αñ«αÑçαñé αñ╣αñ«αñ▓αÑç αñ░αÑïαñòαñ¿αÑç αñ¬αñ░ αñƒαÑìαñ░αñéαñ¬ αñòαÑç αñ½αÑêαñ╕αñ▓αÑç αñ¬αñ░ αñçαñ£αñ░αñ╛αñçαñ▓αÑÇ αñ«αñéαññαÑìαñ░αÑÇ αñ¿αÑç αñ£αññαñ╛αñê αñ¿αñ╛αñ░αñ╛αñ£αñùαÑÇαÑñ αñòαñ╣αñ╛ αñòαñ┐ αñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ¬αññαñ┐ αñòαÑï αñàαñ¼ αñ¿αñ╛ αñòαñ╣αñ¿αÑç αñòαñ╛ αñå αñùαñ»αñ╛ αñ╣αÑê αñ╕αñ«αñ»αÑñ\n3:28\n3 minutes, 28 seconds\nαñêαñ░αñ╛αñ¿ αñòαÑÇ αñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑï αñÜαÑçαññαñ╛αñ╡αñ¿αÑÇαÑñ αñ¼αÑêαñ░αÑéαñª αñòαÑç αñåαñ╕αñ¬αñ╛αñ╕ αñ╣αñ«αñ▓αÑç αñ╣αÑüαñÅ αññαÑï αñëαññαÑìαññαñ░αÑÇ αñçαñ£αñ░αñ╛αñçαñ▓ αñöαñ░ αñ╕αÑêαñ¿αÑìαñ» αñ¼αñ╕αÑìαññαñ┐αñ»αÑïαñé αñòαÑï αñ¼αñ¿αñ╛αñ»αñ╛ αñ£αñ╛ αñ╕αñòαññαñ╛ αñ╣αÑê αñ¿αñ┐αñ╢αñ╛αñ¿αñ╛αÑñ\n3:34\n3 minutes, 34 seconds\nαñ▓αÑïαñùαÑïαñé αñ╕αÑç αñçαñ▓αñ╛αñòαñ╛ αñûαñ╛αñ▓αÑÇ αñòαñ░αñ¿αÑç αñòαÑï αñòαñ╣αñ╛αÑñ\n3:40\n3 minutes, 40 seconds\nαñêαñ░αñ╛αñ¿ αñ¿αÑç αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñòαÑç MK9 αñ░αñ┐αñ¬αñ░ αñíαÑìαñ░αÑïαñ¿ αñòαÑï αñ«αñ╛αñ░ αñùαñ┐αñ░αñ╛αñ¿αÑç αñòαñ╛ αñªαñ╛αñ╡αñ╛ αñòαñ┐αñ»αñ╛αÑñ αñåαñêαñ£αÑÇαñ╕αÑÇ αñ¿αÑç αñ¬αñ▓αñƒαñ╡αñ╛αñ░ αñòαñ╛ αñ╡αÑÇαñíαñ┐αñ»αÑï [αñ╕αñéαñùαÑÇαññ] αñ¡αÑÇ αñ£αñ╛αñ░αÑÇ αñòαñ┐αñ»αñ╛ αñ╣αÑêαÑñ\n3:50\n3 minutes, 50 seconds\nαñêαñ░αñ╛αñ¿ αñòαÑç αñ╡αñ┐αñªαÑçαñ╢ αñ«αñéαññαÑìαñ░αÑÇ αñàαñ¼αÑìαñ¼αñ╛αñ╕ αñöαñ░ αñ¬αñ╛αñòαñ┐αñ╕αÑìαññαñ╛αñ¿ αñòαÑç αñ╡αñ┐αñªαÑçαñ╢ αñ«αñéαññαÑìαñ░αÑÇ αñ«αÑïαñ╣αñ«αÑìαñ«αñª αñêαñ╢αñ╛αñò αñíαñ╛αñ░ [αñ╕αñéαñùαÑÇαññ] αñöαñ░ αñ╕αÑçαñ¿αñ╛ αñ¬αÑìαñ░αñ«αÑüαñû αñåαñ╕αñ┐αñ« αñ«αÑüαñ¿αÑÇαñ░ αñòαÑç αñ╕αñ╛αñÑ αñ¼αñ╛αññαñÜαÑÇαññαÑñ\n3:57\n3 minutes, 57 seconds\nαñòαÑìαñ╖αÑçαññαÑìαñ░αÑÇαñ» αñÿαñƒαñ¿αñ╛αñòαÑìαñ░αñ«αÑïαñé αñöαñ░ αñ╕αñéαñÿαñ░αÑìαñ╖ αñ╡αñ┐αñ░αñ╛αñ« αñ╕αÑç αñ£αÑüαñíαñ╝αÑç αñ«αÑüαñªαÑìαñªαÑïαñé αñ¬αñ░ αñ╣αÑüαñê αñÜαñ░αÑìαñÜαñ╛αÑñ\n4:06\n4 minutes, 6 seconds\nαñ£αñ╛αñ¬αñ╛αñ¿ αñòαÑÇ αñ¬αÑìαñ░αñºαñ╛αñ¿αñ«αñéαññαÑìαñ░αÑÇ αññαñ╛αñòαñ╛αñêαñÜαÑÇ αñ¿αÑç αñ½αÑïαñ¿ αñ¬αñ░ αñêαñ░αñ╛αñ¿ αñòαÑç αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ¬αññαñ┐ αñ¬αÑìαñ░αñªαñ░αÑìαñ╢αñ┐αñ»αñ╛αñ¿ αñ╕αÑç αñ¼αñ╛αññαñÜαÑÇαññ αñòαÑÇαÑñ αñ╕αÑìαñƒαÑçαñƒ αñæαñ½ αñ╣αñ╛αñ░αÑìαñ«αÑïαñ╕ αñòαÑï αñ£αñ▓αÑìαñª αñûαÑïαñ▓αñ¿αÑç αñòαÑÇ αñ«αñ╛αñéαñù αñòαÑÇαÑñ\n4:18\n4 minutes, 18 seconds\nαñ¬αñ╢αÑìαñÜαñ┐αñ« αñ¼αñéαñùαñ╛αñ▓ αñ«αÑçαñé αñÜαÑüαñ¿αñ╛αñ╡ αñòαÑç αñ¼αñ╛αñª αñ╣αñ┐αñéαñ╕αñ╛ αñöαñ░ αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ¿αÑçαññαñ╛αñôαñé αñ¬αñ░ αñ╣αÑüαñÅ αñ╣αñ«αñ▓αÑç αñòαÑç αñ╡αñ┐αñ░αÑïαñº αñ«αÑçαñéαÑñ\n4:22\n4 minutes, 22 seconds\nαñ«αñ«αññαñ╛ αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñòαñ╛ αñòαÑìαñ»αñ╛ αñ╣αÑê αñÅαñòαÑìαñ╢αñ¿ αñ¬αÑìαñ▓αñ╛αñ¿? αñªαÑçαñ╢ αñ¡αñ░ αñ«αÑçαñé αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñòαñ╣αñ╛αñé-αñòαñ╣αñ╛αñé αñÜαñ▓αñ╛αñÅαñùαÑÇ αñàαñ¬αñ¿αñ╛ αñàαñ¡αñ┐αñ»αñ╛αñ¿? αñùαÑî αñ«αñ╛αññαñ╛ αñ¬αñ░ αñ╕αÑÇαñÅαñ« αñ»αÑïαñùαÑÇ αñ¿αÑç αñòαÑìαñ»αñ╛ αñòαñ╣αñ╛? αñ░αñ╛αñ£αñ¿αÑÇαññαñ┐ αñòαÑÇ αñ¼αñíαñ╝αÑÇ αñûαñ¼αñ░αÑçαñé αñåαñ¬αñòαÑï αñªαñ┐αñûαñ╛ αñªαÑçαññαÑç αñ╣αÑêαñé αñ¿αÑî αñ╕αÑç αñ¿αÑìαñ»αÑéαñ£αñ╝αÑñ\n4:35\n4 minutes, 35 seconds\nαñ¬αñ╢αÑìαñÜαñ┐αñ« αñ¼αñéαñùαñ╛αñ▓ αñ«αÑçαñé αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ¿αÑçαññαñ╛αñôαñé αñ¬αñ░ αñ╣αñ«αñ▓αÑç, αñòαñ╛αñ░αÑìαñ»αñòαñ░αÑìαññαñ╛αñôαñé αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñ╣αñ┐αñéαñ╕αñ╛ αñöαñ░ αñçαñéαñªαÑÇ αñ¬αñƒαñ░αÑÇ αñ╡αñ╛αñ▓αÑïαñé αñòαÑï αñ╣αñƒαñ╛αñ¿αÑç αñòαñ╛ αñàαñ¡αñ┐αñ»αñ╛αñ¿αÑñ αñ╡αñ┐αñ░αÑïαñº αñ«αÑçαñé αñ╣αÑê αñ«αñ«αññαñ╛ αñ¼αñ¿αñ░αÑìαñ£αÑÇαÑñ αñòαÑïαñ▓αñòαñ╛αññαñ╛ αñ«αÑçαñé αñåαñ£ αñªαÑçαñéαñùαÑÇ αñºαñ░αñ¿αñ╛αÑñ\n4:47\n4 minutes, 47 seconds\nαñ¬αÑüαñ▓αñ┐αñ╕ αñòαÑÇ αñçαñ£αñ╛αñ£αññ αñ¿αñ╣αÑÇαñé αñ«αñ┐αñ▓αñ¿αÑç αñòαÑç αñ¼αñ╛αñ╡αñ£αÑéαñª αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñòαñ╛ αñºαñ░αñ¿αñ╛ αñ╣αÑïαñùαñ╛ αñåαñ£αÑñ αñ«αñ«αññαñ╛ αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñòαñ╛ αñåαñ░αÑïαñ¬αÑñ αñ¡αñ» αñ«αÑçαñé αñ£αÑÇ αñ░αñ╣αÑÇ αñ╣αÑêαÑñ αñ¡αñ» αñ«αÑçαñé αñ£αÑÇ αñ░αñ╣αÑç αñ╣αÑêαñé αñ¢αÑïαñƒαÑç αñ╡αÑìαñ»αñ╛αñ¬αñ╛αñ░αÑÇαÑñ αñƒαÑÇαñÅαñ«αñ╕αÑÇ [αñ╕αñéαñùαÑÇαññ]\n4:55\n4 minutes, 55 seconds\nαñ╡αñ┐αñºαñ╛αñ»αñòαÑïαñé αñòαÑï αñàαñ¬αñ¿αÑç αñ¬αñ╛αñ▓αÑç αñ«αÑçαñé αñ▓αñ╛αñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñòαñ░ αñ░αñ╣αÑÇ αñ╣αÑê αñºαñ¿ αñ¼αñ▓ αñòαñ╛ αñçαñ╕αÑìαññαÑçαñ«αñ╛αñ▓αÑñ\n5:01\n5 minutes, 1 second\nαñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ╡αñ┐αñºαñ╛αñ»αñòαÑïαñé αñòαÑç αñ½αñ░αÑìαñ£αÑÇ αñ╣αñ╕αÑìαññαñ╛αñòαÑìαñ╖αñ░ αñòαñ╛ αñ«αñ╛αñ«αñ▓αñ╛αÑñ αñàαñ¡αñ┐αñ╖αÑçαñò αñ¿αÑç αñ╕αÑìαñ╡αñ╛αñ╕αÑìαñÑαÑìαñ» αñòαñ╛αñ░αñúαÑïαñé αñòαñ╛ αñ╣αñ╡αñ╛αñ▓αñ╛ αñªαÑçαñòαñ░ 15 αñªαñ┐αñ¿ αñòαñ╛ αñ╕αÑÇαñåαñêαñíαÑÇ αñ╕αÑç αñ╡αñòαÑìαññ αñ«αñ╛αñéαñùαñ╛ αñ╣αÑêαÑñ αñ£αñ┐αñ╕αñòαÑç [αñ╕αñéαñùαÑÇαññ] αñ¼αñ╛αñª αñÅαñò αñ¼αñ╛αñ░ αñ½αñ┐αñ░\n5:09\n5 minutes, 9 seconds\nαñ╕αÑç αñàαñ¡αñ┐αñ╖αÑçαñò αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñòαÑç αñåαñ╡αñ╛αñ╕ αñ¬αñ░ αñ¬αñ╣αÑüαñéαñÜαÑÇ αñ╕αÑÇαñåαñêαñíαÑÇ αñòαÑÇ αñƒαÑÇαñ«αÑñ\n5:14\n5 minutes, 14 seconds\nαñ╕αÑÇαñåαñêαñíαÑÇ αñ¿αÑç αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ╕αñ╛αñéαñ╕αñª αñàαñ¡αñ┐αñ╖αÑçαñò αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñòαÑï αñ£αñ╛αñ░αÑÇ αñòαñ┐αñ»αñ╛ αñªαÑéαñ╕αñ░αñ╛ αñ¿αÑïαñƒαñ┐αñ╕αÑñ 8 αñ£αÑéαñ¿ αñòαÑï αñ╕αÑÇαñåαñêαñíαÑÇ αñæαñ½αñ┐αñ╕ αñ«αÑçαñé αñòαñ┐αñ»αñ╛ αññαñ▓αñ╛αÑñ αñ½αñ░αÑìαñ£αÑÇ αñ╣αñ╕αÑìαññαñ╛αñòαÑìαñ╖αñ░ [αñ╕αñéαñùαÑÇαññ] αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñ¬αÑéαñ¢αññαñ╛αñ¢ αñòαñ░αÑçαñùαÑÇ αñ╕αÑÇαñåαñêαñíαÑÇαÑñ\n5:24\n5 minutes, 24 seconds\nαñªαñ┐αñ▓αÑìαñ▓αÑÇ αñ«αÑçαñé αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñòαÑç αñ╕αñ¡αÑÇ αñ¬αÑìαñ░αñªαÑçαñ╢ αñàαñºαÑìαñ»αñòαÑìαñ╖αÑïαñé αñòαÑÇ αñ¼αÑêαñáαñòαÑñ αñòαÑçαñéαñªαÑìαñ░ αñ╕αñ░αñòαñ╛αñ░ αñòαÑç 12 αñ╕αñ╛αñ▓ αñ¬αÑéαñ░αÑç αñ╣αÑïαñ¿αÑç αñ¬αñ░ αñàαñ¡αñ┐αñ»αñ╛αñ¿ αñ╕αñ«αÑçαññ αñòαñê αñ«αÑüαñªαÑìαñªαÑïαñé αñ¬αñ░ αñÜαñ░αÑìαñÜαñ╛ αñ╣αÑüαñêαÑñ αñòαñ╛αñ░αÑìαñ»αñòαñ░αÑìαññαñ╛αñôαñé αñòαÑÇ αñ╕αñ«αñ╕αÑìαñ»αñ╛ [αñ╕αñéαñùαÑÇαññ] αñòαñ╛ αñºαÑìαñ»αñ╛αñ¿ αñ░αñûαñ¿αÑç αñòαÑç αñ¿αñ┐αñ░αÑìαñªαÑçαñ╢ αñªαñ┐αñÅαÑñ\n5:35\n5 minutes, 35 seconds\nαñ╕αÑéαññαÑìαñ░αÑïαñé αñòαÑç αñàαñ¿αÑüαñ╕αñ╛αñ░ 5 αñ╕αÑç 21 αñ£αÑéαñ¿ αññαñò αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñªαÑçαñ╢ αñ¡αñ░ αñ«αÑçαñé αñÜαñ▓αñ╛αñÅαñùαÑÇ αñàαñ¡αñ┐αñ»αñ╛αñ¿αÑñ αñùαñ╛αñéαñ╡ αñòαñ╛ αñªαÑîαñ░αñ╛ αñòαñ░αÑçαñéαñùαÑç αñ╕αñ╛αñéαñ╕αñª, [αñ╕αñéαñùαÑÇαññ] αñ╡αñ┐αñºαñ╛αñ»αñò αñöαñ░ αñ«αñéαññαÑìαñ░αÑÇαÑñ\n5:41\n5 minutes, 41 seconds\n12 αñ╕αñ╛αñ▓ αñ«αÑçαñé αñ£αñ¿αñ╣αñ┐αññ αñ«αÑçαñé αñ▓αñ┐αñÅ αñùαñÅ αñ½αÑêαñ╕αñ▓αÑïαñé αñòαÑÇ αñªαÑçαñéαñùαÑç αñ£αñ╛αñ¿αñòαñ╛αñ░αÑÇαÑñ\n5:46\n5 minutes, 46 seconds\nαññαñ«αñ┐αñ▓αñ¿αñ╛αñíαÑü αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñòαÑç αñ¿αÑçαññαñ╛ αñòαÑç αñàαñ¿αÑìαñ¿αñ╛ αñ«αñ▓αñ╛αñê αñòαÑç αñ¿αñ╛αñ░αñ╛αñ£ αñ╣αÑïαñ¿αÑç αñòαÑÇ αñàαñòαñíαñ╝αÑÇαÑñ αñåαñ£ αñòαñ░αÑçαñéαñùαÑç αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñ╢αÑÇαñ░αÑìαñ╖ αñ¿αÑçαññαÑâαññαÑìαñ╡ αñòαÑç αñ╕αñ╛αñÑ αñ«αÑüαñ▓αñ╛αñòαñ╛αññαÑñ αñ«αÑÇαñƒαñ┐αñéαñù αñòαÑç αñ¼αñ╛αñª αñ¬αñ╛αñ░αÑìαñƒαÑÇ αñ«αÑçαñé αñ░αñ╣αñ¿αÑç αñòαÑï αñ▓αÑçαñòαñ░ αñ▓αÑçαñéαñùαÑç αñ½αÑêαñ╕αñ▓αñ╛αÑñ\n5:58\n5 minutes, 58 seconds\nαñªαñ┐αñ▓αÑìαñ▓αÑÇ αñ«αÑçαñé αñòαñ░αÑìαñ¿αñ╛αñƒαñò αñòαÑç αñ╕αÑÇαñÅαñ« αñ╢αñ┐αñ╡ αñòαÑüαñ«αñ╛αñ░ αñöαñ░ αñ╕αñ┐αñªαÑìαñº αñ░αñ«αÑêαñ»αñ╛ αñ«αñéαññαÑìαñ░αñ┐αñ«αñéαñíαñ▓ αñùαñáαñ¿ αñ¬αñ░ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñåαñ▓αñ╛αñòαñ«αñ╛αñ¿ αñ╕αÑç αñòαñ░αÑçαñéαñùαÑç αñÜαñ░αÑìαñÜαñ╛αÑñ αñ¼αÑüαñºαñ╡αñ╛αñ░ [αñ╕αñéαñùαÑÇαññ] αñòαÑï αñíαÑÇ αñòαÑç αñ╢αñ┐αñ╡ αñòαÑüαñ«αñ╛αñ░ αñ▓αÑçαñéαñùαÑç αñ╕αÑÇαñÅαñ« αñ¬αñª αñòαÑÇ αñ╢αñ¬αñÑαÑñ\n6:10\n6 minutes, 10 seconds\nαñ╣αÑêαñªαñ░αñ╛αñ¼αñ╛αñª αñ«αÑçαñé αñ╣αÑïαñ¿αÑç αñ╡αñ╛αñ▓αÑÇ αññαÑçαñ▓αñéαñùαñ╛αñ¿αñ╛ αñ¿αñ╡αñ¿αñ┐αñ░αÑìαñ«αñ╛αñú αñ╕αñéαñòαñ▓αÑìαñ¬ αñ╕αñ¡αñ╛ αñòαÑï αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ¿αñ╣αÑÇαñé αñªαÑÇ αñçαñ£αñ╛αñ£αññαÑñ αñåαñéαñºαÑìαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñëαñ¬ αñ«αÑüαñûαÑìαñ»αñ«αñéαññαÑìαñ░αÑÇ αñöαñ░ αñ£αñ¿αñ╕αÑçαñ¿αñ╛ αñ¬αÑìαñ░αñ«αÑüαñû αñ¬αñ╡αñ¿ αñòαñ▓αÑìαñ»αñ╛αñú αñòαÑï αñåαñ£ αñòαñ░αñ¿αÑÇ αñÑαÑÇ αñ╕αñ¡αñ╛αÑñ\n6:23\n6 minutes, 23 seconds\nαñùαñ╛αñ» αñòαÑï αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αÑÇαñ» αñ¬αñ╢αÑü αñÿαÑïαñ╖αñ┐αññ αñòαñ░αñ¿αÑç αñòαÑÇ αñ«αñ╛αñéαñù αñòαñ░ αñ░αñ╣αÑç αñ«αÑîαñ▓αñ╛αñ¿αñ╛αñôαñé αñ¬αñ░ αñ¼αñ░αñ╕αÑç αñ╕αÑÇαñÅαñ« αñ»αÑïαñùαÑÇ αñòαñ╣αñ╛ αñòαñ┐ αñùαÑî αñ╣αñ«αñ╛αñ░αÑÇ αñ«αñ╛αññαñ╛ αñ╣αÑêαÑñ αñ£αñ¿αÑìαñ« αñ£αñ¿αÑìαñ«αñ╛αñéαññαñ░ αñòαñ╛ αñ¿αñ╛αññαñ╛\n6:30\n6 minutes, 30 seconds\nαñ╣αÑêαÑñ αñòαÑìαñ»αñ╛ αñ╣αÑê αñ«αñ╛αñé αñöαñ░ αñ¬αÑüαññαÑìαñ░ αñòαÑç αñ¼αÑÇαñÜ αñòαÑüαñ¢ [αñ╕αñéαñùαÑÇαññ] αñÿαÑïαñ╖αñ┐αññ αñòαñ░αñ¿αÑç αñòαÑÇ αñ£αñ░αÑéαñ░αññ?\n6:37\n6 minutes, 37 seconds\nαñùαÑî αñ«αñ╛αññαñ╛ αñòαÑç αñ«αÑüαñªαÑìαñªαÑç αñ¬αñ░ αñ╕αñ«αñ╛αñ£αñ╡αñ╛αñªαÑÇ αñ¬αñ╛αñ░αÑìαñƒαÑÇ αñ¿αÑç αñ╕αÑÇαñÅαñ« αñ»αÑïαñùαÑÇ αñòαÑï αñÿαÑçαñ░αñ╛αÑñ αñòαñ╣αñ╛ αñ╡αÑïαñƒ αñòαÑç αñ▓αñ┐αñÅ αñùαñ╛αñ» αñòαÑï αñåαñ░αñÅαñ╕αñÅαñ╕ αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñ¿αÑç αñÿαÑçαñ░αñ╛αÑñ αñ«αÑüαñûαÑìαñ»αñ«αñéαññαÑìαñ░αÑÇ αñ£αÑÇ αñ»αñ╣\n6:45\n6 minutes, 45 seconds\nαñ¼αññαñ╛αñÅαñé αñòαñ┐ αñ¬αÑìαñ░αñªαÑçαñ╢ αñ«αÑçαñé [αñ╕αñéαñùαÑÇαññ] αñòαñ¼ αñ░αÑüαñòαÑçαñùαÑÇ αñùαÑî αññαñ╕αÑìαñòαñ░αÑÇ?\n6:52\n6 minutes, 52 seconds\nαñùαñ╛αñ» αñòαÑç αñ«αÑüαñªαÑìαñªαÑç αñ¬αñ░ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñòαñ╛ αñ╣αñ«αñ▓αñ╛αÑñ αñòαñ╣αñ╛ αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñ¿αñ╣αÑÇαñé αñÿαÑïαñ╖αñ┐αññ αñòαñ░ αñ╕αñòαññαÑÇ αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αÑÇαñ» αñ¬αñ╢αÑü αñòαÑìαñ»αÑïαñéαñòαñ┐ αñûαññαÑìαñ« αñ╣αÑï αñ£αñ╛αñÅαñùαÑÇ αñëαñ¿αñòαÑÇ αñ░αñ╛αñ£αñ¿αÑÇαññαñ┐αÑñ\n6:57\n6 minutes, 57 seconds\nαñªαÑüαñ░αÑìαñ¡αñ╛αñùαÑìαñ» αñ╣αÑêαÑñ αñ╕αñéαñ╡αñ┐αñºαñ╛αñ¿ αñòαÑÇ αñ╢αñ¬αñÑ αñ▓αÑçαñ¿αÑç αñ╡αñ╛αñ▓αÑç αñ╕αÑÇαñÅαñ« αñ╢αñ╕αÑìαññαÑìαñ░ αñëαñáαñ╛αñ¿αÑç αñòαÑÇ αñ¼αñ╛αññ αñòαñ░αññαÑç αñ╣αÑêαñéαÑñ\n7:05\n7 minutes, 5 seconds\nαñùαñ╛αñ» αñòαÑç αñ«αÑüαñªαÑìαñªαÑç αñ¬αñ░ αñ¼αñ»αñ╛αñ¿αñ¼αñ╛αñ£αÑÇ αñ£αñ╛αñ░αÑÇ αñ╣αÑêαÑñ\n7:08\n7 minutes, 8 seconds\nαñåαñ░αñ£αÑçαñíαÑÇ αñ¬αÑìαñ░αñ╡αñòαÑìαññαñ╛ αñ«αÑâαññαÑìαñ»αÑüαñéαñ£αñ» αññαñ┐αñ╡αñ╛αñ░αÑÇ αñ¼αÑïαñ▓αÑç αñ»αÑéαñ¬αÑÇ αñ«αÑçαñé αñ╣αÑïαñ¿αÑç αñ╡αñ╛αñ▓αÑç αñ╣αÑêαñé αñÜαÑüαñ¿αñ╛αñ╡αÑñ αñÉαñ╕αÑç αñ«αÑçαñé αñ╡αÑïαñƒ αñòαÑç αñºαÑìαñ░αÑüαñ╡αÑÇαñòαñ░αñú αñòαÑç αñ▓αñ┐αñÅ αñªαñ┐αñÅ αñ£αñ╛ αñ░αñ╣αÑç αñ╣αÑêαñé αñÉαñ╕αÑç αñ¼αñ»αñ╛αñ¿αÑñ\n7:18\n7 minutes, 18 seconds\nαñ╕αÑÇαñÅαñ« αñ»αÑïαñùαÑÇ αñòαÑç αñ¼αñ»αñ╛αñ¿ αñ¬αñ░ αñÅαñåαñêαñÅαñ«αñåαñêαñÅαñ« αñ¿αÑçαññαñ╛ αñ╢αñ╛αñªαñ╛αñ¼ αñÜαÑîαñ╣αñ╛αñ¿ αñ¼αÑïαñ▓αÑç αñ»αÑïαñùαÑÇ αñ£αÑÇ αñÜαÑüαñ¿αñ╛αñ╡αÑÇ αñ«αÑïαñí αñ«αÑçαñé αñ¿αñ£αñ░ αñå αñ░αñ╣αÑç αñ╣αÑêαñéαÑñ αñ»αñ╣ αñªαÑüαñûαñª [αñ╕αñéαñùαÑÇαññ] αñ╣αÑê αñòαñ┐ αñ╡αÑç αñ¼αñ╛αñ░-αñ¼αñ╛αñ░ αñ¼αññαñ╛αññαÑç αñ╣αÑêαñé αñ╣αñ┐αñéαñªαÑüαñôαñé αñòαÑç αñ«αÑüαñûαÑìαñ»αñ«αñéαññαÑìαñ░αÑÇαÑñ\n7:29\n7 minutes, 29 seconds\nαñ¬αÑéαñ░αÑìαñúαñòαñ╛αñ▓αñ┐αñò αñíαÑÇαñ£αÑÇαñ¬αÑÇ αñ¼αñ¿αñ¿αÑç αñòαÑç αñ¼αñ╛αñª αñ░αñ╛αñ£αÑÇαñ╡ αñòαÑâαñ╖αÑìαñúαñ╛ αñ¿αÑç αñÅαñ¼αÑÇαñ¬αÑÇ αñ¿αÑìαñ»αÑéαñ£αñ╝ αñ╕αÑç αñòαñ╣αñ╛ αñ╕αÑÇαñÅαñ« αñ»αÑïαñùαÑÇ αñòαÑç αññαñ» αñ¼αñ┐αñéαñªαÑüαñôαñé αñ¬αñ░ αñòαñ░ αñ░αñ╣αÑç αñ╣αÑêαñé αñòαñ╛αñ«αÑñ αñàαñ▓αñù αñ╣αñ╛αñ▓αñ╛αññ αñ¼αñ¿αñ¿αÑç αñ¬αñ░ αñ╣αÑÇ αñ╣αÑïαññαñ╛ αñ╣αÑê αñÅαñ¿αñòαñ╛αñëαñéαñƒαñ░αÑñ\n7:41\n7 minutes, 41 seconds\nαñ»αÑéαñ¬αÑÇ αñòαÑç αñ«αñéαññαÑìαñ░αÑÇ αñ£αÑçαñ¬αÑÇαñÅαñ╕ αñ░αñ╛αñáαÑîαñ░ αñòαÑÇ αñàαñ¬αñ░αñ╛αñºαñ┐αñ»αÑïαñé αñòαÑï αñÜαÑçαññαñ╛αñ╡αñ¿αÑÇαÑñ αñòαñ╣αñ╛ αñÅαñ¿αñòαñ╛αñëαñéαñƒαñ░ αñ╕αÑç αñ¼αñÜαñ¿αñ╛ αñ╣αÑê αññαÑï αñòαñ░ αñªαÑçαñé αñ╕αñ░αÑçαñéαñíαñ░αÑñ αñ«αÑüαñáαñ¡αÑçαñíαñ╝ αñ«αÑçαñé αñ¬αÑüαñ▓αñ┐αñ╕αñòαñ░αÑìαñ«αÑÇ αñ¡αÑÇ αñÿαñ╛αñ»αñ▓ αñ╣αÑïαññαÑç αñ╣αÑêαñéαÑñ\n7:51\n7 minutes, 51 seconds\nαñ╢αñ┐αñ░αÑïαñ«αñúαñ┐ αñàαñòαñ╛αñ▓αÑÇ αñªαñ▓ αñòαÑç αñ¿αÑçαññαñ╛ αñ╡αñ┐αñòαÑìαñ░αñ« αñ╕αñ┐αñéαñ╣ αñ«αñ£αÑÇαñáαñ┐αñ»αñ╛ αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñ¬αñéαñ£αñ╛αñ¼ αñ¬αÑüαñ▓αñ┐αñ╕ αñòαñ╛ αñ▓αÑüαñòαñë αñ╕αñ░αÑìαñòαÑüαñ▓αñ░αÑñ αñàαñ¼ αñªαÑçαñ╢ αñ¢αÑïαñíαñ╝αñòαñ░ αñ¿αñ╣αÑÇαñé αñ£αñ╛ αñ╕αñòαÑçαñéαñùαÑç αñ«αñ£αÑÇαñáαñ┐αñ»αñ╛αÑñ αñÑαñ╛αñ¿αñ╛ αñ¬αñ░αñ┐αñ╕αñ░ αñ«αÑçαñé αñ╣αÑüαñê αñÿαñƒαñ¿αñ╛ αñòαÑç αñ¼αñ╛αñª αñ╕αÑç αñ½αñ░αñ╛αñ░ αñ╣αÑêαñé αñ«αñ£αÑÇαñáαñ┐αñ»αñ╛αÑñ\n8:06\n8 minutes, 6 seconds\nαñªαÑçαñ╢ αñ¡αñ░ αñ«αÑçαñé αñ╕αÑÇαñ¼αÑÇαñÅαñ╕αñê αñòαÑç αñ¬αÑïαñ░αÑìαñƒαñ▓ αñ«αÑçαñé αñûαñ░αñ╛αñ¼αÑÇ αñåαñê αñ£αñ┐αñ╕αñòαÑÇ αñ╡αñ£αñ╣ αñ╕αÑç αñ¢αñ╛αññαÑìαñ░αÑïαñé αñòαÑï αñ«αÑüαñ╢αÑìαñòαñ┐αñ▓αÑïαñé αñòαñ╛ αñ╕αñ╛αñ«αñ¿αñ╛ αñòαñ░αñ¿αñ╛ αñ¬αñíαñ╝αñ╛ αñöαñ░ αñ¬αÑéαñ░αÑç αñªαñ┐αñ¿ αñòαÑç αñçαñéαññαñ£αñ╛αñ░ αñòαÑç αñ¼αñ╛αñª αñ¡αÑÇ αñ¢αñ╛αññαÑìαñ░ αñ¿αñ┐αñ░αñ╛αñ╢ αñ¿αñ£αñ░ αñåαñÅαÑñ αññαÑï αñ╡αñ╣αÑÇαñé αñ¬αÑçαñ¬αñ░\n8:14\n8 minutes, 14 seconds\nαñ▓αÑÇαñò αñòαÑï αñ▓αÑçαñòαñ░ αñ╡αñ┐αñ¬αñòαÑìαñ╖ αñ▓αñùαñ╛αññαñ╛αñ░ αñ╕αñ░αñòαñ╛αñ░ αñ¬αñ░ αñ╣αñ«αñ▓αñ╛αñ╡αñ░ αñ╣αÑêαÑñ αñÉαñ╕αÑÇ αññαñ«αñ╛αñ« αñªαÑçαñ╢ αñòαÑÇ αñ¼αñíαñ╝αÑÇ αñûαñ¼αñ░αÑçαñé αñåαñ¬αñòαÑï αñªαñ┐αñûαñ╛ αñªαÑçαññαÑç αñ╣αÑêαñé αñ¿αÑëαñ░αÑìαñÑ αñ╕αñ┐αñƒαÑÇ αñ¿αÑìαñ»αÑéαñ£αñ╝ αñ«αÑçαñé αñ½αñƒαñ╛αñ½αñƒαÑñ\n8:24\n8 minutes, 24 seconds\nαñ¬αÑÇαñÅαñ« αñ«αÑïαñªαÑÇ αñ╕αÑç αñ«αñ┐αñ▓αÑç αñ«αÑìαñ»αñ╛αñéαñ«αñ╛αñ░ αñòαÑç αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ¬αññαñ┐αÑñ αñ¼αÑêαñáαñò αñòαÑç αñªαÑîαñ░αñ╛αñ¿ αñòαñ╣αñ╛ αñ¿αñ╣αÑÇαñé αñ╣αÑïαñ¿αÑç αñªαÑçαñéαñùαÑç αñ¡αñ╛αñ░αññ αñòαÑç αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñ╣αñ┐αññαÑïαñé αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñ«αÑìαñ»αñ╛αñéαñ«αñ╛αñ░ αñòαÑç αñçαñ▓αñ╛αñòαÑç αñòαñ╛ αñçαñ╕αÑìαññαÑçαñ«αñ╛αñ▓αÑñ\n8:33\n8 minutes, 33 seconds\nαñ«αÑìαñ»αñ╛αñéαñ«αñ╛αñ░ αñòαÑç αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ¬αññαñ┐, αñ¬αñ╛αñéαñÜ αñòαÑêαñ¼αñ┐αñ¿αÑçαñƒ αñ«αñéαññαÑìαñ░αñ┐αñ»αÑïαñé αñöαñ░ αñëαñÜαÑìαñÜ αñ╕αÑìαññαñ░αÑÇαñ» αñ¬αÑìαñ░αññαñ┐αñ¿αñ┐αñºαñ┐αñ«αñéαñíαñ▓ αñòαñ╛ αñ¡αñ╛αñ░αññ αñªαÑîαñ░αñ╛αÑñ αñ╡αñ┐αñªαÑçαñ╢ αñ«αñéαññαÑìαñ░αñ╛αñ▓αñ» αñòαÑç αñàαñ¿αÑüαñ╕αñ╛αñ░ αñªαÑìαñ╡αñ┐αñ¬αñòαÑìαñ╖αÑÇαñ» αñ«αÑüαñªαÑìαñªαÑïαñé αñ¬αñ░ αñ╡αñ┐αñ╕αÑìαññαñ╛αñ░ αñ╕αÑç αñ╣αÑüαñê αñ╣αÑê\n8:41\n8 minutes, 41 seconds\nαñÜαñ░αÑìαñÜαñ╛αÑñ αñ╕αñéαñ¬αñ░αÑìαñò αñ¼αñóαñ╝αñ╛αñ¿αÑç αñ¬αñ░ αñªαñ┐αñ»αñ╛ αñùαñ»αñ╛ αñ╣αÑê αñ£αÑïαñ░αÑñ\n8:47\n8 minutes, 47 seconds\nαñëαññαÑìαññαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñ«αÑüαñûαÑìαñ»αñ«αñéαññαÑìαñ░αÑÇ αñ»αÑïαñùαÑÇ αñåαñªαñ┐αññαÑìαñ»αñ¿αñ╛αñÑ αñòαñ╛ αñåαñ£ αñùαÑïαñ░αñûαñ¬αÑüαñ░ αñöαñ░ αñòαÑüαñ╢αÑÇαñ¿αñùαñ░ αñªαÑîαñ░αñ╛ αñ╣αÑïαñùαñ╛αÑñ αñ½αÑêαñòαÑìαñƒαÑìαñ░αÑÇ αñòαÑëαñ«αÑìαñ¬αÑìαñ▓αÑçαñòαÑìαñ╕ αñòαñ╛ αñòαñ░αÑçαñéαñùαÑç αñëαñªαÑìαñÿαñ╛αñƒαñ¿αÑñ αñòαÑüαñ╢αÑÇαñ¿αñùαñ░ αñ«αÑçαñé αñ£αñ¿αñ╕αñ¡αñ╛ αñòαÑï αñ¡αÑÇ αñ╕αñéαñ¼αÑïαñºαñ┐αññ αñòαñ░αÑçαñéαñùαÑç αñ╕αÑÇαñÅαñ« αñ»αÑïαñùαÑÇαÑñ\n9:01\n9 minutes, 1 second\nαñªαñ┐αñ▓αÑìαñ▓αÑÇ αñ«αÑçαñé αñ¬αñ╛αñ¿αÑÇ αñòαÑÇ αñòαñ┐αñ▓αÑìαñ▓αññ αñ╕αÑç αñ▓αÑïαñù αñ¬αñ░αÑçαñ╢αñ╛αñ¿ αñ╣αÑêαñéαÑñ αñåαñ£ αñªαñ┐αñ▓αÑìαñ▓αÑÇ αñòαÑç αñ£αñ▓ αñ«αñéαññαÑìαñ░αÑÇ αñ¬αÑìαñ░αñ╡αÑçαñ╢ αñ╡αñ░αÑìαñ«αñ╛ αñòαñ░αÑçαñéαñùαÑç αñ¬αÑìαñ░αÑçαñ╕ αñòαÑëαñ¿αÑìαñ½αÑìαñ░αÑçαñéαñ╕αÑñ αñªαñ┐αñ▓αÑìαñ▓αÑÇ αñ╡αñ╛αñ╕αñ┐αñ»αÑïαñé αñòαÑç αñ▓αñ┐αñÅ αñòαñ░ αñ╕αñòαññαÑç αñ╣αÑêαñé αñòαÑïαñê αñ¼αñíαñ╝αñ╛ αñÉαñ▓αñ╛αñ¿αÑñ\n9:13\n9 minutes, 13 seconds\nαñ¡αñ╛αñ░αññ αñöαñ░ αñ¼αÑìαñ░αñ┐αñƒαÑçαñ¿ αñòαÑç αñ¼αÑÇαñÜ αñ«αÑüαñûαÑìαñ» αñ╡αÑìαñ»αñ╛αñ¬αñ╛αñ░ αñ╕αñ«αñ¥αÑîαññαñ╛αÑñ αñ¼αÑìαñ░αñ┐αñƒαÑçαñ¿ αñòαÑç αñ╡αÑìαñ»αñ╛αñ¬αñ╛αñ░ αñ«αñéαññαÑìαñ░αÑÇ αñåαñ£ αñ¬αñ╣αÑüαñéαñÜαÑçαñéαñùαÑç αñ¡αñ╛αñ░αññαÑñ αñ╕αñ«αñ¥αÑîαññαÑç αñòαÑï αñ▓αñ╛αñùαÑé αñòαñ░αñ¿αÑç αñòαÑÇ αñ¬αÑìαñ░αñòαÑìαñ░αñ┐αñ»αñ╛ αñ¬αñ░ αñ¬αÑÇαñ»αÑéαñ╖ αñùαÑïαñ»αñ▓ αñòαÑç αñ╕αñ╛αñÑ αñ¼αÑêαñáαñò αñ╣αÑïαñùαÑÇαÑñ\n9:25\n9 minutes, 25 seconds\nαñòαÑâαñ╖αñ╛ αñ╢αñ░αÑìαñ«αñ╛ αñ«αÑîαññ αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñ╕αñ«αñ░αÑìαñÑ αñöαñ░ αñùαñ┐αñ░αñ╡αñ╛αñ▓αñ╛ αñ╕αñ┐αñéαñ╣ αñòαÑÇ αñ░αñ┐αñ«αñ╛αñéαñí αñåαñ£ αñûαññαÑìαñ« αñ╣αÑï αñ░αñ╣αÑÇ αñ╣αÑêαÑñ αñªαÑïαñ¿αÑïαñé αñåαñ░αÑïαñ¬αñ┐αñ»αÑïαñé αñòαÑï αñåαñ£ αñòαÑïαñ░αÑìαñƒ αñ«αÑçαñé αñ¬αÑçαñ╢ αñòαñ┐αñ»αñ╛ αñ£αñ╛αñÅαñùαñ╛αÑñ αñ╕αÑïαñ«αñ╡αñ╛αñ░ αñòαÑï αñòαÑìαñ░αñ╛αñçαñ« αñ╕αÑÇαñ¿ αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛ αñÑαñ╛ αñ░αñ┐αñòαñòαÑìαñ░αñ┐αñÅαñƒαÑñ\n9:38\n9 minutes, 38 seconds\nαñ▓αñéαñ¼αÑç αñçαñéαññαñ£αñ╛αñ░ αñòαÑç αñ¼αñ╛αñª αñ╕αÑÇαñ¼αÑÇαñÅαñ╕αñê αñòαñ╛ αñ¬αÑïαñ░αÑìαñƒαñ▓ 2 αñ£αÑéαñ¿ αñ╕αÑç αñ╢αÑüαñ░αÑé αñ╣αÑï αñùαñ»αñ╛ αñ╣αÑêαÑñ αñ╕αÑÇαñ¼αÑÇαñÅαñ╕αñê αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñàαñ¼ αñáαÑÇαñò αñ╕αÑç αñòαñ╛αñ« αñòαñ░ αñ░αñ╣αñ╛ αñ╣αÑê αñ¬αÑïαñ░αÑìαñƒαñ▓αÑñ αñ¢αñ╛αññαÑìαñ░ αñåαñ╕αñ╛αñ¿αÑÇ αñ╕αÑç αñòαñ░ αñ╕αñòαññαÑç [αñ╕αñéαñùαÑÇαññ] αñ╣αÑêαñé αñåαñ╡αÑçαñªαñ¿αÑñ\n9:50\n9 minutes, 50 seconds\nαñ╕αÑÇαñ¼αÑÇαñÅαñ╕αñê αñ¿αÑç αñ¬αñ╣αñ▓αÑç 1 αñ£αÑéαñ¿ αñòαÑï αñ¬αÑïαñ░αÑìαñƒαñ▓ αñ╢αÑüαñ░αÑé αñ╣αÑïαñ¿αÑç αñòαñ╛ αñ¡αñ░αÑïαñ╕αñ╛ αñªαñ┐αñ»αñ╛ αñÑαñ╛αÑñ αñ¢αñ╛αññαÑìαñ░αÑïαñé αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñ╕αÑÇαñ¼αÑÇαñÅαñ╕αñê αñ¿αÑç αñªαÑïαñ¬αñ╣αñ░ 2:45 αñ¼αñ£αÑç αññαñò αñ¬αÑïαñ░αÑìαñƒαñ▓ αñ╢αÑüαñ░αÑé αñ╣αÑïαñ¿αÑç αñòαñ╛ αñ¡αñ░αÑïαñ╕αñ╛ αñªαñ┐αñ»αñ╛ αñÑαñ╛αÑñ\n10:01\n10 minutes, 1 second\nαñöαñ░ 1 αñ£αÑéαñ¿ αñòαÑç αñ¼αñ£αñ╛αñ» αñåαñ£ αñÜαñ▓αñ╛ αñ╣αÑê αñ╕αÑÇαñ¼αÑÇαñÅαñ╕αñê αñòαñ╛ αñ¬αÑïαñ░αÑìαñƒαñ▓αÑñ αñªαÑçαñ╢ αñ¡αñ░ αñ«αÑçαñé αñ¢αñ╛αññαÑìαñ░ αñòαñ▓ αñªαñ┐αñ¿ αñ¡αñ░ αñ¬αñ░αÑçαñ╢αñ╛αñ¿ αñ░αñ╣αÑç αñ╣αÑêαñéαÑñ αñàαñ▓αÑÇαñùαñóαñ╝ αñòαÑç αñ¢αñ╛αññαÑìαñ░ αñ╢αñ┐αñ╡αñ« αñíαñ╛αñùαñ░ αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñòαÑìαñ»αÑïαñé αñ¼αñÜαÑìαñÜαÑïαñé αñòαÑï αñƒαÑëαñ░αÑìαñÜαñ░ αñòαñ┐αñ»αñ╛ αñ£αñ╛ αñ░αñ╣αñ╛ αñ╣αÑêαÑñ\n10:14\n10 minutes, 14 seconds\nαñòαñ▓ αñ╕αÑÇαñ¼αÑÇαñÅαñ╕αñê αñ¬αÑïαñ░αÑìαñƒαñ▓ αñ¿αñ╣αÑÇαñé αñûαÑüαñ▓αñ¿αÑç αñ╕αÑç αñªαÑçαñ╢ αñ¡αñ░ αñ«αÑçαñé αñ¢αñ╛αññαÑìαñ░ αñ¬αñ░αÑçαñ╢αñ╛αñ¿ αñ░αñ╣αÑçαÑñ αñ£αñ«αÑìαñ«αÑé αñòαÑÇ αñ¢αñ╛αññαÑìαñ░ αñåαñòαñ╛αñéαñòαÑìαñ╖αñ╛ αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñ¬αñ╣αñ▓αÑç αññαÑï αñùαñ▓αññ αñ¬αÑçαñ¬αñ░ αñ¡αÑçαñ£ αñªαñ┐αñÅ αñùαñÅ αñöαñ░ αñàαñ¼ αñ¬αÑïαñ░αÑìαñƒαñ▓ αññαñò αñ¿αñ╣αÑÇαñé αñûαÑüαñ▓αñ╛αÑñ\n10:24\n10 minutes, 24 seconds\nαñ╕αÑÇαñ¼αÑÇαñÅαñ╕αñê αñôαñÅαñ╕αñÅαñ« αñ╕αñ┐αñ╕αÑìαñƒαñ« αñ«αÑçαñé αñùαñíαñ╝αñ¼αñíαñ╝αÑÇ αñöαñ░ αññαÑÇαñ¿ αñ¡αñ╛αñ╖αñ╛ αñòαÑç αñ½αñ╛αñ░αÑìαñ«αÑéαñ▓αÑç αñòαñ╛ αñ«αÑüαñªαÑìαñªαñ╛ αñåαñ£ αñ╢αñ┐αñòαÑìαñ╖αñ╛ αñ«αñéαññαÑìαñ░αñ╛αñ▓αñ» αñòαÑÇ αñ╕αñéαñ╕αñªαÑÇαñ» αñ╕αñ«αñ┐αññαñ┐ αñòαÑÇ [αñ╕αñéαñùαÑÇαññ] αñ¼αÑêαñáαñòαÑñ αñ╕αÑÇαñ¼αÑÇαñÅαñ╕αñê αñÜαÑçαñ»αñ░αñ«αÑêαñ¿ αñ╕αÑìαñòαÑéαñ▓ αñ╢αñ┐αñòαÑìαñ╖αñ╛ αñ╡αñ┐αñ¡αñ╛αñù αñòαÑç αñ╕αñÜαñ┐αñ╡ αñ╢αñ╛αñ«αñ┐αñ▓ αñ╣αÑïαñéαñùαÑçαÑñ\n10:37\n10 minutes, 37 seconds\nαñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñ¿αÑçαññαñ╛ αñªαñ┐αñùαÑìαñ╡αñ┐αñ£αñ» αñ╕αñ┐αñéαñ╣ αñ¿αÑç αñòαñ╣αñ╛ αñºαñ░αÑìαñ«αÑçαñéαñªαÑìαñ░ αñ¬αÑìαñ░αñºαñ╛αñ¿ αñ╕αÑç αñ¬αñ░αÑçαñ╢αñ╛αñ¿αÑñ αñ¬αÑÇαñÅαñ« αñ«αÑïαñªαÑÇ αñ¿αÑç αñ▓αÑÇ αñ╣αÑê αñàαñ¼ 21 αñ£αÑéαñ¿ αñòαÑÇ αñ¿αÑÇαñƒ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛ αñòαÑÇ αñ£αñ┐αñ«αÑìαñ«αÑçαñªαñ╛αñ░αÑÇαÑñ αñàαñùαñ░ αñ½αñ┐αñ░ αñ¡αÑÇ αñ¬αÑçαñ¬αñ░ αñ▓αÑÇαñò αñ╣αÑïαñùαñ╛ αññαÑï αñ«αñ╛αñéαñùαÑçαñéαñùαÑç αñ¬αÑÇαñÅαñ« αñ«αÑïαñªαÑÇ αñòαñ╛ αñçαñ╕αÑìαññαÑÇαñ½αñ╛αÑñ\n10:48\n10 minutes, 48 seconds\nαñ╕αÑÇαñ¼αÑÇαñÅαñ╕αñê αñòαÑÇ αñùαñíαñ╝αñ¼αñíαñ╝αñ┐αñ»αÑïαñé αñòαÑï αñ▓αÑçαñòαñ░ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñ╣αñ«αñ▓αñ╛αñ╡αñ░ αñ╣αÑêαÑñ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñ¿αÑçαññαñ╛ αñ╕αÑüαñ¬αÑìαñ░αñ┐αñ»αñ╛ αñ╢αÑìαñ░αÑÇαñ¿αÑçαññ αñ¿αÑç αñòαñ╣αñ╛ αñ¢αñ╛αññαÑìαñ░ αñ¿αñ╛αñ░αñ╛αñ£ αñ╣αÑêαÑñ αñƒαÑÇαñÜαñ░ αñ¬αñ░αÑçαñ╢αñ╛αñ¿ αñ╣αÑêαÑñ αñ«αÑïαñªαÑÇ αñ╕αñ░αñòαñ╛αñ░ αñ¿αÑç αñ╡αñ╛αñòαñê αñ«αÑçαñé αñ╢αñ┐αñòαÑìαñ╖αñ╛ αñòαñ╛ αñ¡αñƒαÑìαñƒαñ╛ αñ¼αÑêαñáαñ╛ αñªαñ┐αñ»αñ╛ αñ╣αÑêαÑñ\n11:01\n11 minutes, 1 second\nαñ¿αÑÇαñƒ αñ¬αÑçαñ¬αñ░ αñ▓αÑÇαñò αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñåαñ░αÑïαñ¬αñ┐αñ»αÑïαñé αñòαÑÇ αñåαñ£ αñòαÑïαñ░αÑìαñƒ αñ¬αÑìαñ░αñ╡αÑç αñ¬αÑçαñ╢αÑÇαÑñ αñ¬αñ╛αñéαñÜ αñåαñ░αÑïαñ¬αñ┐αñ»αÑïαñé αñòαÑï αñ░αñ╛αñëαñ¿αÑÇ αñòαÑïαñ░αÑìαñƒ αñ«αÑçαñé αñòαñ┐αñ»αñ╛ αñ£αñ╛αñÅαñùαñ╛ αñ¬αÑçαñ╢αÑñ αñòαÑïαñ░αÑìαñƒ αñ¼αñóαñ╝αñ╛ αñ╕αñòαññαñ╛ αñ╣αÑê αñåαñ░αÑïαñ¬αñ┐αñ»αÑïαñé αñòαÑÇ αñ░αñ┐αñ«αñ╛αñéαñíαÑñ\n11:12\n11 minutes, 12 seconds\nαñ«αñ╣αñ╛αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░ αñòαÑç αñ¼αÑÇαñíαñ╝ αñ«αÑçαñé αñ¿αÑÇαñƒ αñ¬αÑçαñ¬αñ░ αñ▓αÑÇαñò αñòαÑç αñåαñ░αÑïαñ¬αÑÇ αñ¬αÑÇαñ╡αÑÇ αñòαÑüαñ▓αñòαñ░αÑìαñúαÑÇ αñòαÑç αñ¿αñ┐αñ░αÑìαñ«αñ╛αñúαñ╛αñºαÑÇαñ¿ αñ¼αñéαñùαñ▓αÑç αñ¬αñ░ αñ¼αÑüαñ▓αñíαÑïαñ£αñ░ αñÜαñ▓αñ╛αÑñ αñÅαñò αñ╣αñ½αÑìαññαÑç αñ¬αñ╣αñ▓αÑç αñ¿αÑïαñƒαñ┐αñ╕ αñªαÑçαñòαñ░ αñ░αÑüαñòαñ╛αñ»αñ╛ αñùαñ»αñ╛ αñÑαñ╛ αñ¿αñ┐αñ░αÑìαñ«αñ╛αñú αñòαñ╛αñ░αÑìαñ»αÑñ αñòαÑüαñ▓αñòαñ░αÑìαñúαÑÇ αñ¬αñ░ αñàαñ╡αÑêαñº αñ¿αñ┐αñ░αÑìαñ«αñ╛αñú αñòαñ░αñ╛αñ¿αÑç αñòαñ╛ αñåαñ░αÑïαñ¬αÑñ\n11:25\n11 minutes, 25 seconds\nαñ¿αÑÇαñƒ, αñ╕αÑÇαñ¼αÑÇαñÅαñ╕αñê αñöαñ░ αñªαÑéαñ╕αñ░αÑÇ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛αñôαñé αñ«αÑçαñé αñùαñíαñ╝αñ¼αñíαñ╝αÑÇ αñòαñ╛ αñ╡αñ┐αñ░αÑïαñºαÑñ αñ╢αñ┐αñòαÑìαñ╖αñ╛ αñ«αñéαññαÑìαñ░αñ╛αñ▓αñ» αñòαÑç αñ¼αñ╛αñ╣αñ░ αñæαñ▓ αñçαñéαñíαñ┐αñ»αñ╛ αñ╕αÑìαñƒαÑéαñíαÑçαñéαñƒαÑìαñ╕ αñÅαñ╕αÑïαñ╕αñ┐αñÅαñ╢αñ¿ αñ¿αÑç αñ¬αÑìαñ░αñªαñ░αÑìαñ╢αñ¿ αñòαñ┐αñ»αñ╛αÑñ αñ«αñ╛αñéαñùαñ╛ αñòαÑçαñéαñªαÑìαñ░αÑÇαñ» αñ╢αñ┐αñòαÑìαñ╖αñ╛\n11:33\n11 minutes, 33 seconds\nαñ«αñéαññαÑìαñ░αÑÇ αñºαñ░αÑìαñ«αÑçαñéαñªαÑìαñ░ [αñ╕αñéαñùαÑÇαññ] αñ¬αÑìαñ░αñºαñ╛αñ¿ αñòαñ╛ αñçαñ╕αÑìαññαÑÇαñ½αñ╛αÑñ\n11:39\n11 minutes, 39 seconds\nαñ£αÑçαñêαñê αñÅαñíαñ╡αñ╛αñéαñ╕ 2026 αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛ αñòαÑç αñ¿αññαÑÇαñ£αÑç αñÿαÑïαñ╖αñ┐αññ αñòαñ┐αñÅ αñùαñÅαÑñ αñªαñ░αÑìαñ╢ αñ╕αñ┐αñòαÑìαñòαñ╛ αñ¿αÑç αñ╣αñ╛αñ╕αñ┐αñ▓ αñòαñ┐αñÅαÑñ αñæαñ▓ αñçαñéαñíαñ┐αñ»αñ╛ αñ«αÑçαñé 10αñ╡αÑÇαñé αñ░αÑêαñéαñòαÑñ αñòαñ╣αñ╛ αñòαñ┐ αñ╣αñ«αÑçαñ╢αñ╛ αñåαñêαñåαñêαñƒαÑÇ αñ«αÑçαñé αñ£αñ╛αñ¿αÑç αñòαñ╛ αñëαñ¿αñòαñ╛ αñ╕αñ¬αñ¿αñ╛ αñ░αñ╣αñ╛ αñ╣αÑêαÑñ\n11:52\n11 minutes, 52 seconds\nαñ¬αÑìαñ░αñ»αñ╛αñùαñ░αñ╛αñ£ αñ«αÑçαñé αñ¬αÑçαñ¬αñ░ αñ▓αÑÇαñò αñòαÑç αñ«αÑüαñªαÑìαñªαÑç αñ¬αñ░ αñ╕αñéαñ£αñ» αñ╕αñ┐αñéαñ╣ αñ¡αñ┐αñíαñ╝αÑç αñÅαñíαÑÇαñÅαñ« αñ╕αñ┐αñƒαÑÇ αñ╕αÑç αñëαñ¿αñòαÑÇ αññαÑÇαñûαÑÇ αñ¿αÑïαñòαñ¥αÑïαñéαñò αñ╣αÑï αñùαñêαÑñ αñ«αÑÇαñƒαñ┐αñéαñù αñòαÑï αñ░αÑïαñòαñ¿αÑç αñ¬αñ░ αñòαñ╣αñ╛ αñ╕αñ░αÑìαñòαñ┐αñƒ αñ╣αñ╛αñëαñ╕ αñ«αÑçαñé αñ«αÑÇαñƒαñ┐αñéαñù αñòαÑç αñ▓αñ┐αñÅ αñçαñ£αñ╛αñ£αññ αñòαÑÇ αñ£αñ░αÑéαñ░αññ αñ¿αñ╣αÑÇαñéαÑñ\n12:04\n12 minutes, 4 seconds\nαñ╕αÑüαñ¬αÑìαñ░αÑÇαñ« αñòαÑïαñ░αÑìαñƒ αñ«αÑçαñé αñåαñ£ αñ¬αñ╛αñéαñÜ αñ¿αñÅ αñ£αñ£αÑçαñ╕ αñòαñ╛ αñ╢αñ¬αñÑ αñùαÑìαñ░αñ╣αñú αñ╣αÑïαñùαñ╛αÑñ αñÜαÑÇαñ½ αñ£αñ╕αÑìαñƒαñ┐αñ╕ αñ╕αÑéαñ░αÑìαñ»αñòαñ╛αñéαññ αñ╕αÑüαñ¼αñ╣ 10:30 αñ¼αñ£αÑç αñ£αñ£αÑçαñ╕ αñòαÑï αñªαñ┐αñ▓αñ╛αñÅαñéαñùαÑç αñ¬αñª αñòαÑÇ αñ╢αñ¬αñÑαÑñ 37\n12:11\n12 minutes, 11 seconds\nαñ╣αÑï αñ£αñ╛αñÅαñùαÑÇ αñ╕αÑüαñ¬αÑìαñ░αÑÇαñ« αñòαÑïαñ░αÑìαñƒ αñ«αÑçαñé αñ£αñ£αÑïαñé αñòαÑÇ αñ╕αñéαñûαÑìαñ»αñ╛αÑñ αñåαñêαñåαñ░αñ╕αÑÇαñƒαÑÇαñ╕αÑÇ αñ╕αÑç αñ£αÑüαñíαñ╝αñ╛ αñ╣αÑüαñå αñ╕αÑÇαñ¼αÑÇαñåαñê αñòαñ╛ αñ«αñ╛αñ«αñ▓αñ╛αÑñ\n12:18\n12 minutes, 18 seconds\nαñåαñ£ αñ░αñ╛αñ╡ αñ£αñ«αñ¿αÑÇ αñòαÑïαñ░αÑìαñƒ αñ«αÑçαñé αñ╣αÑïαñùαÑÇ αñ╕αÑüαñ¿αñ╡αñ╛αñêαÑñ αñòαÑïαñ░αÑìαñƒ αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñùαñ╡αñ╛αñ╣αÑïαñé αñòαÑç αñ¼αñ»αñ╛αñ¿ αñòαñ░ αñ░αñ╣αñ╛ αñ╣αÑê αñªαñ░αÑìαñ£αÑñ\n12:26\n12 minutes, 26 seconds\nαñ£αñ«αÑÇαñ¿ αñòαÑç αñ¼αñªαñ▓αÑç αñ¿αÑîαñòαñ░αÑÇ αñ╕αÑç αñ£αÑüαñíαñ╝αñ╛ αñ╕αÑÇαñ¼αÑÇαñåαñê αñòαñ╛ αñ«αñ╛αñ«αñ▓αñ╛αÑñ αñ░αñ╛αñëαñ¿ αñòαÑïαñ░αÑìαñƒ αñ«αÑçαñé αñåαñ£ αñ╣αÑïαñùαÑÇ αñ╕αÑüαñ¿αñ╡αñ╛αñêαÑñ\n12:30\n12 minutes, 30 seconds\nαñ╕αÑÇαñ¼αÑÇαñåαñê αñ¿αÑç αñªαñ╛αñûαñ┐αñ▓ αñòαÑÇ αñ╣αÑê αñ▓αñ╛αñ▓αÑé αññαÑçαñ£αñ╕αÑìαñ╡αÑÇ αñ░αñ╛αñ¼αñíαñ╝αÑÇ αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñÜαñ╛αñ░αÑìαñ£αñ╢αÑÇαñƒαÑñ\n12:37\n12 minutes, 37 seconds\nαñàαñùαñ╕αÑìαññαñ╛ αñ╡αÑçαñ╕αÑìαñƒαñ▓αÑêαñéαñí αñ╣αÑçαñ▓αÑÇαñòαÑëαñ¬αÑìαñƒαñ░ αñÿαÑïαñƒαñ╛αñ▓αñ╛ αñ«αñ╛αñ«αñ▓αñ╛αÑñ αñ╕αÑÇαñ¼αÑÇαñåαñê αñöαñ░ αñêαñíαÑÇ αñòαÑÇ αñªαñ╛αñûαñ┐αñ▓ αñÜαñ╛αñ░αÑìαñ£αñ╢αÑÇαñƒ αñ¬αñ░ αñåαñ£ αñ░αñ╛αñëαñ£αñ╝ αñ░αÑçαñ╡αÑçαñ¿αÑìαñ»αÑé αñòαÑïαñ░αÑìαñƒ αñ«αÑçαñé αñ╕αÑüαñ¿αñ╡αñ╛αñê αñ╣αÑïαñùαÑÇαÑñ\n12:46\n12 minutes, 46 seconds\nαñëαññαÑìαññαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢ αñ«αÑçαñé αñ¼αñ┐αñ£αñ▓αÑÇ αñëαñ¬αñ¡αÑïαñòαÑìαññαñ╛αñôαñé αñòαÑï 10 αñêαñéαñºαñ¿ αñ╕αñ░αñÜαñ╛αñ░αÑìαñ£ αñ╕αÑç αñ«αñ┐αñ▓ αñ╕αñòαññαÑÇ αñ╣αÑê αñ«αÑüαñòαÑìαññαñ┐αÑñ\n12:50\n12 minutes, 50 seconds\nαñ╡αñ┐αñªαÑìαñ»αÑüαññ αñ¿αñ┐αñ»αñ╛αñ«αñò αñåαñ»αÑïαñù αñ¿αÑç αñ»αÑéαñ¬αÑÇαñ¬αÑÇαñ╕αÑÇαñÅαñ▓ αñòαÑç αñ½αÑêαñ╕αñ▓αÑç αñ¬αñ░ αñ╕αñ╡αñ╛αñ▓ αñëαñáαñ╛αñÅ αñ╣αÑêαñéαÑñ 10% αñàαñºαñ┐αñ¡αñ╛αñ░ αñ¼αñóαñ╝αñ╛αñ¿αÑç αñòαÑï αñ¼αññαñ╛αñ»αñ╛ αñùαÑêαñ░ αñòαñ╛αñ¿αñ╛αñ¿αÑéαñ¿αÑÇαÑñ\n13:00\n13 minutes\nαñöαñ░ αñàαñ¼ αñ¿αÑîαñ╕αÑç αñ¿αÑìαñ»αÑéαñ£αñ╝ αñ╕αÑç αñ¼αñ╛αññ αñòαñ░αÑçαñéαñùαÑç αñàαñ¬αñ░αñ╛αñº αñ£αñùαññ αñ╕αÑç αñ£αÑüαñíαñ╝αÑÇ αñ╣αÑüαñê αñûαñ¼αñ░αÑïαñé αñòαñ╛ αñöαñ░ αñ£αñ╛αñ¿αÑçαñéαñùαÑç αñòαñ┐ αñòαñ╣αñ╛αñé αñ«αñ░αÑìαñíαñ░ αñ╕αÑç αñ╕αñ¿αñ╕αñ¿αÑÇ αñ½αÑêαñ▓αÑÇαÑñ αñòαñ╣αñ╛αñé αñÜαñ▓ αñ░αñ╣αñ╛ αñÑαñ╛\n13:07\n13 minutes, 7 seconds\nαñ╕αñƒαÑìαñƒαÑç αñòαñ╛ αñ¬αÑéαñ░αñ╛ αñòαñ╛αñ░αÑïαñ¼αñ╛αñ░αÑñ αñòαÑêαñ╕αÑç αñ╣αÑüαñê αñªαÑï αñ«αñ╛αñ╕αÑéαñ« αñ¼αñÜαÑìαñÜαÑïαñé αñòαÑÇ αñ«αÑîαññαÑñ αñªαñ┐αñûαñ╛ αñªαÑçαññαÑç αñ╣αÑêαñé αñåαñ¬αñòαÑï αñ½αñƒαñ╛αñ½αñƒαÑñ\n13:16\n13 minutes, 16 seconds\nαñàαñ╕αñ« αñòαÑç αñ¿αñ▓αñ¼αñ╛αñíαñ╝αÑÇ αñ«αÑçαñé αñ¢αñ╛αññαÑìαñ░ αñ╕αñéαñÿ αñ¿αÑçαññαñ╛ αñòαÑÇ αñ╣αññαÑìαñ»αñ╛ αñòαñ╛ αñåαñ░αÑïαñ¬αÑÇ αñ«αÑüαñáαñ¡αÑçαñíαñ╝ αñ«αÑçαñé αñóαÑçαñ░αÑñ αñåαñ░αÑïαñ¬αÑÇ αñ¿αÑç αñ«αÑâαñªαÑüαñ£αñ» αñ¼αñ░αÑìαñ«αñ¿ αñöαñ░ αñëαñ¿αñòαÑÇ αñ¼αñ╣αñ¿ αñ¬αñ░ αñòαñ┐αñ»αñ╛ αñÑαñ╛\n13:25\n13 minutes, 25 seconds\nαñàαñƒαÑêαñòαÑñ αñ╣αñ«αñ▓αÑç αñ«αÑçαñé αñ«αÑâαñªαÑüαñ£αñ» αñ¼αñ░αÑìαñ«αñ¿ αñòαÑÇ αñ╣αÑüαñê αñÑαÑÇ αñ«αÑîαññαÑñ αñ¼αñ╣αñ¿ αñòαñ╛ αñçαñ▓αñ╛αñ£ αñ£αñ╛αñ░αÑÇ αñ╣αÑêαÑñ αñªαñ┐αñ▓αÑìαñ▓αÑÇ αñòαÑç αñ«αÑüαñûαñ░αÑìαñ£αÑÇ αñ¿αñùαñ░ αñ«αÑçαñé αñûαÑéαñ¿αÑÇ αñ╡αñ╛αñ░αñªαñ╛αññαÑñ\n13:33\n13 minutes, 33 seconds\nαñùαñªαÑìαñªαÑç αñòαÑÇ αñªαÑüαñòαñ╛αñ¿ αñ«αÑçαñé αñ╕αñ╛αñÑ αñòαñ╛αñ« αñòαñ░αñ¿αÑç αñ╡αñ╛αñ▓αÑç αñ╢αñûαÑìαñ╕ αñ¿αÑç αñàαñ¬αñ¿αÑç αñ╕αñ╣αñòαñ░αÑìαñ«αÑÇ αñòαÑÇ αñòαÑêαñéαñÜαÑÇ αñ╕αÑç αñ╣αñ«αñ▓αñ╛ αñòαñ░ αñ£αñ╛αñ¿ αñ▓αÑÇαÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñåαñ░αÑïαñ¬αÑÇ αñàαñ╢αñ½αñ╛αñò αñòαÑï αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛αÑñ\n13:42\n13 minutes, 42 seconds\nαñªαñ┐αñ▓αÑìαñ▓αÑÇ αñòαÑç αñ¿αÑìαñ»αÑé αñëαñ╕αÑìαñ«αñ╛αñ¿ αñ¿αñùαñ░ αñ«αÑçαñé αñëαñ╕αÑìαñ«αñ╛αñ¿αñ¬αÑüαñ░ αñ«αÑçαñé αñ¿αñ╛αñ¼αñ╛αñ▓αñ┐αñò αñ▓αñíαñ╝αñòαÑç αñòαÑÇ αñÜαñ╛αñòαÑé αñ«αñ╛αñ░αñòαñ░ αñ╣αññαÑìαñ»αñ╛αÑñ\n13:47\n13 minutes, 47 seconds\nαñ╡αñ╛αñ░αñªαñ╛αññ αñ«αÑçαñé αñ╢αñ╛αñ«αñ┐αñ▓ αñ¼αññαñ╛αñÅ αñ£αñ╛ αñ░αñ╣αÑç αñ╣αÑêαñé 10 αñ╕αÑç 12 αñ▓αÑïαñùαÑñ αñåαñ░αÑïαñ¬αñ┐αñ»αÑïαñé αñòαÑÇ αññαñ▓αñ╛αñ╢ αñ«αÑçαñé αñ£αÑüαñƒαÑÇ αñ╣αÑê αñ¬αÑüαñ▓αñ┐αñ╕αÑñ\n13:54\n13 minutes, 54 seconds\nαñ¼αñ┐αñ╣αñ╛αñ░ αñòαÑç αñòαñ┐αñ╢αñ¿αñùαñéαñ£ αñ«αÑçαñé αñ╕αñéαñªαñ┐αñùαÑìαñº αñ╣αñ╛αñ▓αññ αñ«αÑçαñé αñ╕αñ╛αññαñ╡αÑÇαñé αñòαÑìαñ▓αñ╛αñ╕ αñòαÑÇ αñ¢αñ╛αññαÑìαñ░αñ╛ αñòαÑÇ αñ«αÑîαññ αñ╣αÑï αñùαñêαÑñ\n13:58\n13 minutes, 58 seconds\nαñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ¬αñ░αñ┐αñ£αñ¿αÑïαñé αñòαÑÇ αñ╢αñ┐αñòαñ╛αñ»αññ αñ¬αñ░ αñòαñ┐αñ»αñ╛ αñ«αñ╛αñ«αñ▓αñ╛ αñªαñ░αÑìαñ£αÑñ αñ£αñ╛αñéαñÜ αñòαñ░ αñ░αñ╣αÑÇ αñ╣αÑê αñ¬αÑüαñ▓αñ┐αñ╕αÑñ\n14:05\n14 minutes, 5 seconds\nαñ░αñ╛αñ£αñºαñ╛αñ¿αÑÇ αñªαñ┐αñ▓αÑìαñ▓αÑÇ αñ¼αñªαñ«αñ╛αñ╢αÑïαñé αñòαÑç αñ╣αÑîαñ╕αñ▓αÑç αñ¼αÑüαñ▓αñéαñª αñ╣αÑêαÑñ αñ¿αÑìαñ»αÑé αñëαñ╕αÑìαñ«αñ╛αñ¿αñ¬αÑüαñ░ αñçαñ▓αñ╛αñòαÑç αñ«αÑçαñé αñòαÑêαñƒαñ░αñ┐αñéαñù αñòαñ╛αñ░αÑïαñ¼αñ╛αñ░αÑÇ αñòαÑÇ αñªαÑüαñòαñ╛αñ¿ αñòαÑç αñ¼αñ╛αñ╣αñ░ αññαñ╛αñ¼αñíαñ╝αññαÑïαñíαñ╝ αñ½αñ╛αñ»αñ░αñ┐αñéαñù αñ╣αÑüαñêαÑñ αñ╕αñíαñ╝αñò αñ╕αÑç αñùαÑüαñ£αñ░ αñ░αñ╣αÑç αñ¼αñÜαÑìαñÜαÑç αñòαÑï αñùαÑïαñ▓αÑÇ αñ▓αñùαÑÇαÑñ\n14:15\n14 minutes, 15 seconds\nαñ«αÑüαñ░αñ╛αñªαñ╛αñ¼αñ╛αñª αñ«αÑçαñé αñ¼αñ╛αñçαñò αñ╕αñ╡αñ╛αñ░ αñ¼αñªαñ«αñ╛αñ╢αÑïαñé αñòαÑÇ αññαñ╛αñ¼αñíαñ╝αññαÑïαñíαñ╝ αñ½αñ╛αñ»αñ░αñ┐αñéαñùαÑñ αñùαÑïαñ▓αÑÇ αñ▓αñùαñ¿αÑç αñ╕αÑç αñ»αÑüαñ╡αñò αñÿαñ╛αñ»αñ▓ αñ╣αÑï αñùαñ»αñ╛αÑñ αñªαÑïαñ¿αÑïαñé αñ¬αñòαÑìαñ╖αÑïαñé αñòαÑç αñ¼αÑÇαñÜ αñÜαñ▓ αñ░αñ╣αñ╛ αñ╣αÑê αñ╡αñ┐αñ╡αñ╛αñªαÑñ\n14:24\n14 minutes, 24 seconds\nαñ╕αñ╣αñ╛αñ░αñ¿αñ¬αÑüαñ░ αñ«αÑçαñé αñ╡αÑìαñ»αñ╛αñ¬αñ╛αñ░αÑÇ αñòαÑÇ αñ¬αññαÑìαñ¿αÑÇ αñòαÑÇ αñ╣αññαÑìαñ»αñ╛ αñ╕αÑç αñ╕αñ¿αñ╕αñ¿αÑÇαÑñ αñ╡αñ╛αñ░αñªαñ╛αññ αñòαÑç αñ╕αñ«αñ» αñÿαñ░ αñ«αÑçαñé αñàαñòαÑçαñ▓αÑÇ αñÑαÑÇ αñ«αñ╣αñ┐αñ▓αñ╛αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ«αñ╛αñ«αñ▓αÑç αñòαÑÇ αñ£αñ╛αñéαñÜ αñ╢αÑüαñ░αÑé αñòαÑÇαÑñ\n14:34\n14 minutes, 34 seconds\nαñ╣αñ░αñ┐αñ»αñ╛αñúαñ╛ αñòαÑç αñ½αñ░αÑÇαñªαñ╛αñ¼αñ╛αñª αñ«αÑçαñé αñ«αñ╣αñ┐αñ▓αñ╛ αñòαÑÇ αñ╕αñéαñªαñ┐αñùαÑìαñº αñ¬αñ░αñ┐αñ╕αÑìαñÑαñ┐αññαñ┐αñ»αÑïαñé αñ«αÑçαñé αñ«αÑîαññ αñ╣αÑï αñùαñêαÑñ αñ«αñ╣αñ┐αñ▓αñ╛ αñòαÑç αñ«αñ╛αñ»αñòαÑç αñ╡αñ╛αñ▓αÑïαñé αñ¿αÑç αñ¬αññαñ┐ αñ¬αñ░ αñ▓αñùαñ╛αñ»αñ╛ αñ╣αÑê αñ╣αññαÑìαñ»αñ╛ αñòαñ╛ αñåαñ░αÑïαñ¬αÑñ αñàαñ╡αÑêαñº αñ╕αñéαñ¼αñéαñºαÑïαñé αñòαÑç αñÜαñ▓αññαÑç αñ╣αññαÑìαñ»αñ╛ αñòαñ╛ αñ╢αñò αñ╣αÑêαÑñ\n14:46\n14 minutes, 46 seconds\nαñ«αÑçαñ░αñá αñ«αÑçαñé αñ¿αÑçαñ╢αñ¿αñ▓ αñòαñ¼αñíαÑìαñíαÑÇ αñûαñ┐αñ▓αñ╛αñíαñ╝αÑÇ αñàαñ¿αÑüαñ╖αÑìαñòαñ╛ αñ╣αññαÑìαñ»αñ╛αñòαñ╛αñéαñí αñ¬αñ░ αñ¬αñ░αñ┐αñ£αñ¿αÑïαñé αñ¿αÑç αñëαñáαñ╛αñÅ αñ╕αñ╡αñ╛αñ▓αÑñ αñòαñ╣αñ╛ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ£αÑï αñ╢αñ╡ αñ¼αñ░αñ╛αñ«αñª αñòαñ┐αñ»αñ╛ αñ╡αÑï αñàαñ¿αÑüαñ╖αÑìαñòαñ╛ αñòαñ╛ αñ╣αÑê αñ╣αÑÇ αñ¿αñ╣αÑÇαñéαÑñ αñ¬αñ░αñ┐αñ£αñ¿αÑïαñé αñ¿αÑç αñòαñéαñòαñ░αñûαÑçαñíαñ╝αñ╛ αñÑαñ╛αñ¿αÑç αñ¬αñ░ αñòαñ┐αñ»αñ╛ αñ£αñ«αñòαñ░ αñ╣αñéαñùαñ╛αñ«αñ╛αÑñ\n15:00\n15 minutes\nαñçαñƒαñ╛αñ╡αñ╛ αñ«αÑçαñé αñûαÑçαññ αñ«αÑçαñé αñ╕αñéαñªαñ┐αñùαÑìαñº αñ╕αÑìαñÑαñ┐αññαñ┐ αñ«αÑçαñé αñ«αñ┐αñ▓αÑç αñªαÑï αñ¼αñÜαÑìαñÜαÑïαñé αñòαÑç αñ╢αñ╡αÑñ αñÿαñ░ αñ╕αÑç αñûαÑçαñ▓αñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ αñ¿αñ┐αñòαñ▓αÑç αñÑαÑç αñªαÑïαñ¿αÑïαñé αñ¼αñÜαÑìαñÜαÑçαÑñ αñ¬αñ░αñ┐αñ£αñ¿αÑïαñé αñ¿αÑç αñòαÑÇ αñ╣αÑê αñ«αñ╛αñ«αñ▓αÑç αñòαÑÇ [αñ╕αñéαñùαÑÇαññ] αñ£αñ╛αñéαñÜ αñòαñ░ αñ£αñ▓αÑìαñª αñûαÑüαñ▓αñ╛αñ╕αñ╛ αñòαñ░αñ¿αÑç αñòαÑÇ αñ«αñ╛αñéαñùαÑñ\n15:12\n15 minutes, 12 seconds\nαñùαñ╛αñ£αñ┐αñ»αñ╛αñ¼αñ╛αñª αñòαÑç αñ╕αÑéαñ░ αñ╣αññαÑìαñ»αñ╛αñòαñ╛αñéαñí αñòαÑç αñ╡αñ┐αñ░αÑïαñº αñ«αÑçαñé αñ«αÑüαñ░αñ╛αñªαñ╛αñ¼αñ╛αñª αñ«αÑçαñé αñ¬αÑìαñ░αñªαñ░αÑìαñ╢αñ¿ αñ╣αÑüαñåαÑñ αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αÑÇαñ» αñ¼αñ£αñ░αñéαñù αñªαñ▓ αñ¿αÑç αñ¬αÑìαñ░αñªαñ░αÑìαñ╢αñ¿ αñòαñ┐αñ»αñ╛αÑñ αñ░αñ╛αñ«αñùαñéαñùαñ╛ αñ¿αñªαÑÇ αñ«αÑçαñé αñ¬αÑìαñ░αñ╡αñ╛αñ╣αñ┐αññ αñòαÑÇ αñ¬αÑìαñ░αññαÑÇαñòαñ╛αññαÑìαñ«αñò αñàαñ╕αÑìαñÑαñ┐αñ»αñ╛αñéαÑñ\n15:24\n15 minutes, 24 seconds\nαñ»αÑéαñ¬αÑÇ αñòαÑç αñëαñ¿αÑìαñ¿αñ╛αñ╡ αñ«αÑçαñé αñ¿αñ╣αñ░ αñòαñ┐αñ¿αñ╛αñ░αÑç αñ«αñ┐αñ▓αÑç αñ«αñ╣αñ┐αñ▓αñ╛ αñöαñ░ αñ¬αÑüαñ░αÑüαñ╖ αñòαÑç αñ╢αñ╡αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ╢αñ╡αÑïαñé αñòαÑï αñòαñ¼αÑìαñ£αÑç αñ«αÑçαñé αñ▓αÑçαñòαñ░ αñ¬αÑïαñ╕αÑìαñƒαñ«αñ╛αñ░αÑìαñƒαñ« [αñ╕αñéαñùαÑÇαññ] αñòαÑç αñ▓αñ┐αñÅ αñ¡αÑçαñ£αñ╛αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ£αññαñ╛αñê αÑ¢αñ╣αñ░ αñûαñ╛αñòαñ░ αñûαÑüαñªαñòαÑüαñ╢αÑÇ αñòαñ░αñ¿αÑç αñòαÑÇ αñåαñ╢αñéαñòαñ╛αÑñ\n15:35\n15 minutes, 35 seconds\nαñ¿αÑïαñÅαñíαñ╛ αñòαÑç αñ╣αÑïαñƒαñ▓ αñ«αÑçαñé αñÜαñ▓ αñ░αñ╣αÑç αñ£αÑüαñå αñ░αÑêαñòαÑçαñƒ αñòαñ╛ αñ╣αÑüαñå αñûαÑüαñ▓αñ╛αñ╕αñ╛αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç 20 αñòαñƒαÑïαñ░αñ┐αñ»αÑïαñé αñòαÑïαñéαñùαÑç αñ╣αñ╛αñÑαÑïαñé αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛αÑñ αñ▓αñ╛αñûαÑïαñé αñòαÑÇ αñ¿αñòαñªαÑÇ, αñ▓αñùαÑìαñ£αñ░αÑÇ αñùαñ╛αñíαñ╝αñ┐αñ»αñ╛αñé αñöαñ░ αñ«αÑïαñ¼αñ╛αñçαñ▓ αñ½αÑïαñ¿ αñ¼αñ░αñ╛αñ«αñªαÑñ\n15:49\n15 minutes, 49 seconds\nαñ╣αñ░αñ┐αñ»αñ╛αñúαñ╛ αñòαñ╛ αñ¬αÑìαñ░αñªαÑÇαñ¬ αñ╣αññαÑìαñ»αñ╛αñòαñ╛αñéαñíαÑñ αñ¡αñ┐αñ╡αñ╛αñ¿αÑÇ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ¢αñ╣ αñåαñ░αÑïαñ¬αñ┐αñ»αÑïαñé αñòαÑï αñàαñ░αÑçαñ╕αÑìαñƒ αñòαñ┐αñ»αñ╛αÑñ αñ«αÑüαñûαÑìαñ» αñåαñ░αÑïαñ¬αÑÇ αñ¡αÑÇ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛αÑñ\n15:58\n15 minutes, 58 seconds\nαñ«αñºαÑìαñ» αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñ¼αÑêαññαÑéαñ▓ αñ«αÑçαñé αñƒαÑìαñ░αÑçαñ¿ αñòαÑÇ αñ╕αÑÇαñƒ αñòαÑï αñ▓αÑçαñòαñ░ αñ╣αÑüαñê αñ╡αñ┐αñ╡αñ╛αñª αñ«αÑçαñé αñ»αÑüαñ╡αñò αñòαÑÇ αñ╣αññαÑìαñ»αñ╛αÑñ αñ¬αÑÇαñƒαÑñ\n16:02\n16 minutes, 2 seconds\nαñ¬αÑÇαñƒ αñòαñ░ αñëαññαñ╛αñ░αñ╛ αñ«αÑîαññ αñòαÑç αñÿαñ╛αñƒαÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñåαñ░αÑïαñ¬αñ┐αñ»αÑïαñé αñòαÑÇ αñòαñ░ αñ░αñ╣αÑÇ αñ╣αÑê αññαñ▓αñ╛αñ╢αÑñ\n16:08\n16 minutes, 8 seconds\nαñªαñ┐αñ▓αÑìαñ▓αÑÇ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ¿αñòαñ▓αÑÇ αñåαñ░αÑïαñ¬ αñ½αñ┐αñ▓αÑìαñƒαñ░ αñ¼αñ¿αñ╛αñ¿αÑç αñ╡αñ╛αñ▓αÑç αñùαÑêαñéαñù αñòαñ╛ αñ¬αñ░αÑìαñªαñ╛αñ½αñ╛αñ╢ αñòαñ┐αñ»αñ╛αÑñ αñ½αÑêαñòαÑìαñƒαÑìαñ░αÑÇ αñòαÑç αñ«αñ╛αñ▓αñ┐αñò αñòαÑï αñ«αÑîαñòαÑç αñ╕αÑç αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛αÑñ\n16:22\n16 minutes, 22 seconds\nαñªαÑçαñ╢ αñòαÑç αñàαñ▓αñù-αñàαñ▓αñù αñ░αñ╛αñ£αÑìαñ»αÑïαñé αñòαÑÇ αñ¼αñíαñ╝αÑÇ αñûαñ¼αñ░αÑçαñéαÑñ αñàαñ¼ αñåαñ¬αñòαÑï αñªαñ┐αñûαñ╛ αñªαÑçαññαÑç αñ╣αÑêαñé αñöαñ░ αñåαñ¬αñòαÑï αñ¼αññαñ╛ αñªαÑçαññαÑç αñ╣αÑêαñé αñòαñ╣αñ╛αñé αñ¬αñ░ αñåαñù αñ╕αÑç αñ«αñÜαñ╛ αñ╣αÑüαñå αñ╣αÑê αñ╣αñ╛αñ╣αñ╛αñòαñ╛αñ░αÑñ\n16:28\n16 minutes, 28 seconds\nαñ▓αÑüαñºαñ┐αñ»αñ╛αñ¿αñ╛ αñ«αÑçαñé αñ½αÑêαñòαÑìαñƒαÑìαñ░αÑÇ αñòαÑêαñ╕αÑç αñ¼αñ¿αÑÇ αñùαÑêαñ╕ αñÜαÑçαñéαñ¼αñ░ αñöαñ░ αñòαñ╣αñ╛αñé αñ▓αñ╛αñ¬αññαñ╛ αñ╣αÑüαñÅ αñ¬αñ░αÑìαñ╡αññαñ╛αñ░αÑïαñ╣αÑÇαÑñ αñªαñ┐αñûαñ╛ αñªαÑçαññαÑç αñ╣αÑêαñé αñ¬αÑéαñ░αÑÇ αñûαñ¼αñ░ αñ½αñƒαñ╛αñ½αñƒαÑñ\n16:38\n16 minutes, 38 seconds\nαñùαñ╛αñ£αñ┐αñ»αñ╛αñ¼αñ╛αñª αñòαÑÇ αñÅαñò αñ«αñ▓αÑìαñƒαÑÇ αñ╕αÑìαñƒαÑïαñ░αÑÇ αñ¼αñ┐αñ▓αÑìαñíαñ┐αñéαñù αñ«αÑçαñé αñ▓αñùαÑÇ αñ¡αÑÇαñ╖αñú αñåαñùαÑñ αñ▓αÑïαñùαÑïαñé αñòαÑï αñ╕αÑÇαñóαñ╝αñ┐αñ»αÑïαñé αñòαÑç αñ╕αñ╣αñ╛αñ░αÑç αñ¼αñ╛αñ╣αñ░ αñ¿αñ┐αñòαñ╛αñ▓αñ╛ αñùαñ»αñ╛αÑñ αñåαñù αñ¬αñ░ αñ½αñ╛αñ»αñ░ αñ¼αÑìαñ░αñ┐αñùαÑçαñí αñòαÑÇ αñªαÑï αñùαñ╛αñíαñ╝αñ┐αñ»αÑïαñé αñ¿αÑç αñòαñ╛αñ¼αÑé αñ¬αñ╛αñ»αñ╛αÑñ\n16:50\n16 minutes, 50 seconds\nαñ¬αñéαñ£αñ╛αñ¼ αñ«αÑçαñé αñ½αÑêαñòαÑìαñƒαÑìαñ░αÑÇ αñ«αÑçαñé αñùαÑêαñ╕ αñ▓αÑÇαñò αñ╣αÑïαñ¿αÑç αñ╕αÑç αñ╣αÑüαñå αñ╣αñ╛αñªαñ╕αñ╛αÑñ αñ▓αÑüαñºαñ┐αñ»αñ╛αñ¿αñ╛ αñòαÑÇ αñ½αÑêαñòαÑìαñƒαÑìαñ░αÑÇ αñ«αÑçαñé αññαÑÇαñ¿ αñ▓αÑïαñùαÑïαñé αñòαÑÇ αñ«αÑîαññ αñòαÑÇ αñ£αñ╛αñ¿αñòαñ╛αñ░αÑÇαÑñ αñ«αñ╢αÑÇαñ¿ αñƒαÑéαñ▓αÑìαñ╕ αñ¼αñ¿αñ╛αñ¿αÑç αñòαÑÇ αñ½αÑêαñòαÑìαñƒαÑìαñ░αÑÇ αñ«αÑçαñé αñ╣αÑüαñå αñ»αñ╣ αñ╣αñ╛αñªαñ╕αñ╛αÑñ\n17:00\n17 minutes\nαñùαñ╛αñ£αÑÇαñ¬αÑüαñ░ αñ«αÑçαñé αñ╣αÑïαñƒαñ▓ αñ╡αÑìαñ»αñ╡αñ╕αñ╛αñê αñ╡αñ┐αñ¿αÑÇαññ αñ░αñ╛αñ» αñòαÑÇ αñ╣αññαÑìαñ»αñ╛ αñòαñ╛ αñ«αñ╛αñ«αñ▓αñ╛αÑñ αñ¬αÑÇαñíαñ╝αñ┐αññ αñ¬αñ░αñ┐αñ╡αñ╛αñ░ αñ╕αÑç αñ«αñ┐αñ▓αñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ αñ¬αñ╣αÑüαñéαñÜαÑç αñÅαñ╕αñ¬αÑÇ αñêαñ░αñ£ αñ░αñ╛αñ£αñ╛αÑñ αñåαñ░αÑïαñ¬αñ┐αñ»αÑïαñé αñòαÑÇ αñ£αñ▓αÑìαñª αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░αÑÇ αñòαñ╛ αñ¡αñ░αÑïαñ╕αñ╛ αñªαñ┐αñ»αñ╛αÑñ αñ¼αÑüαñ▓αñíαÑïαñ£αñ░ αñòαñ╛αñ░αñ╡αñ╛αñê αñòαÑç αñ¡αÑÇ αñ╕αñéαñòαÑçαññ [αñ╕αñéαñùαÑÇαññ] αñªαñ┐αñÅαÑñ\n17:12\n17 minutes, 12 seconds\nαñùαñ╛αñ£αÑÇαñ¬αÑüαñ░ αñ«αÑçαñé αñ╕αñ░αñòαñ╛αñ░αÑÇ αñ╕αñ┐αñ╕αÑìαñƒαñ« αñòαÑÇ αñ¿αñ╛αñòαñ╛αñ«αÑÇ αñ╕αÑç αñûαñ½αñ╛ αñ»αÑüαñ╡αñòαÑñ αñƒαñ╛αñ╡αñ░ αñ¬αñ░ αñÜαñóαñ╝ αñùαñ»αñ╛αÑñ αñ£αñ«αÑÇαñ¿ αñ╡αñ┐αñ╡αñ╛αñª αñ«αÑçαñé αñçαñéαñ╕αñ╛αñ½ αñ¿αñ╛ αñ«αñ┐αñ▓αñ¿αÑç αñ¬αñ░ αñ¿αñ╛αñ░αñ╛αñ£ αñÑαñ╛ αñ»αÑüαñ╡αñòαÑñ\n17:19\n17 minutes, 19 seconds\nαñ¬αÑìαñ░αñ╢αñ╛αñ╕αñ¿ αñòαÑç αñòαñ╛αñ½αÑÇ αñ╕αñ«αñ¥αñ╛αñ¿αÑç αñòαÑç αñ¼αñ╛αñª αñƒαñ╛αñ╡αñ░ αñ╕αÑç αñ¿αÑÇαñÜαÑç αñëαññαñ░αñ╛ αñ»αÑüαñ╡αñòαÑñ αñ«αÑüαñ╣αñ░αÑìαñ░αñ« αñòαÑï αñ▓αÑçαñòαñ░ αñ▓αñûαñ¿αñè αñ¬αÑüαñ▓αñ┐αñ╕ αñòαÑÇ αññαÑêαñ»αñ╛αñ░αÑñ\n17:27\n17 minutes, 27 seconds\nαñíαÑÇαñ╕αÑÇαñ¬αÑÇ αñ¬αñ╢αÑìαñÜαñ┐αñ« αñòαñ«αñ▓αÑçαñ╢ αñªαÑÇαñòαÑìαñ╖αñ┐αññ αñ¿αÑç αñ╣αÑüαñ╕αÑêαñ¿αñ╛αñ¼αñ╛αñª αñ«αÑçαñé αñ¬αÑêαñªαñ▓ αñùαñ╢αÑìαññ αñòαñ┐αñ»αñ╛αÑñ αñ¼αñíαñ╝αÑç αñçαñ«αñ╛αñ«αñ¼αñ╛αñíαñ╝αñ╛ αñöαñ░ αñ¢αÑïαñƒαÑç αñçαñ«αñ╛αñ«αñ¼αñ╛αñíαñ╝αñ╛ αñòαñ╛ αñ¿αñ┐αñ░αÑÇαñòαÑìαñ╖αñú αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛αÑñ\n17:34\n17 minutes, 34 seconds\nαñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñ╡αÑìαñ»αñ╡αñ╕αÑìαñÑαñ╛αñôαñé αñòαñ╛ αñ¡αÑÇ αñ£αñ╛αñ»αñ£αñ╛ αñ▓αñ┐αñ»αñ╛αÑñ\n17:39\n17 minutes, 39 seconds\nαñ«αñ╣αÑïαñ¼αñ╛ αñ«αÑçαñé αñ╕αñ░αñòαñ╛αñ░αÑÇ αñùαñ╛αñíαñ╝αÑÇ αñ¢αÑïαñíαñ╝αñòαñ░ αñ¼αÑêαñ▓αñùαñ╛αñíαñ╝αÑÇ αñ¬αñ░ αñ╕αñ╡αñ╛αñ░ αñ╣αÑüαñÅ αñ╕αÑÇαñêαñô αñ░αñ╡αñ┐αñòαñ╛αñéαññ αñùαÑîαñ░αÑñ αñ╡αñ░αÑìαñªαÑÇ αñ«αÑçαñé αñ¼αÑêαñ▓αñùαñ╛αñíαñ╝αÑÇ αñÜαñ▓αñ╛αññαÑç αñ╕αÑÇαñô αñòαñ╛ αñ╡αÑÇαñíαñ┐αñ»αÑï αñ╡αñ╛αñ»αñ░αñ▓ αñ╣αÑï αñ░αñ╣αñ╛ αñ╣αÑêαÑñ\n17:50\n17 minutes, 50 seconds\nαñëαññαÑìαññαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñ¼αñ░αÑçαñ▓αÑÇ αñòαÑÇ αññαñ╕αÑìαñ╡αÑÇαñ░ αñ¼αñªαñ▓αñ¿αÑç αñòαÑÇ αññαÑêαñ»αñ╛αñ░αÑÇαÑñ αñ«αÑçαñùαñ╛ αñ½αÑéαñí αñ¬αñ╛αñ░αÑìαñò αñòαñ╛ αñ¿αñ┐αñ░αÑìαñ«αñ╛αñú αñ╣αÑê αñ£αñ╛αñ░αÑÇαÑñ αñöαñªαÑìαñ»αÑïαñùαñ┐αñò αñ╡αñ┐αñòαñ╛αñ╕ αñòαÑï αñ«αñ┐αñ▓αÑçαñùαñ╛ αñçαñ╕αñ╕αÑç αñ¼αñóαñ╝αñ╛αñ╡αñ╛αÑñ\n18:01\n18 minutes, 1 second\nαñ£αñ«αÑìαñ«αÑé αñòαñ╢αÑìαñ«αÑÇαñ░ αñ«αÑçαñé αñ¿αñ╢αñ╛ αñ«αÑüαñòαÑìαññαñ┐ αñàαñ¡αñ┐αñ»αñ╛αñ¿ αñòαÑüαñ▓αñùαñ╛αñ« αñ«αÑçαñé αñ▓αÑïαñùαÑïαñé αñòαÑï αñ£αñ╛αñùαñ░αÑéαñò αñòαñ░αñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ αñ¬αñª αñ»αñ╛αññαÑìαñ░αñ╛ αñ¿αñ┐αñòαñ╛αñ▓αÑÇ αñùαñêαÑñ αñëαñ¬αñ░αñ╛αñ£αÑìαñ»αñ¬αñ╛αñ▓ αñ«αñ¿αÑïαñ£ αñ╕αñ┐αñ¿αÑìαñ╣αñ╛ αñ¡αÑÇ αñ╢αñ╛αñ«αñ┐αñ▓ αñ╣αÑüαñÅαÑñ\n18:13\n18 minutes, 13 seconds\nαññαñ«αñ┐αñ▓αñ¿αñ╛αñíαÑü αñ«αÑçαñé αñ╕αñíαñ╝αñòαÑïαñé αñ¬αñ░ αñëαññαñ░αÑç αñòαñ┐αñ╕αñ╛αñ¿αÑñ αñ¼αÑçαñ▓αÑîαñ░ αñ«αÑçαñé αñòαñ░αÑÇαñ¼ 600 αñòαñ┐αñ╕αñ╛αñ¿αÑïαñé αñ¿αÑç αñ¬αÑìαñ░αñªαñ░αÑìαñ╢αñ¿ αñòαñ┐αñ»αñ╛αÑñ αñ¬αÑéαñ░αñ╛ αñòαñ░αÑìαñ£ αñ«αñ╛αñ½ αñòαñ░αñ¿αÑç αñòαÑÇ αñ«αñ╛αñéαñù αñòαÑÇ αñùαñêαÑñ\n18:24\n18 minutes, 24 seconds\nαñ╣αñ«αÑÇαñ░αñ¬αÑüαñ░ αñ«αÑçαñé αñ£αñ╛αñéαñÜ αñƒαÑÇαñ« αñ¿αÑç αñ¼αÑçαñƒαñ╡αñ╛ αñ¬αÑüαñ▓ αñòαÑç αñ¬αñ┐αñ▓αñ░ αñöαñ░ αñ«αñ▓αñ╡αÑç αñòαñ╛ αñ¿αñ┐αñ░αÑÇαñòαÑìαñ╖αñú αñòαñ┐αñ»αñ╛αÑñ αñòαñéαñòαÑìαñ░αÑÇαñƒ αñöαñ░ αñ╕αñ░αñ┐αñ»αñ╛ αñòαÑç αñ¿αñ«αÑéαñ¿αÑç αñ▓αñ┐αñÅαÑñ αñ£αñ╛αñéαñÜ αñòαÑç αñ▓αñ┐αñÅ αñ¼αÑÇαñÅαñÜαñ»αÑé αñåαñêαñåαñêαñƒαÑÇ αñ▓αÑêαñ¼ αñ¡αÑçαñ£αÑç αñ£αñ╛αñÅαñéαñùαÑç αñ╕αÑêαñéαñ¬αñ▓αÑìαñ╕αÑñ\n18:37\n18 minutes, 37 seconds\nαñòαÑçαñªαñ╛αñ░αñ¿αñ╛αñÑ αñºαñ╛αñ« αñ«αÑçαñé αñàαñ¼ αññαñò 10 αñ▓αñ╛αñû αñ╕αÑç αñàαñºαñ┐αñò αñ╢αÑìαñ░αñªαÑìαñºαñ╛αñ▓αÑü αñ¿αÑç αñªαñ░αÑìαñ╢αñ¿ αñòαñ┐αñÅ αñ╣αÑêαñéαÑñ 22 αñàαñ¬αÑìαñ░αÑêαñ▓ αñ╕αÑç αñ╢αÑüαñ░αÑé αñ╣αÑüαñê αñÑαÑÇ αñòαÑçαñªαñ╛αñ░αñ¿αñ╛αñÑ αñºαñ╛αñ« αñòαÑÇ αñ»αñ╛αññαÑìαñ░αñ╛αÑñ αñ¼αñ╛αñ¼αñ╛ αñòαÑçαñªαñ╛αñ░ αñòαÑç αñ¡αñòαÑìαññαÑïαñé αñ«αÑçαñé αñ╣αÑê αñòαñ╛αñ½αÑÇ αñëαññαÑìαñ╕αñ╛αñ╣αÑñ\n18:49\n18 minutes, 49 seconds\nαñëαññαÑìαññαñ░αñ╛αñûαñéαñí αñòαÑç αñ¬αñ┐αñéαñíαñ╛αñ░αÑÇ αñùαÑìαñ▓αÑçαñ╢αñ┐αñ»αñ░ αñ«αÑçαñé αñƒαÑìαñ░αÑêαñòαñ┐αñéαñù αñòαÑç αñ▓αñ┐αñÅ αñùαñ»αñ╛ αñ╕αñ╣αñ╛αñ░αñ¿αñ¬αÑüαñ░ αñòαñ╛ αñ»αÑüαñ╡αñò αñ▓αñ╛αñ¬αññαñ╛ αñ╣αÑï αñùαñ»αñ╛ αñ╣αÑêαÑñ αñ╕αñ░αÑìαñÜ αñƒαÑÇαñ«αÑçαñé αñ¼αÑÇαññαÑç αñªαÑï αñªαñ┐αñ¿ αñ╕αÑç αñ»αÑüαñ╡αñò αñòαÑÇ αññαñ▓αñ╛αñ╢ αñòαñ░ αñ░αñ╣αÑÇ αñ╣αÑêαñéαÑñ αñùαñ╛αñçαñí αñ¿αÑç αñªαÑÇ αñ▓αñ╛αñ¬αññαñ╛ αñ╣αÑïαñ¿αÑç αñòαÑÇ αñ╕αÑéαñÜαñ¿αñ╛αÑñ\n19:01\n19 minutes, 1 second\nαñªαñ╛αñ░αñ╛ αñ¼αÑüαñùαñ┐αñ»αñ╛αñ▓ αñƒαÑìαñ░αÑêαñò αñ¬αñ░ αñÿαÑéαñ«αñ¿αÑç αñùαñê αñ░αñ╛αñ«αñ¿αñùαñ░ αñòαÑÇ αñ¼αñ¼αÑÇαññαñ╛ αñ¬αñ╛αñéαñíαÑç αñ▓αñ╛αñ¬αññαñ╛αÑñ αñ¬αñ┐αñ¢αñ▓αÑç αñÜαñ╛αñ░ αñªαñ┐αñ¿αÑïαñé αñ╕αÑç αñ¿αñ╣αÑÇαñé αñ▓αñù αñ¬αñ╛αñ»αñ╛ αñòαÑïαñê αñ╕αÑüαñ░αñ╛αñùαÑñ αñ╕αñ░αÑìαñÜ αñƒαÑÇαñ«αÑçαñé αñ▓αñùαñ╛αññαñ╛αñ░ αñòαñ░ αñ░αñ╣αÑÇ αñ╣αÑê αñ¼αñ¼αÑÇαññαñ╛ αñòαÑÇ αññαñ▓αñ╛αñ╢αÑñ\n19:13\n19 minutes, 13 seconds\nαñ¼αÑüαñ▓αñéαñªαñ╢αñ╣αñ░ αñ«αÑçαñé αñ¼αñ╛αñçαñò αñ¬αñ░ αñ£αñ╛αñ¿αñ▓αÑçαñ╡αñ╛ αñ╕αÑìαñƒαñéαñƒαñ¼αñ╛αñ£αÑÇαÑñ αñÅαñò αñ¼αñ╛αñçαñò αñ¬αñ░ αñ╕αñ╛αññ αñ▓αÑïαñùαÑïαñé αñ¿αÑç αñòαñ┐αñ»αñ╛ αñ╕αÑìαñƒαÑêαñéαñíαÑñ\n19:18\n19 minutes, 18 seconds\nαñ╕αñ╡αñ╛αñ░αÑïαñé αñ«αÑçαñé αñ¿αñ╛αñ¼αñ╛αñ▓αñ┐αñò αñ¡αÑÇ αñ╢αñ╛αñ«αñ┐αñ▓αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ╡αñ╛αñ»αñ░αñ▓ αñ╡αÑÇαñíαñ┐αñ»αÑï αñòαñ╛ αñ╕αñéαñ£αÑìαñ₧αñ╛αñ¿ αñ▓αñ┐αñ»αñ╛αÑñ\n19:25\n19 minutes, 25 seconds\nαñ¿αÑî αñ╕αÑçαñòαñéαñí αñ¿αÑìαñ»αÑéαñ£αñ╝ αñ«αÑçαñé αñªαÑçαñ╢ αñ¡αñ░ αñòαÑç αñ«αÑîαñ╕αñ« αñòαñ╛ αñ╣αñ╛αñ▓ αñ¡αÑÇ αñàαñ¼ αñåαñ¬αñòαÑï αñ¼αññαñ╛ αñªαÑçαññαÑç αñ╣αÑêαñé αñ½αñƒαñ╛αñ½αñƒαÑñ\n19:32\n19 minutes, 32 seconds\nαñ«αÑîαñ╕αñ« αñ╡αñ┐αñ¡αñ╛αñù αñ¿αÑç αñªαÑÇ αñ╣αÑê αñÅαñò αñ░αñ╛αñ╣αññ αñ¡αñ░αÑÇ αñûαñ¼αñ░αÑñ αñöαñ░ αñàαñùαñ▓αÑç αñªαÑï αñ╕αÑç αññαÑÇαñ¿ αñªαñ┐αñ¿αÑïαñé αñ«αÑçαñé αñòαÑçαñ░αñ▓ αñ«αÑçαñé αñªαñòαÑìαñ╖αñ┐αñú αñ¬αñ╢αÑìαñÜαñ┐αñ« αñ«αñ╛αñ¿αñ╕αÑéαñ¿ αñòαÑç αñåαñ¿αÑç αñòαÑÇ αñ╕αñéαñ¡αñ╛αñ╡αñ¿αñ╛ αñ╣αÑêαÑñ\n19:42\n19 minutes, 42 seconds\nαñ«αñºαÑìαñ» αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñëαñ£αÑìαñ£αÑêαñ¿ αñ«αÑçαñé αñåαñéαñºαÑÇ αñòαÑç αñ╕αñ╛αñÑ αññαÑçαñ£ αñ¼αñ╛αñ░αñ┐αñ╢ αñ╣αÑüαñêαÑñ αñ«αÑîαñ╕αñ« αñòαÑç αñòαñ░αñ╡αñƒ αñ▓αÑçαñ¿αÑç αñ╕αÑç αññαñ╛αñ¬αñ«αñ╛αñ¿ αñ«αÑçαñé αñùαñ┐αñ░αñ╛αñ╡αñƒ αñªαñ░αÑìαñ£αÑñ αñ▓αÑïαñùαÑïαñé αñòαÑï αñÜαñ┐αñ▓αñÜαñ┐αñ▓αñ╛αññαÑÇ αñùαñ░αÑìαñ«αÑÇ αñ╕αÑç αñÑαÑïαñíαñ╝αÑÇ αñ░αñ╛αñ╣αññ αñ«αñ┐αñ▓αÑÇαÑñ\n19:54\n19 minutes, 54 seconds\nαñ£αÑêαñ╕αñ▓αñ«αÑçαñ░ αñ«αÑçαñé αñåαñéαñºαÑÇ αñòαÑç αñ╕αñ╛αñÑ αññαÑçαñ£ αñ¼αñ╛αñ░αñ┐αñ╢ αñòαÑÇ αñ╡αñ£αñ╣ αñ╕αÑç αñ«αÑîαñ╕αñ« αñòαñ╛ αñ«αñ┐αñ£αñ╛αñ£ αñ¼αñªαñ▓αñ╛αÑñ αñ¼αñ╛αñ░αñ┐αñ╢ αñ╣αÑïαñ¿αÑç αñ╕αÑç αñ▓αÑïαñùαÑïαñé αñòαÑï αñ«αñ┐αñ▓αÑÇ αñùαñ░αÑìαñ«αÑÇ αñ╕αÑç αñ░αñ╛αñ╣αññαÑñ αñ¿αñ┐αñÜαñ▓αÑç αñçαñ▓αñ╛αñòαÑïαñé αñ«αÑçαñé αñ£αñ▓αñ¡αñ░αñ╛αñ╡ αñòαÑÇ αñ¡αÑÇ αñ╕αÑìαñÑαñ┐αññαñ┐ αñ¼αñ¿ αñùαñêαÑñ\n20:05\n20 minutes, 5 seconds\nαñ░αññαñ▓αñ╛αñ« αñ«αÑçαñé αñ¡αÑÇ αñ«αÑîαñ╕αñ« αñ¿αÑç αñòαñ░αñ╡αñƒ αñ¼αñªαñ▓αÑÇαÑñ αñåαñéαñºαÑÇ αññαÑéαñ½αñ╛αñ¿ αñòαÑç αñ╕αñ╛αñÑ αñ«αÑéαñ╕αñ▓αñ╛αñºαñ╛αñ░ αñ¼αñ╛αñ░αñ┐αñ╢ αñ╣αÑüαñêαÑñ αñºαÑéαñ▓ αñ¡αñ░αÑÇ αñåαñéαñºαÑÇ αñòαÑÇ αñ╡αñ£αñ╣ αñ╕αÑç αñàαñ½αñ░αñ╛αññαñ½αñ░αÑÇ αñ╢αñ╣αñ░ αñ«αÑçαñé αñ¿αñ£αñ░ αñåαñêαÑñ\n20:17\n20 minutes, 17 seconds\nαñ«αñºαÑìαñ» αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñ¼αÑüαñ░αñ╣αñ╛αñ¿αñ¬αÑüαñ░ αñ«αÑçαñé αñ¡αÑÇ αñ«αÑîαñ╕αñ« αñ¿αÑç αñàαñÜαñ╛αñ¿αñò αñòαñ░αñ╡αñƒ αñ¼αñªαñ▓αÑÇαÑñ αñåαñéαñºαÑÇ αññαÑéαñ½αñ╛αñ¿ αñòαÑç αñ╕αñ╛αñÑ αñ¼αñ╛αñ░αñ┐αñ╢ αñ╣αÑüαñêαÑñ αñ¬αñ╛αñ░αñ╛ αñùαñ┐αñ░αñ¿αÑç αñòαÑÇ αñ╡αñ£αñ╣ αñ╕αÑç αñ▓αÑïαñùαÑïαñé αñòαÑï αñùαñ░αÑìαñ«αÑÇ αñ╕αÑç αñ░αñ╛αñ╣αññ αñ«αñ┐αñ▓αÑÇαÑñ\n20:28\n20 minutes, 28 seconds\nαñùαÑüαñ£αñ░αñ╛αññ αñòαÑç αñûαÑçαñíαñ╝αñ╛ αñ«αÑçαñé αñ¡αÑÇ αñÜαñ▓αÑÇ αñºαÑéαñ▓ αñ¡αñ░αÑÇ αñåαñéαñºαÑÇαÑñ αñ¿αñ╛αñªαñ┐αñ»αñ╛αñª αñçαñ▓αñ╛αñòαÑç αñ«αÑçαñé αñ╣αÑüαñê [αñ╕αñéαñùαÑÇαññ] αñ¼αñ╛αñ░αñ┐αñ╢αÑñ αñ¬αñ╛αñ░αñ╛ αñùαñ┐αñ░αñ¿αÑç αñ╕αÑç αñ▓αÑïαñùαÑïαñé αñòαÑï αñùαñ░αÑìαñ«αÑÇ αñ╕αÑç αñ░αñ╛αñ╣αññαÑñ\n20:38\n20 minutes, 38 seconds\nαñ«αñºαÑìαñ» αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñ¼αÑüαñ░αñ╣αñ╛αñ¿αñ¬αÑüαñ░ αñ«αÑçαñé αñåαñéαñºαÑÇ αñÜαñ▓αñ¿αÑç αñ╕αÑç αñ«αñÜαÑÇ αñàαñ½αñ░αñ╛αññαñ½αñ░αÑÇαÑñ αñòαñê αñçαñ▓αñ╛αñòαÑïαñé αñ«αÑçαñé αñåαñéαñºαÑÇ αñòαÑç αñÜαñ▓αññαÑç αñƒαÑéαñƒ αñòαñ░ [αñ╕αñéαñùαÑÇαññ] αñùαñ┐αñ░αÑç αñ¬αÑçαñíαñ╝αÑñ αñ£αñ┐αñ▓αñ╛ αñàαñ╕αÑìαñ¬αññαñ╛αñ▓ αñ¬αñ░αñ┐αñ╕αñ░ αñòαÑç αñàαñéαñªαñ░ αñ¡αÑÇ αñòαñê αñ¬αÑçαñíαñ╝ αñëαñûαñíαñ╝αÑçαÑñ\n20:49\n20 minutes, 49 seconds\nαñ«αñºαÑìαñ» αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñ¿αÑÇαñ«αñÜ αñ«αÑçαñé αñ¡αÑÇ αñ╕αÑïαñ«αñ╡αñ╛αñ░ αñ╢αñ╛αñ« αñàαñÜαñ╛αñ¿αñò αñ¼αñªαñ▓αñ╛ αñ«αÑîαñ╕αñ« αñòαñ╛ αñ«αñ┐αñ£αñ╛αñ£αÑñ αññαÑéαñ½αñ╛αñ¿ αñòαÑç αñ╕αñ╛αñÑ αñ╣αÑüαñê αñ¼αñ╛αñ░αñ┐αñ╢αÑñ αññαÑéαñ½αñ╛αñ¿ αñòαÑÇ αñ╡αñ£αñ╣ αñ╕αÑç αñàαñ½αñ░αñ╛αññαñ½αñ░αÑÇ αñ«αñÜαÑÇαÑñ\n20:59\n20 minutes, 59 seconds\nαñùαÑüαñ£αñ░αñ╛αññ αñòαÑç αñíαñ¡αÑïαñê αñ«αÑçαñé αññαÑçαñ£ αñ╣αñ╡αñ╛ αñòαÑç αñ╕αñ╛αñÑ αñ£αÑïαñ░αñªαñ╛αñ░ αñ¼αñ╛αñ░αñ┐αñ╢αÑñ αñ¿αñ┐αñÜαñ▓αÑç αñçαñ▓αñ╛αñòαÑïαñé αñ«αÑçαñé αñ╕αñíαñ╝αñòαÑïαñé αñ¬αñ░ αñ£αñ▓αñ¡αñ░αñ╛αñ╡ αñ╣αÑï αñùαñ»αñ╛αÑñ αñåαñéαñºαÑÇ αñòαÑÇ αñ╡αñ£αñ╣ αñ╕αÑç αñòαñê αñçαñ▓αñ╛αñòαÑïαñé αñ«αÑçαñé αñ¼αñ┐αñ£αñ▓αÑÇ αñ░αñ╣αÑÇ αñùαÑüαñ▓αÑñ\n21:11\n21 minutes, 11 seconds\nαñùαÑüαñ£αñ░αñ╛αññ αñòαÑç αñòαñê αñ╢αñ╣αñ░αÑïαñé αñ«αÑçαñé αñ¼αñªαñ▓αñ╛ αñ«αÑîαñ╕αñ« αñòαñ╛ αñ«αñ┐αñ£αñ╛αñ£αÑñ αñ╡αñíαñ╝αÑïαñªαñ░αñ╛ αñöαñ░ αñàαñ╣αñ«αñªαñ╛αñ¼αñ╛αñª αñ«αÑçαñé αñ£αñ«αñòαñ░ αñ¼αñ╛αñ░αñ┐αñ╢ αñ╣αÑüαñêαÑñ αñ¬αñ╛αñ░αñ╛ αñùαñ┐αñ░αñ¿αÑç αñ╕αÑç αñùαñ░αÑìαñ«αÑÇ αñ╕αÑç αñ«αñ┐αñ▓αÑÇ αñ░αñ╛αñ╣αññαÑñ\n21:19\n21 minutes, 19 seconds\nαñùαÑüαñ£αñ░αñ╛αññ αñòαÑç αñùαñ╛αñéαñºαÑÇαñ¿αñùαñ░ αñ«αÑçαñé αññαÑçαñ£ αñåαñéαñºαÑÇ αñöαñ░ αñ¼αñ╛αñ░αñ┐αñ╢αÑñ αñòαñê αñçαñ▓αñ╛αñòαÑïαñé αñ«αÑçαñé αññαÑçαñ£ αñ╣αñ╡αñ╛αñôαñé αñòαÑç αñ╕αñ╛αñÑ αñ¼αñ╛αñ░αñ┐αñ╢ αñ¡αÑÇ αñ╣αÑüαñê αñ╣αÑêαÑñ αñ╕αñíαñ╝αñòαÑïαñé αñ¬αñ░ αñ£αñ▓αñ¡αñ░αñ╛αñ╡ αñ╕αÑç αñåαñ╡αñ╛αñ£αñ╛αñ╣αÑÇ αñ¬αÑìαñ░αñ¡αñ╛αñ╡αñ┐αññ αñ╣αÑüαñêαÑñ\n21:29\n21 minutes, 29 seconds\nαñ¿αÑêαñ¿αÑÇαññαñ╛αñ▓ αñ«αÑçαñé αñ«αÑîαñ╕αñ« αñ¿αÑç αñòαñ░αñ╡αñƒ αñ¼αñªαñ▓αÑÇαÑñ αñ¥αñ«αñ╛αñ¥αñ« αñ¼αñ╛αñ░αñ┐αñ╢ αñòαÑÇ αñ╡αñ£αñ╣ αñ╕αÑç αñ╕αÑüαñ╣αñ╛αñ╡αñ¿αñ╛ αñ╣αÑüαñå αñ«αÑîαñ╕αñ«αÑñ αñ╢αñ╣αñ░ αñòαÑç αñòαñê αñçαñ▓αñ╛αñòαÑïαñé αñ«αÑçαñé αñ╕αñíαñ╝αñòαÑïαñé αñ¬αñ░ αñ£αñ▓αñ¡αñ░αñ╛αñ╡ αñ╣αÑï αñùαñ»αñ╛αÑñ\n21:38\n21 minutes, 38 seconds\n[αñ╕αñéαñùαÑÇαññ]\n21:42\n21 minutes, 42 seconds\n[αñ╕αñéαñùαÑÇαññ]\n21:44\n21 minutes, 44 seconds\nαñÅαñ¼αÑÇαñ¬αÑÇ αñ¿αÑìαñ»αÑéαñ£αñ╝ αñåαñ¬αñòαÑï αñ░αñûαÑç αñåαñùαÑçαÑñ	f	2026-06-02 15:45:11.277003
29	UCRWFSbif-RFENbBrSiez1DA	National	General	Transcript\nSearch transcript\n0:02\n2 seconds\nαñôαñ«αñ╛αñ¿ αñòαÑÇ αñûαñ╛αñíαñ╝αÑÇ αñ«αÑçαñé αñ½αñ┐αñ░ αñƒαñòαñ░αñ╛αñÅ αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñöαñ░ αñêαñ░αñ╛αñ¿αÑñ αñåαñêαñåαñ░αñ£αÑÇαñ╕αÑÇ αñòαñ╛ αñªαñ╛αñ╡αñ╛αÑñ αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñòαÑç αñªαÑï αñ£αñéαñùαÑÇ αñ£αñ╣αñ╛αñ£αÑïαñé αñ¬αñ░ αñªαñ╛αñùαÑç αñíαÑìαñ░αÑïαñ¿ αñöαñ░ αñ«αñ┐αñ╕αñ╛αñçαñ▓αÑñ\n0:08\n8 seconds\nαñ╣αñ«αñ▓αÑç αñòαÑç αñ¼αñ╛αñª αñ¡αñ╛αñù αñûαñíαñ╝αÑç αñ╣αÑüαñÅ αñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñ»αÑüαñªαÑìαñºαñ¬αÑïαññαÑñ\n0:13\n13 seconds\nαñêαñ░αñ╛αñ¿ αñ╕αÑç αñ╕αñ«αñ¥αÑîαññαÑç αñòαÑï αñ▓αÑçαñòαñ░ αñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ¬αññαñ┐ αñíαÑïαñ¿αñ╛αñ▓αÑìαñí αñƒαÑìαñ░αñéαñ¬ αñòαñ╛ αñ¼αñ»αñ╛αñ¿αÑñ αñ¼αÑïαñ▓αÑç αñ¼αñ╛αññαñÜαÑÇαññ αñ▓αñùαñ╛αññαñ╛αñ░ αñ£αñ╛αñ░αÑÇαÑñ αñêαñ░αñ╛αñ¿ αñòαÑç αñ¬αñ╛αñ╕ αñ¬αñ░αñ«αñ╛αñúαÑü αñ╣αñÑαñ┐αñ»αñ╛αñ░ αñ¿αñ╛ αñ╣αÑïαñ¿αñ╛ αñöαñ░ αñ╣αÑëαñ░αÑìαñ«αÑïαñ╢ αñòαÑï αñûαÑïαñ▓αñ¿αñ╛ αñíαÑÇαñ▓ αñòαÑç αñ«αÑüαñûαÑìαñ» αñ¼αñ┐αñéαñªαÑüαÑñ\n0:25\n25 seconds\nαñêαñª αñàαñ▓ αñùαñªαÑÇαñ░ αñòαÑç αñ«αÑîαñòαÑç αñ¬αñ░ αñêαñ░αñ╛αñ¿ αñ«αÑçαñé αñ▓αÑïαñùαÑïαñé αñ¿αÑç αñªαñ┐αñûαñ╛αñê αñÅαñòαñ£αÑüαñƒαññαñ╛αÑñ αñ░αÑêαñ▓αÑÇ αñ«αÑçαñé αñ▓αñ╣αñ░αñ╛αñÅ αñêαñ░αñ╛αñ¿, αñ½αñ┐αñ▓αñ┐αñ╕αÑìαññαÑÇαñ¿, αñ╣αñ┐αñ£αñ¼αÑüαñ▓αÑìαñ▓αñ╛αñ╣ αñòαÑç αñ¥αñéαñíαÑçαÑñ αñàαñ«αÑçαñ░αñ┐αñòαñ╛, αñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñ£αñ╛αñ╣αñ┐αñ░ αñòαñ┐αñ»αñ╛ αñùαÑüαñ╕αÑìαñ╕αñ╛αÑñ\n0:37\n37 seconds\nαñ»αÑéαñòαÑìαñ░αÑçαñ¿ αñ╕αÑç αñ╕αñƒαÑç αñ░αÑïαñ«αñ╛αñ¿αñ┐αñ»αñ╛ αñòαÑç αñÅαñò αñ¼αñéαñªαñ░αñùαñ╛αñ╣ αñ¬αñ░ αñíαÑìαñ░αÑïαñ¿ αñàαñƒαÑêαñòαÑñ αñ░αÑéαñ╕ αñ»αÑéαñòαÑìαñ░αÑçαñ¿ αñ£αñéαñù αñ╢αÑüαñ░αÑé αñ╣αÑïαñ¿αÑç αñòαÑç αñ¼αñ╛αñª αñ╕αÑç αñ¬αñ╣αñ▓αÑÇ αñ¼αñ╛αñ░ αñ░αÑïαñ«αñ╛αñ¿αñ┐αñ»αñ╛ αñòαÑç αñòαñ┐αñ╕αÑÇ αñ¼αñéαñªαñ░αñùαñ╛αñ╣\n0:44\n44 seconds\nαñ¬αñ░ αñ╣αñ«αñ▓αñ╛αÑñ αñ╣αñ«αñ▓αñ╛ αñòαñ┐αñ╕αñ¿αÑç αñòαñ┐αñ»αñ╛ αñ»αñ╣ αñàαñ¼ αññαñò αñ╕αñ╛αñ½ αñ¿αñ╣αÑÇαñéαÑñ\n0:50\n50 seconds\nαñªαñòαÑìαñ╖αñ┐αñú αñ¬αÑéαñ░αÑìαñ╡αÑÇ αñ»αÑéαñòαÑìαñ░αÑçαñ¿ αñòαÑç αñ╢αñ╣αñ░ αñ£αñ»αñ¬αÑüαñ░ αñçαÑ¢αñ┐αñ»αñ╛ αñ¬αñ░ αñ░αÑéαñ╕ αñòαñ╛ αñ£αÑïαñ░αñªαñ╛αñ░ αñ╣αñ«αñ▓αñ╛αÑñ αñòαñê αñçαñ«αñ╛αñ░αññαÑçαñé αññαñ¼αñ╛αñ╣αÑñ\n0:54\n54 seconds\nαñ╣αñ«αñ▓αÑç αñ«αÑçαñé αñÅαñò αñ╡αÑìαñ»αñòαÑìαññαñ┐ αñòαÑÇ αñ«αÑîαññ, 15 αñ╕αÑç αñ£αÑìαñ»αñ╛αñªαñ╛ αñÿαñ╛αñ»αñ▓αÑñ\n1:00\n1 minute\nαñ░αÑéαñ╕αÑÇ αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ¬αññαñ┐ αñ¬αÑüαññαñ┐αñ¿ αñ¿αÑç αñ¬αÑìαñ░αñºαñ╛αñ¿αñ«αñéαññαÑìαñ░αÑÇ αñ«αÑïαñªαÑÇ αñòαÑÇ αññαñ╛αñ░αÑÇαñ½ αñòαÑÇαÑñ αñ¡αñ╛αñ░αññ αñòαÑï αñ¼αññαñ╛αñ»αñ╛ αñ¡αñ░αÑïαñ╕αÑçαñ«αñéαñª αñ╕αñ╛αñ¥αÑçαñªαñ╛αñ░αÑñ αñòαñ╣αñ╛ αñ¬αÑÇαñÅαñ« αñ«αÑïαñªαÑÇ αñ¬αñ░ αñªαñ¼αñ╛αñ╡ αñ¼αñ¿αñ╛αñ¿αñ╛ αñ¿αÑüαñòαñ╕αñ╛αñ¿αñªαÑçαñ╣ αñ╣αÑïαñùαñ╛αÑñ\n1:10\n1 minute, 10 seconds\nαñùαÑüαñ£αñ░αñ╛αññ αñòαÑç αñ╕αÑéαñ░αññ αñ«αÑçαñé αñ¬αÑìαñ░αñºαñ╛αñ¿αñ«αñéαññαÑìαñ░αÑÇ αñ¿αñ░αÑçαñéαñªαÑìαñ░ αñ«αÑïαñªαÑÇ αñ¿αÑç αñ▓αñ╛αñ░αÑìαñ╕αñ¿ αñÅαñéαñí αñƒαÑéαñ¼αÑï αñòαÑç αñåαñ░αÑìαñ«αÑìαñí αñ╕αñ┐αñ╕αÑìαñƒαñ« αñòαÑëαñ«αÑìαñ¬αÑìαñ▓αÑçαñòαÑìαñ╕ αñòαñ╛ αñòαñ┐αñ»αñ╛ αñªαÑîαñ░αñ╛αÑñ αñ«αÑçαñò αñçαñ¿ αñçαñéαñíαñ┐αñ»αñ╛\n1:17\n1 minute, 17 seconds\nαñòαÑç αññαñ╣αññ αñ╡αñ┐αñòαñ╕αñ┐αññ αñ╕αÑçαñ¿αñ╛ αñòαÑç αñ╕αñ¼αñ╕αÑç αñ¿αñÅ αñ£αÑïαñ░αñ╛αñ╡αñ░ αñƒαÑêαñéαñò αñòαñ╛ αñ▓αñ┐αñ»αñ╛ αñ£αñ╛αñ»αñ£αñ╛αÑñ\n1:23\n1 minute, 23 seconds\nαñùαÑüαñ£αñ░αñ╛αññ αñòαÑÇ αñ╕αÑéαñ░αññ αñòαÑï αñ¬αÑÇαñÅαñ« αñ«αÑïαñªαÑÇ αñ¿αÑç αñªαÑÇ αñ¼αñíαñ╝αÑÇ αñ╕αÑîαñùαñ╛αññαÑñ 18,800 αñòαÑÇ αñòαñê αñ»αÑïαñ£αñ¿αñ╛αñôαñé αñòαñ╛ αñ╢αÑüαñ¡αñ╛αñ░αñéαñ¡αÑñ\n1:28\n1 minute, 28 seconds\nαñ╡αñ┐αñ╢αÑìαñ╡ αñ¬αñ░αÑìαñ»αñ╛αñ╡αñ░αñú αñªαñ┐αñ╡αñ╕ αñ¬αñ░ αñ¬αÑîαñºαñ╛αñ░αÑïαñ¬αñú αñòαñ░ αñªαñ┐αñ»αñ╛ αñ╕αñéαñªαÑçαñ╢αÑñ\n1:34\n1 minute, 34 seconds\nαñ╕αÑéαñ░αññ αñòαÑç αñ¼αñ╛αñª αñªαñ«αñ¿ αñòαÑï 10,340 αñòαñ░αÑïαñíαñ╝ αñòαÑÇ αñ¬αÑÇαñÅαñ« αñ¿αÑç αñªαÑÇ αñ╕αÑîαñùαñ╛αññαÑñ αñ¿αñ«αÑï αñÅαñ»αñ░αñ¬αÑïαñ░αÑìαñƒ αñòαÑç αñ▓αñ┐αñÅ αñƒαñ░αÑìαñ«αñ┐αñ¿αñ▓ αñ¼αñ┐αñ▓αÑìαñíαñ┐αñéαñù αñöαñ░ αñ¿αñ«αÑï αñàαñ╕αÑìαñ¬αññαñ╛αñ▓ αñòαñ╛ αñëαñªαÑìαñÿαñ╛αñƒαñ¿αÑñ\n1:44\n1 minute, 44 seconds\nαñ╕αñ«αÑüαñªαÑìαñ░ αñ«αñéαñÑαñ¿ αñ«αñ┐αñ╢αñ¿ αñòαÑï αñ«αñ┐αñ▓αÑÇ αñ¼αñíαñ╝αÑÇ αñòαñ╛αñ«αñ»αñ╛αñ¼αÑÇαÑñ\n1:46\n1 minute, 46 seconds\nαñàαñéαñíαñ«αñ╛αñ¿ αññαñƒ αñ╕αÑç 15 αñòαñ┐.αñ«αÑÇ. αñªαÑéαñ░ αñ«αñ┐αñ▓αñ╛ αñùαÑêαñ╕ αñòαñ╛ αñ¡αñéαñíαñ╛αñ░αÑñ αñòαÑçαñéαñªαÑìαñ░αÑÇαñ» αñ«αñéαññαÑìαñ░αÑÇ αñ╣αñ░αñªαÑÇαñ¬ αñ╕αñ┐αñéαñ╣ αñ¬αÑüαñ░αÑÇ αñ¿αÑç αñæαñ»αñ▓ αñçαñéαñíαñ┐αñ»αñ╛ αñ▓αñ┐αñ«αñ┐αñƒαÑçαñí αñòαÑï αñªαÑÇ αñ¼αñºαñ╛αñêαÑñ\n1:55\n1 minute, 55 seconds\nαññαÑìαñ░αñ┐αñ¬αÑüαñ░αñ╛ αñªαÑîαñ░αÑç αñ¬αñ░ αñùαÑâαñ╣ αñ«αñéαññαÑìαñ░αÑÇ αñàαñ«αñ┐αññ αñ╢αñ╛αñ╣ αñ¡αñ╛αñ░αññ αñ¼αñ╛αñéαñùαÑìαñ▓αñ╛αñªαÑçαñ╢ αñ╕αÑÇαñ«αñ╛ αñ¬αñ░ αñ╕αÑìαñÑαñ┐αññ αñ▓αñéαñòαñ╛ αñ«αÑüαñ░αñ╛ αñ¼αÑëαñ░αÑìαñíαñ░ αñåαñëαñƒαñ¬αÑïαñ╕αÑìαñƒ αñ¬αñ░ αñ¼αÑÇαñÅαñ╕αñÅαñ½ αñ£αñ╡αñ╛αñ¿αÑïαñé αñ╕αÑç αñòαÑÇ αñ¼αñ╛αññαñÜαÑÇαññ αñàαñùαñ░αññαñ▓αñ╛ αñ«αÑçαñé αñ¼αÑÇαñÅαñ╕αñÅαñ½ αñ½αÑìαñ░αñéαñƒαñ┐αñ»αñ░\n2:04\n2 minutes, 4 seconds\nαñ«αÑüαñûαÑìαñ»αñ╛αñ▓αñ» αñ«αÑçαñé αñ╕αÑÇαñ«αñ╛αñ╡αñ░αÑìαññαÑÇ αñçαñ▓αñ╛αñòαÑïαñé αñ╕αÑç αñ£αÑüαñíαñ╝αÑç αñ«αÑüαñªαÑìαñªαÑïαñé αñ¬αñ░ αñ¼αÑêαñáαñò αñòαÑÇ αñ»αÑéαñ¬αÑÇ αñòαÑç αñ¼αñ▓αñ░αñ╛αñ«αñ¬αÑüαñ░ αñ«αÑçαñé αñ╕αÑÇαñÅαñ« αñ»αÑïαñùαÑÇ αñ¿αÑç 294\n2:13\n2 minutes, 13 seconds\nαñòαñ░αÑïαñíαñ╝ αñòαÑÇ αñ▓αñ╛αñùαññ αñ╡αñ╛αñ▓αÑÇ 75 αñ¬αñ░αñ┐αñ»αÑïαñ£αñ¿αñ╛αñôαñé αñòαñ╛ αñ╢αÑüαñ¡αñ╛αñ░αñéαñ¡ αñòαñ┐αñ»αñ╛αÑñ αñòαñ╣αñ╛ αñ£αñ╛αññαñ┐αñ╡αñ╛αñª αñ¬αñ░αñ┐αñ╡αñ╛αñ░αñ╡αñ╛αñª αñ╕αÑç αñèαñ¬αñ░ αñëαñáαñòαñ░ αñòαñ╛αñ« αñòαñ░αñ¿αñ╛ αñ╣αÑïαñùαñ╛αÑñ αñ«αñ╛αñ½αñ┐αñ»αñ╛ αñòαÑï αñÜαÑüαñ¿αÑïαñùαÑç αññαÑï αñûαÑéαñ¿ αñÜαÑéαñ╕αÑçαñùαñ╛αÑñ\n2:25\n2 minutes, 25 seconds\nαñ»αÑéαñ¬αÑÇ αñòαÑç αñ╕αñéαñ¡αñ▓ αñ«αÑçαñé αñûαñéαñíαÑçαñ╢αÑìαñ╡αñ░ αñ╢αñ┐αñ╡ αñ«αñéαñªαñ┐αñ░ αñòαÑç αñ¬αñ╛αñ╕ αñ¼αñ¿αÑç αñàαñ╡αÑêαñº αñ«αñ£αñ╛αñ░ αñ¬αñ░ αñ¬αÑìαñ░αñ╢αñ╛αñ╕αñ¿ αñ¿αÑç αñòαÑÇ αñ¼αÑüαñ▓αñíαÑïαñ£αñ░ αñòαñ╛αñ░αñ╡αñ╛αñêαÑñ αñ╕αñ░αñòαñ╛αñ░αÑÇ αñ£αñ«αÑÇαñ¿ αñ¬αñ░ αñàαñ╡αÑêαñº αñòαñ¼αÑìαñ£αñ╛ αñòαñ░ αñ¼αñ¿αñ╛αñ»αñ╛ αñùαñ»αñ╛ αñÑαñ╛ αñ«αñ£αñ╛αñ░αÑñ\n2:37\n2 minutes, 37 seconds\nαñòαÑïαñ▓αñòαñ╛αññαñ╛ αñ«αÑçαñé αñ«αñ«αññαñ╛ αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñòαÑç αñåαñ╡αñ╛αñ╕ αñ¬αñ░ αñ╣αÑüαñê αñ¼αÑêαñáαñòαÑñ αñ«αÑÇαñƒαñ┐αñéαñù αñòαÑç αñ¼αñ╛αñª αñ¬αñ╛αñ░αÑìαñƒαÑÇ αñ╕αñ╛αñéαñ╕αñª αñòαñ▓αÑìαñ»αñ╛αñú αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñ¿αÑç αñ╕αÑìαñ¬αÑÇαñòαñ░ αñòαÑÇ αñôαñ░ αñ╕αÑç αñ¿αñ┐αñ»αÑüαñòαÑìαññ αñòαñ┐αñ»αñ╛ αñ¿αÑçαññαñ╛ αñ¬αÑìαñ░αññαñ┐αñ¬αñòαÑìαñ╖ αñòαÑï αñ¼αññαñ╛ αñªαñ┐αñ»αñ╛ αñàαñ╡αÑêαñºαÑñ αñòαñ╣αñ╛ αñçαñ╕αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñ╕αÑïαñ«αñ╡αñ╛αñ░ αñòαÑï αñòαÑïαñ░αÑìαñƒ αñ£αñ╛αñÅαñéαñùαÑçαÑñ\n2:49\n2 minutes, 49 seconds\nαñ¼αñ┐αñ╣αñ╛αñ░ αñ«αÑçαñé αñÅαñ«αñÅαñ▓αñ╕αÑÇ αñÜαÑüαñ¿αñ╛αñ╡ αñòαÑç αñ▓αñ┐αñÅ αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñöαñ░ αñ£αÑçαñíαÑÇαñ»αÑé αñ¿αÑç αñ£αñ╛αñ░αÑÇ αñòαÑÇ αñ¬αÑìαñ░αññαÑìαñ»αñ╛αñ╢αñ┐αñ»αÑïαñé αñòαÑÇ αñ▓αñ┐αñ╕αÑìαñƒαÑñ\n2:53\n2 minutes, 53 seconds\nαñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñ¿αÑç αñ¡αÑïαñ£αñ¬αÑüαñ░αÑÇ αñ╕αÑìαñƒαñ╛αñ░ αñ¬αñ╡αñ¿ αñ╕αñ┐αñéαñ╣ αñöαñ░ αñ╕αñéαñ£αñ» αñ«αñ»αÑé αñòαÑï αñ¼αñ¿αñ╛αñ»αñ╛ αñëαñ«αÑìαñ«αÑÇαñªαñ╡αñ╛αñ░αÑñ αñ£αÑçαñíαÑÇαñ»αÑé αñ╕αÑç αñ¿αÑÇαññαÑÇαñ╢ αñòαÑüαñ«αñ╛αñ░ αñòαÑç αñ¼αÑçαñƒαÑç αñ¿αñ┐αñ╢αñ╛αñéαññ [αñ╕αñéαñùαÑÇαññ] αñëαñ«αÑìαñ«αÑÇαñªαñ╡αñ╛αñ░ αñ¼αñ¿αñ╛αñÅ αñùαñÅαÑñ\n3:03\n3 minutes, 3 seconds\nαññαñ«αñ┐αñ▓αñ¿αñ╛αñíαÑü αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñòαÑç αñ¬αÑéαñ░αÑìαñ╡ αñ¬αÑìαñ░αñªαÑçαñ╢ αñàαñºαÑìαñ»αñòαÑìαñ╖ αñàαñ¿αÑìαñ¿αñ╛ αñ«αñ▓αñê αñ¿αÑç αñ¿αñê αñ¬αñ╛αñ░αÑìαñƒαÑÇ αñ¼αñ¿αñ╛αñ¿αÑç αñòαñ╛ αñÉαñ▓αñ╛αñ¿ αñòαñ┐αñ»αñ╛αÑñ αñ¼αÑïαñ▓αÑç 2031 αñ«αÑçαñé αñ╣αñ«αñ╛αñ░αÑÇ αñ¬αñ╛αñ░αÑìαñƒαÑÇ αñ▓αñíαñ╝αÑçαñùαÑÇ αñÜαÑüαñ¿αñ╛αñ╡αÑñ\n3:13\n3 minutes, 13 seconds\nαñ╣αñ╛αñê αñ▓αÑçαñ╡αñ▓ αñ«αÑÇαñƒαñ┐αñéαñù αñ«αÑçαñé αñªαñ┐αñ▓αÑìαñ▓αÑÇ αñ╕αñ░αñòαñ╛αñ░ αñòαñ╛ αñ¼αñíαñ╝αñ╛ αñ½αÑêαñ╕αñ▓αñ╛αÑñ αñàαñ╡αÑêαñº αñ¿αñ┐αñ░αÑìαñ«αñ╛αñú αñòαÑç αñ«αñ╛αñ«αñ▓αÑïαñé αñ¬αñ░ αñàαñ¼ αñàαñºαñ┐αñòαñ╛αñ░αñ┐αñ»αÑïαñé αñ¬αñ░ αñ¡αÑÇ αñùαñ┐αñ░αÑçαñùαÑÇ αñùαñ╛αñ£αÑñ αñªαÑïαñ╖αÑÇ αñàαñ½αñ╕αñ░αÑïαñé\n3:20\n3 minutes, 20 seconds\nαñòαÑç αñ╡αÑçαññαñ¿, αñ¬αÑçαñéαñ╢αñ¿ αñöαñ░ αñ╕αñéαñ¬αññαÑìαññαñ┐ αñ╕αÑç αñòαÑÇ αñ£αñ╛αñÅαñùαÑÇ αñ╕αñ╛αñ░αÑìαñ╡αñ£αñ¿αñ┐αñò αñ¿αÑüαñòαñ╕αñ╛αñ¿ αñòαÑÇ αñ¡αñ░αñ¬αñ╛αñêαÑñ\n3:26\n3 minutes, 26 seconds\nαñªαñ┐αñ▓αÑìαñ▓αÑÇ αñàαñùαÑìαñ¿αñ┐αñòαñ╛αñéαñí αñ«αÑçαñé 21 αñ▓αÑïαñùαÑïαñé αñòαÑÇ αñ«αÑîαññ αñòαÑç αñ¼αñ╛αñª αñ£αñ╛αñùαñ╛ αñ¬αÑìαñ░αñ╢αñ╛αñ╕αñ¿αÑñ αñàαñ╡αÑêαñº αñ¿αñ┐αñ░αÑìαñ«αñ╛αñú αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñàαñ¡αñ┐αñ»αñ╛αñ¿ αñ£αñ╛αñ░αÑÇαÑñ αñÿαñ┐αñƒαÑïαñíαñ╝αñ¿αÑÇ αñçαñ▓αñ╛αñòαÑç αñ«αÑçαñé αñàαñ╡αÑêαñº αñçαñ«αñ╛αñ░αññαÑïαñé αñ¬αñ░ αñÜαñ▓αñ╛ αñ¼αÑüαñ▓αñíαÑïαñ£αñ░αÑñ\n3:37\n3 minutes, 37 seconds\nαñ«αñ╛αñ▓αñ╡αÑÇαñ» αñ¿αñùαñ░ αñàαñùαÑìαñ¿αñ┐αñòαñ╛αñéαñí αñòαÑç αñ¼αñ╛αñª αñªαñ┐αñ▓αÑìαñ▓αÑÇ αñ╕αñ░αñòαñ╛αñ░ αñòαÑÇ αñòαñ╛αñ░αñ╡αñ╛αñêαÑñ αñ╣αÑîαñ£αñûαñ╛ αñ╕αñ«αÑçαññ αñòαñê αñçαñ▓αñ╛αñòαÑïαñé αñ«αÑçαñé αñ¿αñ┐αñ»αñ«αÑïαñé αñòαÑç αñëαñ▓αÑìαñ▓αñéαñÿαñ¿ αñ¬αñ░ αñ╕αÑÇαñ▓αñ┐αñéαñùαÑñ αñòαñê αñªαÑüαñòαñ╛αñ¿αÑïαñé αñòαÑï αñ╕αÑÇαñ▓ αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛αÑñ\n3:46\n3 minutes, 46 seconds\nαñàαñùαÑìαñ¿αñ┐αñòαñ╛αñéαñí αñ«αÑçαñé αñ£αñûαÑìαñ«αÑÇ αñ▓αÑïαñùαÑïαñé αñ╕αÑç αñ«αñ┐αñ▓αñ¿αÑç αñ«αÑêαñòαÑìαñ╕ αñàαñ╕αÑìαñ¬αññαñ╛αñ▓ αñ¬αñ╣αÑüαñéαñÜαÑÇ αñ¬αÑéαñ░αÑìαñ╡ αñ╕αÑÇαñÅαñ« αñåαññαñ┐αñ╢αÑÇαñ╖αÑÇ αñ╕αñ┐αñòαÑìαñ»αÑïαñ░αñ┐αñƒαÑÇ αñ╕αÑìαñƒαñ╛αñ½ αñ¬αñ░ αñÅαñéαñƒαÑìαñ░αÑÇ αñ¿αñ╣αÑÇαñé αñªαÑçαñ¿αÑç αñòαñ╛ αñ▓αñùαñ╛αñ»αñ╛ αñåαñ░αÑïαñ¬αÑñ αñòαñ╣αñ╛ αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñ╕αñÜαÑìαñÜαñ╛αñê αñ¢αñ┐αñ¬αñ╛ αñ░αñ╣αÑÇ αñ╣αÑêαÑñ\n3:58\n3 minutes, 58 seconds\nαñ«αÑüαñ£αñ½αÑìαñ½αñ░αñ¬αÑüαñ░ αñòαÑç αñàαñ╕αÑìαñ¬αññαñ╛αñ▓ αñ«αÑçαñé αñåαñù αñ▓αñùαñ¿αÑç αñòαÑç αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñÅαñòαÑìαñ╢αñ¿αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñÅαñò αñíαÑëαñòαÑìαñƒαñ░ αñ╕αñ«αÑçαññ αññαÑÇαñ¿ αñòαÑï αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛αÑñ αñ╣αñ╛αñªαñ╕αÑç αñ«αÑçαñé αñ¢αñ╣ αñ«αñ░αÑÇαñ£αÑïαñé αñòαÑÇ αñ╣αÑüαñê αñÑαÑÇ αñ«αÑîαññαÑñ\n4:06\n4 minutes, 6 seconds\n[αñ╕αñéαñùαÑÇαññ]\n4:12\n4 minutes, 12 seconds\n[αñ╕αñéαñùαÑÇαññ]\n4:13\n4 minutes, 13 seconds\nαñÅαñ¼αÑÇαñ¬αÑÇ αñ¿αÑìαñ»αÑéαñ£αñ╝ αñåαñ¬αñòαÑï αñ░αñûαÑç αñåαñùαÑçαÑñ	f	2026-06-05 23:39:39.275661
30	UCRWFSbif-RFENbBrSiez1DA	National	General	Transcript\nSearch transcript\n0:03\n3 seconds\nαñ»αñ«αñ¿ αñòαÑçαÑéαññαÑÇ αñ╡αñ┐αñªαÑìαñ░αÑïαñ╣αñ┐αñ»αÑïαñé αñ¿αÑç αñòαñ░ αñªαñ┐αñ»αñ╛ αñçαñ£αñ░αñ╛αñçαñ▓ αñ¬αñ░ αñ«αñ┐αñ╕αñ╛αñçαñ▓ αñ╣αñ«αñ▓αÑç αñòαñ╛ αñªαñ╛αñ╡αñ╛αÑñ αñòαñ╣αñ╛ αñ▓αñ╛αñ▓ αñ╕αñ╛αñùαñ░ αñ«αÑçαñé αñçαñ£αñ░αñ╛αñçαñ▓ αñ╕αÑç αñ£αÑüαñíαñ╝αÑç αñ£αñ╣αñ╛αñ£αÑïαñé αñ¬αñ░ αñ½αñ┐αñ░ αñ╕αÑç αñ╣αñ«αñ▓αÑç αñ╣αÑïαñéαñùαÑçαÑñ\n0:16\n16 seconds\nαñ╣αñ┐αñ£αñ¼αÑüαñ▓ αñ¿αÑç αñòαñ┐αñ»αñ╛ αñçαñ£αñ░αñ»αñ▓αÑÇ αñ╕αÑçαñ¿αñ╛ αñòαÑç αñƒαÑêαñéαñò αñ¬αñ░ αñ╣αñ«αñ▓αñ╛ αñòαñ░αñ¿αÑç αñòαñ╛ αñªαñ╛αñ╡αñ╛αÑñ αñªαñòαÑìαñ╖αñ┐αñúαÑÇ αñ▓αÑçαñ¼αñ¿ αñ«αÑçαñé αñçαñ£αñ░αñ»αñ▓αÑÇ αñ«αñ░αñòαñ╛αñ╡αñ╛ αñƒαÑêαñéαñò αñ¬αñ░ αñíαÑìαñ░αÑïαñ¿ αñ╕αÑç αñ╣αñ«αñ▓αñ╛ αñòαñ░αñ¿αÑç αñòαñ╛ αñ╡αÑÇαñíαñ┐αñ»αÑï αñ£αñ╛αñ░αÑÇαÑñ\n0:29\n29 seconds\nαñëαññαÑìαññαñ░αÑÇ αñçαñ░αñ╛αñò αñ«αÑçαñé αñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñáαñ┐αñòαñ╛αñ¿αÑïαñé αñ¬αñ░ αñêαñ░αñ╛αñ¿ αñòαÑç αñ╣αñ«αñ▓αÑç αñ╕αñ┐αñ░αñ╛αñ¿ αñûαñ╛αñ▓αÑÇαñ½αñ╛αñ¿ αñòαÑç αñèαñ¬αñ░ αñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñÅαñ»αñ░ αñíαñ┐αñ½αÑçαñéαñ╕ αñ╕αñ┐αñ╕αÑìαñƒαñ« αñ¿αÑç αñòαñê αñíαÑìαñ░αÑïαñéαñ╕ αñòαÑï αñçαñéαñƒαñ░αñ╕αÑçαñ¬αÑìαñƒ αñòαñ┐αñ»αñ╛αÑñ\n0:43\n43 seconds\nαñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñ╕αÑçαñ¿αñ╛ αñ¿αÑç αñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑÇ αñôαñ░ αñªαñ╛αñù αñªαÑÇ αñ╣αÑêαÑñ\n0:45\n45 seconds\nαñòαñê αñêαñ░αñ╛αñ¿αÑÇ αñ«αñ┐αñ╕αñ╛αñçαñ▓αÑìαñ╕ αñòαÑï αñçαñéαñƒαñ░αñ╕αÑçαñ¬αÑìαñƒ αñòαñ░αñ¿αÑç αñ«αÑçαñé αñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑÇ αñ«αñªαñª αñòαÑÇ αñÑαÑÇαÑñ αñ«αÑÇαñíαñ┐αñ»αñ╛ αñ░αñ┐αñ¬αÑïαñ░αÑìαñƒαÑìαñ╕ αñ«αÑçαñé αñ»αñ╣ αñªαñ╛αñ╡αñ╛ αñòαñ┐αñ»αñ╛ αñ£αñ╛ αñ░αñ╣αñ╛ αñ╣αÑêαÑñ αñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñàαñºαñ┐αñòαñ╛αñ░αñ┐αñ»αÑïαñé αñòαÑç αñ╣αñ╡αñ╛αñ▓αÑç αñ╕αÑç αñ»αñ╣ αñ¼αñíαñ╝αÑÇ αñûαñ¼αñ░ αñ╣αÑêαÑñ\n1:00\n1 minute\nαñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑç αñ¬αÑìαñ░αñºαñ╛αñ¿αñ«αñéαññαÑìαñ░αÑÇ αñ¿αÑçαññαñ¿ αñ»αñ╛αÑé αñ¿αÑç αñíαÑïαñ¿αñ▓αÑìαñí αñƒαÑìαñ░αñéαñ¬ αñ╕αÑç αñòαñ╣αñ╛ αñ╣αÑê αñêαñ░αñ╛αñ¿ αñòαÑç αñ╣αñ«αñ▓αÑç αñòαñ╛ αñ£αñ╡αñ╛αñ¼ αñ¿αñ╛ αñªαÑçαñ¿αñ╛ αñçαñ£αñ░αñ╛αñçαñ▓ αñöαñ░ αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñªαÑïαñ¿αÑïαñé αñòαÑç αñ▓αñ┐αñÅ αñ¼αÑüαñ░αñ╛ αñ╣αÑïαñùαñ╛ αñöαñ░ αñíαÑÇαñ▓ αñòαÑç αñ▓αñ┐αñÅ αñ¡αÑÇ αñ¿αÑüαñòαñ╕αñ╛αñ¿αñªαÑçαñ╣ αñ╣αÑïαñùαñ╛αÑñ\n1:14\n1 minute, 14 seconds\nαñêαñ░αñ╛αñ¿ αñòαÑÇ αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñöαñ░ αñçαñ£αñ░αñ╛αñçαñÅαñ▓ αñòαÑï αñÜαÑçαññαñ╛αñ╡αñ¿αÑÇαÑñ\n1:16\n1 minute, 16 seconds\nαñòαñ╣αñ╛ αññαñ¿αñ╛αñ╡ αñ¼αñóαñ╝αñ╛αñ¿αÑç αñòαÑÇ αñòαÑïαñ╢αñ┐αñ╢ αñòαÑÇ αññαÑï αñ«αñ┐αñ▓αÑçαñùαñ╛ αñ«αÑüαñéαñ╣αññαÑïαñíαñ╝ αñ£αñ╡αñ╛αñ¼αÑñ αñêαñ░αñ╛αñ¿ αñöαñ░ αñëαñ¿αñòαÑç αñ╕αñ╣αñ»αÑïαñùαñ┐αñ»αÑïαñé αñòαÑç αñ¬αñ╛αñ╕ αñ£αñ╡αñ╛αñ¼ αñªαÑçαñ¿αÑç αñòαÑÇ αñòαÑìαñ╖αñ«αññαñ╛αÑñ\n1:28\n1 minute, 28 seconds\nαñçαñ£αñ░αñ»αñ▓αÑÇ αñ¬αÑìαñ░αñºαñ╛αñ¿αñ«αñéαññαÑìαñ░αÑÇ αñ¼αÑçαñéαñ£αñ╛αñ«αñ┐αñ¿ αñ¿αñ┐αññαñ┐αñ¿ αñ»αñ╛αÑé αñ¿αÑç αñòαñ╣αñ╛ αñ╣αÑê αñ½αñ┐αñ▓αñ╣αñ╛αñ▓ αñêαñ░αñ╛αñ¿ αñòαÑç αñ╕αñ╛αñÑ αñÑαñ« αñùαñê αñ╣αÑê αñ▓αñíαñ╝αñ╛αñêαÑñ αñêαñ░αñ╛αñ¿ αñ¿αÑç αñªαÑïαñ¼αñ╛αñ░αñ╛ αñ╣αñ«αñ▓αñ╛ αñòαñ┐αñ»αñ╛ αññαÑï αñçαñ£αñ░αñ╛αñçαñ▓ αñªαÑçαñùαñ╛ αñ¬αÑéαñ░αÑÇ αññαñ╛αñòαññ αñòαÑç αñ╕αñ╛αñÑ αñ£αñ╡αñ╛αñ¼αÑñ\n1:42\n1 minute, 42 seconds\nαñíαÑëαñ¿αñ▓αÑìαñí αñƒαÑìαñ░αñéαñ¬ αñ¿αÑç αñ¿αñ┐αññαñ┐αñ¿ αñ»αñ╛αÑé αñòαÑï αñ╣αñ┐αñªαñ╛αñ»αññ αñªαÑÇαÑñ\n1:44\n1 minute, 44 seconds\nαñòαñ╣αñ╛ αñêαñ░αñ╛αñ¿ αñòαÑç αñ╕αñ╛αñÑ αñ½αñ┐αñ░ αñ╕αÑç αñ»αÑüαñªαÑìαñº αñ«αÑçαñé αñëαññαñ░αÑç αññαÑï αñëαñ¿αÑìαñ╣αÑçαñé αñàαñòαÑçαñ▓αÑç αñ▓αñíαñ╝αñ¿αñ╛ αñ¬αñíαñ╝ αñ╕αñòαññαñ╛ αñ╣αÑê αñ»αÑüαñªαÑìαñºαÑñ αñÉαñ╕αñ╛ αñòαñ┐αñ»αñ╛ αññαÑï αñàαñ▓αñù-αñÑαñ▓αñù αñ¬αñíαñ╝ αñ£αñ╛αñÅαñùαñ╛ αñçαñ£αñ░αñ╛αñçαñ▓αÑñ\n1:55\n1 minute, 55 seconds\nαñêαñ░αñ╛αñ¿ αñòαÑç αñëαñ¬αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ¬αññαñ┐ αñ«αÑïαñ╣αñ«αÑìαñ«αñª αñ░αñ£αñ╛ αñåαñ░αñ½ αñòαñ╛ αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñöαñ░ αñçαñ£αñ░αñ╛αñçαñ▓ αñ¬αñ░ αñ¿αñ┐αñ╢αñ╛αñ¿αñ╛αÑñ αñòαñ╣αñ╛ αñªαÑüαñ╢αÑìαñ«αñ¿ αñªαÑçαñ╢αÑïαñé αñòαÑï αñ¼αñ╣αÑüαññ αñòαñ« αñ╕αñ«αñ» αñ«αÑçαñé αñ╣αÑüαñå αñêαñ░αñ╛αñ¿ αñòαÑÇ\n2:03\n2 minutes, 3 seconds\nαññαñ╛αñòαññ αñòαñ╛ αñÅαñ╣αñ╕αñ╛αñ╕αÑñ αñ»αÑüαñªαÑìαñº αñ╡αñ┐αñ░αñ╛αñ« αñ╕αÑìαñ╡αÑÇαñòαñ╛αñ░ αñòαñ░αñ¿αÑç αñòαÑÇ αñùαÑüαñ╣αñ╛αñ░ αñ▓αñùαñ╛αñ¿αÑç αñ¬αñ░ αñ╣αñ«αñ¿αÑç αñ«αñ£αñ¼αÑéαñ░ αñòαñ┐αñ»αñ╛αÑñ\n2:08\n2 minutes, 8 seconds\nαñ½αÑìαñ░αñ╛αñéαñ╕ αñ«αÑçαñé αñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑç αñ░αñ╛αñ£αñªαÑéαññ αñ£αÑïαñ╢αñ╡αñ╛ αñ£αñ╛αñ░αñòαñ╛ αñòαñ╛ αñ¼αñíαñ╝αñ╛ αñ¼αñ»αñ╛αñ¿αÑñ αñ¼αÑïαñ▓αÑç αñçαñ£αñ░αñ╛αñçαñ▓ αñöαñ░ αñêαñ░αñ╛αñ¿ αñòαÑç αñ¼αÑÇαñÜ αñ▓αñíαñ╝αñ╛αñê αñ½αñ┐αñ░ αñ╕αÑç αñ╢αÑüαñ░αÑé αñòαñ░αñ¿αÑç αñòαñ╛ αñ½αÑêαñ╕αñ▓αñ╛ αñêαñ░αñ╛αñ¿ αñòαñ╛ αñÑαñ╛αÑñ αñ»αÑüαñªαÑìαñº αñ╡αñ┐αñ░αñ╛αñ« αñòαÑç αñ¼αñ╛αñª αñ╕αÑç αñªαÑïαñ¿αÑïαñé αñ¬αñòαÑìαñ╖αÑïαñé αñòαÑç αñ¼αÑÇαñÜ αñ¬αñ╣αñ▓αÑÇ αñ¼αñ╛αñ░ αñ╣αñ«αñ▓αÑç αñ╣αÑüαñÅαÑñ\n2:23\n2 minutes, 23 seconds\nαñòαÑïαñÜαñ┐αñéαñù αñùαÑïαñ▓αÑÇαñòαñ╛αñéαñí αñ«αÑçαñé αñûαñ╛αñ¿ αñ╕αñ░ αñòαÑï αñòαÑïαñ░αÑìαñƒ αñ╕αÑç αñ¼αñíαñ╝αÑÇ αñ░αñ╛αñ╣αññ αñ«αñ┐αñ▓αÑÇ αñ╣αÑêαÑñ αñ¬αñƒαñ¿αñ╛ αñ╕αñ┐αñ╡αñ┐αñ▓ αñòαÑïαñ░αÑìαñƒ αñ¿αÑç αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░αÑÇ αñ¬αñ░ αñ░αÑïαñò αñ▓αñùαñ╛αñêαÑñ\n2:34\n2 minutes, 34 seconds\nαñ«αñ«αññαñ╛ αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñòαÑÇ αñ¬αñ╛αñ░αÑìαñƒαÑÇ αñ«αÑçαñé αñ¼αñíαñ╝αÑÇ αñƒαÑéαñƒαÑñ αñ¼αñ╛αñùαÑÇ αñùαÑüαñƒ αñ¿αÑç αñòαñ┐αñ»αñ╛ 20 αñ╕αñ╛αñéαñ╕αñªαÑïαñé αñòαÑç αñ╕αñ«αñ░αÑìαñÑαñ¿ αñòαñ╛ αñªαñ╛αñ╡αñ╛αÑñ αñåαñ£ αñ¼αñùαñ╛αñ╡αññ αñ¬αñ░ αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñòαÑÇ αñ¬αÑìαñ░αÑçαñ╕ αñòαÑëαñ¿αÑìαñ½αÑìαñ░αÑçαñéαñ╕αÑñ\n2:46\n2 minutes, 46 seconds\nαñ░αñ╛αñ£αÑìαñ»αñ╕αñ¡αñ╛ αñ╕αÑç αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ╕αñ╛αñéαñ╕αñª αñ╕αÑüαñûαÑçαñéαñªαÑìαñ░ αñ╢αÑçαñûαñ░ αñ░αÑëαñ» αñòαñ╛ αñçαñ╕αÑìαññαÑÇαñ½αñ╛αÑñ αñ«αñ«αññαñ╛ αñ¬αñ░ αñ▓αñùαñ╛ αñªαñ┐αñÅ αñåαñ░αÑïαñ¬ αñåαñ¿αÑç αñ╡αñ╛αñ▓αÑç αñªαñ┐αñ¿αÑïαñé αñ«αÑçαñé αñ░αñ╛αñ£αÑìαñ»αñ╕αñ¡αñ╛ αñ╕αÑç αñ╣αÑï αñ╕αñòαññαÑç αñ╣αÑêαñéαÑñ\n2:52\n2 minutes, 52 seconds\nαñƒαÑÇαñÅαñ«αñ╕αÑÇ αñòαÑç αñòαñê αñöαñ░ αñ╕αñ╛αñéαñ╕αñªαÑïαñé αñòαÑç αñçαñ╕αÑìαññαÑÇαñ½αÑçαÑñ\n3:00\n3 minutes\nαñ«αñºαÑìαñ» αñ¬αÑìαñ░αñªαÑçαñ╢ αñ░αñ╛αñ£αÑìαñ»αñ╕αñ¡αñ╛ αñÜαÑüαñ¿αñ╛αñ╡ αñòαÑç αñ▓αñ┐αñÅ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñòαÑÇ αñ¼αñíαñ╝αÑÇ αñ░αñúαñ¿αÑÇαññαñ┐αÑñ αñòαÑìαñ░αÑëαñ╕ αñ╡αÑïαñƒαñ┐αñéαñù αñ░αÑïαñòαñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ αñòαñ░αÑìαñ¿αñ╛αñƒαñò αñ¡αÑçαñ£αÑç αñ£αñ╛ αñ╕αñòαññαÑç αñ╣αÑêαñé αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñòαÑç αñ╡αñ┐αñºαñ╛αñ»αñòαÑñ\n3:12\n3 minutes, 12 seconds\nαñ░αñ╛αñ« αñ«αñéαñªαñ┐αñ░ αñòαÑç αñÜαñóαñ╝αñ╛αñ╡αÑç αñ¬αñ░ αñ╕αñ┐αñ»αñ╛αñ╕αÑÇ αñÿαñ«αñ╛αñ╕αñ╛αñ¿ αñ╣αÑêαÑñ\n3:14\n3 minutes, 14 seconds\nαñåαñ¬ αñ╕αñ╛αñéαñ╕αñª αñ╕αñéαñ£αñ» αñ╕αñ┐αñéαñ╣ αñ¿αÑç αñ▓αñùαñ╛ αñªαñ┐αñ»αñ╛ αñ╣αÑê αñÜαÑïαñ░αÑÇ αñòαñ╛ αñåαñ░αÑïαñ¬αÑñ αñ¿αÑç αñòαñ╣αñ╛ αñÜαñéαñªαñ╛ αñÜαÑïαñ░ αñùαñªαÑìαñªαÑÇ αñ¢αÑïαñíαñ╝\n3:25\n3 minutes, 25 seconds\nαñàαñûαñ┐αñ▓αÑçαñ╢ αñ¬αñ░ αñôαñ¬αÑÇ αñ░αñ╛αñ£αñ¡αñ░ αñ¿αÑç αñ▓αñùαñ╛ αñªαñ┐αñ»αñ╛ αñùαÑüαñ«αñ░αñ╛αñ╣ αñòαñ░αñ¿αÑç αñòαñ╛ αñåαñ░αÑïαñ¬ αñòαñ╣αñ╛ αñàαñûαñ┐αñ▓αÑçαñ╢ αñòαÑìαñ»αñ╛ αñòαñ¡αÑÇ αñùαñÅ αñ╣αÑêαñé αñàαñ»αÑïαñºαÑìαñ»αñ╛ αñòαÑç αñ░αñ╛αñ« αñ«αñéαñªαñ┐αñ░ αñ»αñ╣ αñ╕αñ¼ αñ¥αÑéαñá αñ¼αÑïαñ▓αñ¿αÑç\n3:31\n3 minutes, 31 seconds\nαñ╡αñ╛αñ▓αÑç αñ▓αÑïαñù αñ╣αÑêαñé αñ░αñ╛αñ« αñ«αñéαñªαñ┐αñ░ αñòαÑç αñÜαñóαñ╝αñ╛αñ╡αÑç αñ╕αÑç αñ£αÑüαñíαñ╝αÑç αñàαñûαñ┐αñ▓αÑçαñ╢ αñòαÑç\n3:40\n3 minutes, 40 seconds\nαñåαñ░αÑïαñ¬αÑïαñé αñ¬αñ░ αñ╕αñ┐αñ»αñ╛αñ╕αÑÇ αñÿαñ«αñ╛αñ╕αñ╛αñ¿ αñ¢αÑçαñíαñ╝αñ╛ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñ¼αÑïαñ▓αÑÇ αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñöαñ░ αñåαñ░αñÅαñ╕αñÅαñ╕ αñºαñ░αÑìαñ« αñòαÑÇ αñåαñíαñ╝ αñ«αÑçαñé αñ¢αñ┐αñ¬αñòαñ░ αñ░αñ╛αñ£αñ¿αÑÇαññαñ┐ αñòαñ░ αñ░αñ╣αÑç αñ╣αÑêαñéαÑñ\n3:51\n3 minutes, 51 seconds\nαñçαññαñ┐αñ╣αñ╛αñ╕ αñ░αñÜαñ¿αÑç αñòαÑï αññαÑêαñ»αñ╛αñ░ αñ£αÑïαñ£αñ▓αñ╛ αñ╕αÑüαñ░αñéαñù αñƒαñ¿αñ▓ αñòαÑç αñªαÑïαñ¿αÑïαñé αñ╕αñ┐αñ░αÑïαñé αñòαÑï αñåαñ¬αñ╕ αñ«αÑçαñé αñ£αÑïαñíαñ╝αñ╛ αñ£αñ╛αñÅαñùαñ╛αÑñ αñàαñ¼ αñ¼αñ░αÑìαñ½αñ¼αñ╛αñ░αÑÇ αñ«αÑçαñé αñ¡αÑÇ αñ¿αñ╣αÑÇαñé αñÑαñ«αÑçαñéαñùαÑç αñ¬αñ╣αñ┐αñÅαÑñ αñòαñ╢αÑìαñ«αÑÇαñ░ αñ▓αñªαÑìαñªαñ╛αñû αñòαÑç αñ¼αÑÇαñÜ αñåαñ¿αñ╛ αñ£αñ╛αñ¿αñ╛ αñåαñ╕αñ╛αñ¿ αñ╣αÑïαñùαñ╛αÑñ\n4:04\n4 minutes, 4 seconds\nαñëαññαÑìαññαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñàαñ«αñ░αÑïαñ╣αñ╛ αñ«αÑçαñé αñ£αÑêαñòαÑçαñƒ αñ½αÑêαñòαÑìαñƒαÑìαñ░αÑÇ αñ«αÑçαñé αñ¡αÑÇαñ╖αñú αñåαñù αñ▓αñù αñùαñêαÑñ αñåαñù αñòαÑÇ αñ¡αñ»αñéαñòαñ░ αñ▓αñ¬αñƒαÑïαñé αñ«αÑçαñé αñ▓αñ╛αñûαÑïαñé αñòαñ╛ αñ╕αñ╛αñ«αñ╛αñ¿ αñ£αñ▓αñòαñ░ αñ░αñ╛αñû αñ╣αÑï αñùαñ»αñ╛αÑñ αñ½αÑêαñòαÑìαñƒαÑìαñ░αÑÇ αñ«αñ╛αñ▓αñ┐αñò αñ¿αÑç αñ£αññαñ╛αñê αñ╕αñ╛αñ£αñ┐αñ╢ αñòαÑÇ αñåαñ╢αñéαñòαñ╛αÑñ αñ£αñ╛αñéαñÜ αñ«αÑçαñé αñ¬αÑüαñ▓αñ┐αñ╕ αñ£αÑüαñƒαÑÇαÑñ\n4:18\n4 minutes, 18 seconds\nαñ╡αñ┐αñ╢αñ╛αñûαñ╛αñ¬αñƒαñ¿αñ« αñ╕αÑìαñƒαÑÇαñ▓ αñ¬αÑìαñ▓αñ╛αñéαñƒ αñ«αÑçαñé αñ¼αñíαñ╝αñ╛ αñ╣αñ╛αñªαñ╕αñ╛ αñ╣αÑüαñåαÑñ αñ¬αñ┐αñÿαñ▓αñ╛ αñ╣αÑüαñå αñ╕αÑìαñƒαÑÇαñ▓ αñùαñ┐αñ░αñ¿αÑç αñ╕αÑç αñåαñá αñ«αñ£αñªαÑéαñ░αÑïαñé αñòαÑÇ αñ«αÑîαññ αñ╣αÑï αñùαñêαÑñ αñòαñê αñ«αñ£αñªαÑéαñ░ αñ¥αÑüαñ▓αñ╕ αñùαñÅαÑñ αñ╣αñ╛αñªαñ╕αÑç αñòαÑÇ αñ╡αñ£αñ╣ αñ╕αÑç αñ¬αÑìαñ▓αñ╛αñéαñƒ αñ«αÑçαñé αñ«αñÜαÑÇ αñàαñ½αñ░αñ╛αññαñ½αñ░αÑÇαÑñ\n4:31\n4 minutes, 31 seconds\nαñ░αñ╛αñ£αñ╕αÑìαñÑαñ╛αñ¿ αñòαÑç αñ╕αñ┐αñ░αÑïαñ╣αÑÇ αñ«αÑçαñé αñªαÑüαñòαñ╛αñ¿ αñòαÑç αñ¼αñ╛αñ╣αñ░ αñ╕αÑç αñ¼αñ╛αñçαñò αñòαÑÇ αñÜαÑïαñ░αÑÇαÑñ αñ╕αÑÇαñ╕αÑÇαñƒαÑÇαñ╡αÑÇ αñ«αÑçαñé αñòαÑêαñª αñ╣αÑüαñå αñ¼αñ╛αñçαñò αñÜαÑïαñ░αÑñ αññαñ▓αñ╛αñ╢ αñ«αÑçαñé αñ£αÑüαñƒαÑÇ αñ¬αÑüαñ▓αñ┐αñ╕αÑñ\n4:41\n4 minutes, 41 seconds\nαñ«αñºαÑìαñ» αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñ╕αñ┐αñéαñùαÑîαñ▓αÑÇ αñ«αÑçαñé αñàαñ╕αÑìαñ¬αññαñ╛αñ▓ αñ«αÑçαñé αñùαñ╛αñ░αÑìαñí αñíαÑëαñòαÑìαñƒαñ░ αñ¼αñ¿ αñùαñ»αñ╛αÑñ αñ«αñ░αÑÇαñ£αÑïαñé αñòαÑï αñçαñéαñ£αÑçαñòαÑìαñ╢αñ¿ αñ▓αñùαñ╛αññαñ╛ αñ¿αñ£αñ░ αñåαñ»αñ╛αÑñ αñíαÑìαñ»αÑéαñƒαÑÇ αñòαÑç αñªαÑîαñ░αñ╛αñ¿ αñàαñ╕αÑìαñ¬αññαñ╛αñ▓ αñ╕αÑç αñùαñ╛αñ»αñ¼ αñÑαÑç αñíαÑëαñòαÑìαñƒαñ░ αñöαñ░ αñ¿αñ░αÑìαñ╕αÑñ αñ╡αÑÇαñíαñ┐αñ»αÑï αñ╕αñ╛αñ«αñ¿αÑçαÑñ\n4:49\n4 minutes, 49 seconds\nαñ╕αÑìαñ╡αñ╛αñ╕αÑìαñÑαÑìαñ» αñ╡αñ┐αñ¡αñ╛αñù αñ«αÑçαñé αñ╣αñíαñ╝αñòαñéαñ¬ αñ«αñÜ αñùαñ»αñ╛αÑñ\n4:57\n4 minutes, 57 seconds\nαñªαñ┐αñ▓αÑìαñ▓αÑÇ αñ«αÑçαñé αñùαÑêαñéαñùαñ╕αÑìαñƒαñ░ αñ╣αñ╛αñ╢αñ┐αñ« αñ¼αñ╛αñ¼αñ╛ αñòαñ╛ αñ╢αÑéαñƒαñ░ αñòαÑç αñ╕αñ╛αñÑ αñ¬αÑüαñ▓αñ┐αñ╕ αñòαÑÇ αñ«αÑüαñáαñ¡αÑçαñíαñ╝αÑñ αñ£αñ╡αñ╛αñ¼αÑÇ αñòαñ╛αñ░αñ╡αñ╛αñ╣αÑÇ αñ«αÑçαñé αñ¼αñªαñ«αñ╛αñ╢ αñòαÑç αñ¬αÑêαñ░ αñ«αÑçαñé αñùαÑïαñ▓αÑÇ αñ▓αñùαÑÇ αñ╣αÑêαÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ░ αñ▓αñ┐αñ»αñ╛αÑñ	f	2026-06-09 13:23:25.979616
31	UCRWFSbif-RFENbBrSiez1DA	National	General	Transcript\nSearch transcript\n0:02\n2 seconds\nαñ»αñ«αñ¿ αñòαÑç αñ╣αÑüαññαÑÇ αñ╡αñ┐αñªαÑìαñ░αÑïαñ╣αñ┐αñ»αÑïαñé αñ¿αÑç αñòαñ┐αñ»αñ╛ αñçαñ£αñ░αñ╛αñçαñ▓ αñ¬αñ░ αñ«αñ┐αñ╕αñ╛αñçαñ▓ αñ╣αñ«αñ▓αÑç αñòαñ╛ αñªαñ╛αñ╡αñ╛αÑñ αñòαñ╣αñ╛ αñòαñ┐ αñ▓αñ╛αñ▓ αñ╕αñ╛αñùαñ░ αñ«αÑçαñé αñçαñ£αñ░αñ╛αñçαñ▓ αñ╕αÑç αñ£αÑüαñíαñ╝αÑç αñ£αñ╣αñ╛αñ£αÑïαñé αñ¬αñ░ αñ½αñ┐αñ░ αñ╕αÑç αñ╣αñ«αñ▓αÑç αñ╣αÑïαñéαñùαÑçαÑñ\n0:13\n13 seconds\nαñ╣αÑ¢αñ¼αÑüαñ▓αÑìαñ▓αñ╛ αñ¿αÑç αñòαñ┐αñ»αñ╛ αñçαñ£αñ░αñ╛αñçαñ▓αÑÇ αñ╕αÑçαñ¿αñ╛ αñòαÑç αñƒαÑêαñéαñò αñ¬αñ░ αñ╣αñ«αñ▓αÑç αñòαñ░αñ¿αÑç αñòαñ╛ αñªαñ╛αñ╡αñ╛αÑñ αñªαñòαÑìαñ╖αñ┐αñúαÑÇ αñ▓αñ╛αñ¼αñ¿αñ╛αñ¿ αñ«αÑçαñé αñçαñ£αñ░αñ╛αñ»αñ▓αÑÇ αñ«αñ░αñòαñ╛αñ╡αñ╛ αñƒαÑêαñéαñò αñ¬αñ░ αñíαÑìαñ░αÑïαñ¿ αñ╕αÑç αñ╣αñ«αñ▓αñ╛ αñòαñ░αñ¿αÑç αñòαñ╛ αñ╡αÑÇαñíαñ┐αñ»αÑï αñ£αñ╛αñ░αÑÇ αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛αÑñ\n0:24\n24 seconds\nαñëαññαÑìαññαñ░αÑÇ αñçαñ░αñ╛αñò αñ«αÑçαñé αñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñáαñ┐αñòαñ╛αñ¿αÑïαñé αñ¬αñ░ αñêαñ░αñ╛αñ¿ αñòαÑç αñ╣αñ«αñ▓αÑç αñ╕αÑïαñ░αñ╛αñ¿ αñöαñ░ αñûαñ▓αÑÇαñ½αñ╛αñ¿ αñòαÑç αñèαñ¬αñ░ αñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñÅαñ»αñ░ αñíαñ┐αñ½αÑçαñéαñ╕ αñ╕αñ┐αñ╕αÑìαñƒαñ« αñ¿αÑç αñòαñê αñíαÑìαñ░αÑïαñ¿ αñòαÑï αñçαñéαñƒαñ░αñ╕αÑçαñ¬αÑìαñƒ αñòαñ┐αñ»αñ╛αÑñ\n0:35\n35 seconds\nαñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñ╕αÑçαñ¿αñ╛ αñ¿αÑç αñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑÇ αñôαñ░ αñªαñ╛αñùαÑÇ αñùαñê αñêαñ░αñ╛αñ¿αÑÇ αñ«αñ┐αñ╕αñ╛αñçαñ▓αÑïαñé αñòαÑï αñçαñéαñƒαñ░αñ╕αÑçαñ¬αÑìαñƒ αñòαñ░αñ¿αÑç αñ«αÑçαñé αñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑÇ αñ«αñªαñª αñòαÑÇαÑñ αñ«αÑÇαñíαñ┐αñ»αñ╛ αñ░αñ┐αñ¬αÑïαñ░αÑìαñƒαÑìαñ╕ αñ«αÑçαñé αñªαñ╛αñ╡αñ╛ αñòαñ┐αñ»αñ╛ αñ£αñ╛ αñ░αñ╣αñ╛ αñ╣αÑê αñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñàαñºαñ┐αñòαñ╛αñ░αñ┐αñ»αÑïαñé αñòαÑç αñ╣αñ╡αñ╛αñ▓αÑç αñ╕αÑç αñûαñ¼αñ░αÑñ\n0:47\n47 seconds\nαñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑÇ αñ¬αÑÇαñÅαñ« αñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑç αñ¬αÑÇαñÅαñ« αñ«αñ┐αñÑαñ¿ αñ»αñ╛αñ╣αÑé αñ¿αÑç αñƒαÑìαñ░αñéαñ¬ αñ╕αÑç αñòαñ╣αñ╛ αñòαñ┐ αñêαñ░αñ╛αñ¿ αñòαÑç αñ╣αñ«αñ▓αÑç αñòαñ╛ αñ£αñ╡αñ╛αñ¼ αñ¿αñ╛ αñªαÑçαñ¿αñ╛ αñçαñ£αñ░αñ╛αñçαñ▓ αñöαñ░ αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñªαÑïαñ¿αÑïαñé αñòαÑç αñ▓αñ┐αñÅ αñ¼αÑüαñ░αñ╛ αñ╣αÑïαñùαñ╛αÑñ αñíαÑÇαñ▓ αñòαÑç αñ▓αñ┐αñÅ αñ¡αÑÇ αñ╣αÑïαñùαñ╛ αñ¿αÑüαñòαñ╕αñ╛αñ¿αñªαÑçαñ╣αÑñ\n1:00\n1 minute\nαñêαñ░αñ╛αñ¿ αñòαÑÇ αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñöαñ░ αñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑï αñÜαÑçαññαñ╛αñ╡αñ¿αÑÇαÑñ\n1:02\n1 minute, 2 seconds\nαñòαñ╣αñ╛ αññαñ¿αñ╛αñ╡ αñ¼αñóαñ╝αñ╛αñ¿αÑç αñòαÑÇ αñòαÑïαñ╢αñ┐αñ╢ αñòαÑÇ αññαÑï αñ«αñ┐αñ▓αÑçαñùαñ╛ αñ«αÑüαñéαñ╣αññαÑïαñíαñ╝ αñ£αñ╡αñ╛αñ¼αÑñ αñêαñ░αñ╛αñ¿ αñöαñ░ αñëαñ¿αñòαÑç αñ╕αñ╣αñ»αÑïαñùαñ┐αñ»αÑïαñé αñòαÑç αñ¬αñ╛αñ╕ αñ£αñ╡αñ╛αñ¼ αñªαÑçαñ¿αÑç αñòαÑÇ αñòαÑìαñ╖αñ«αññαñ╛αÑñ\n1:12\n1 minute, 12 seconds\nαñçαñ£αñ░αñ╛αñçαñ▓αÑÇ αñ¬αÑìαñ░αñºαñ╛αñ¿αñ«αñéαññαÑìαñ░αÑÇ αñ¼αÑçαñéαñ£αñ« αñ¿αÑçαññαñ¿αÑìαñ»αñ╛ αñ¿αÑç αñòαñ╣αñ╛ αñ½αñ┐αñ▓αñ╣αñ╛αñ▓ αñêαñ░αñ╛αñ¿ αñòαÑç αñ╕αñ╛αñÑ αñÑαñ« αñùαñê αñ╣αÑê αñ▓αñíαñ╝αñ╛αñêαÑñ\n1:17\n1 minute, 17 seconds\nαñêαñ░αñ╛αñ¿ αñ¿αÑç αñªαÑïαñ¼αñ╛αñ░αñ╛ αñ╣αñ«αñ▓αñ╛ αñòαñ┐αñ»αñ╛ αññαÑï αñçαñ£αñ░αñ╛αñçαñ▓ αñªαÑçαñùαñ╛ αñ¬αÑéαñ░αÑÇ αññαñ╛αñòαññ αñòαÑç αñ╕αñ╛αñÑ αñ£αñ╡αñ╛αñ¼αÑñ αñíαÑïαñ¿αñ▓αÑìαñí αñƒαÑìαñ░αñéαñ¬ αñ¿αÑç αññαÑïαñ¿αñ»αñ╛ αñòαÑï αñªαÑÇ αñÑαÑÇ αñ╣αñ┐αñªαñ╛αñ»αññαÑñ\n1:25\n1 minute, 25 seconds\nαñòαñ╣αñ╛ αñòαñ┐ αñêαñ░αñ╛αñ¿ αñòαÑç αñ╕αñ╛αñÑ αñ½αñ┐αñ░ αñ╕αÑç αñ»αÑüαñªαÑìαñº αñ«αÑçαñé αñëαññαñ░αÑç αññαÑï αñëαñ¿αÑìαñ╣αÑçαñé αñàαñòαÑçαñ▓αÑç αñ╣αÑÇ αñ▓αñíαñ╝αñ¿αñ╛ αñ¬αñíαñ╝ αñ╕αñòαññαñ╛ αñ╣αÑê αñ»αÑüαñªαÑìαñºαÑñ αñÉαñ╕αñ╛ αñòαñ┐αñ»αñ╛ αññαÑï αñàαñ▓αñù-αñÑαñ▓αñù αñ¬αñíαñ╝ αñ£αñ╛αñÅαñùαñ╛ αñçαñ£αñ░αñ╛αñçαñ▓αÑñ\n1:35\n1 minute, 35 seconds\nαñêαñ░αñ╛αñ¿ αñòαÑç αñëαñ¬αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ¬αññαñ┐ αñ«αÑïαñ╣αñ«αÑìαñ«αñª αñ░αñ£αñ╛ αñåαñ░αñ┐αñ½ αñòαñ╛ αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñöαñ░ αñçαñ£αñ░αñ╛αñçαñ▓ αñ¬αñ░ αñ¿αñ┐αñ╢αñ╛αñ¿αñ╛αÑñ αñòαñ╣αñ╛ αñªαÑüαñ╢αÑìαñ«αñ¿ αñªαÑçαñ╢αÑïαñé αñòαÑï αñ¼αñ╣αÑüαññ αñòαñ« αñ╕αñ«αñ» αñ«αÑçαñé αñ╣αÑüαñå αñêαñ░αñ╛αñ¿ αñòαÑÇ\n1:43\n1 minute, 43 seconds\nαññαñ╛αñòαññ αñòαñ╛ αñÅαñ╣αñ╕αñ╛αñ╕αÑñ αñ»αÑüαñªαÑìαñº αñ╡αñ┐αñ░αñ╛αñ« αñ╕αÑìαñ╡αÑÇαñòαñ╛αñ░ αñòαñ░αñ¿αÑç αñòαÑÇ αñùαÑüαñ╣αñ╛αñ░ αñ▓αñùαñ╛αñ¿αÑç αñ¬αñ░ αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛ αñ«αñ£αñ¼αÑéαñ░αÑñ\n1:50\n1 minute, 50 seconds\nαñ½αÑìαñ░αñ╛αñéαñ╕ αñ«αÑçαñé αñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑç αñ░αñ╛αñ£αñªαÑéαññ αñ£αÑïαñ╢αÑüαñå αñ£αñ╛αñ░αñòαñ╛ αñòαñ╛ αñ¼αñ»αñ╛αñ¿αÑñ αñòαñ╣αñ╛ αñçαñ£αñ░αñ╛αñçαñ▓ αñöαñ░ αñêαñ░αñ╛αñ¿ αñòαÑç αñ¼αÑÇαñÜ αñ▓αñíαñ╝αñ╛αñê αñ½αñ┐αñ░ αñ╕αÑç αñ╢αÑüαñ░αÑé αñòαñ░αñ¿αÑç αñòαñ╛ αñ½αÑêαñ╕αñ▓αñ╛ αñêαñ░αñ╛αñ¿ αñòαñ╛ αñÑαñ╛αÑñ\n1:57\n1 minute, 57 seconds\nαñ»αÑüαñªαÑìαñº αñ╡αñ┐αñ░αñ╛αñ« αñòαÑç αñ¼αñ╛αñª αñ╕αÑç αñªαÑïαñ¿αÑïαñé αñ¬αñòαÑìαñ╖αÑïαñé αñòαÑç αñ¼αÑÇαñÜ αñ¬αñ╣αñ▓αÑÇ αñ¼αñ╛αñ░ αñ╣αñ«αñ▓αÑç αñ╣αÑüαñÅαÑñ\n2:02\n2 minutes, 2 seconds\nαñ╕αñéαñ»αÑüαñòαÑìαññ αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░ αñ¿αÑç αñ«αñ┐αñíαñ┐αñ▓ αñêαñ╕αÑìαñƒ αñ«αÑçαñé αñ¼αñóαñ╝αññαÑç αññαñ¿αñ╛αñ╡ αñ¬αñ░ αñÅαñò αñ¼αñ╛αñ░ αñ½αñ┐αñ░ αñ╕αÑç αñÜαñ┐αñéαññαñ╛ αñ╡αÑìαñ»αñòαÑìαññ αñòαÑÇαÑñ\n2:06\n2 minutes, 6 seconds\nαñ╕αñ¡αÑÇ αñ¬αñòαÑìαñ╖αÑïαñé αñ╕αÑç αñ╕αñéαñ»αñ« αñ¼αñ░αññαñ¿αÑç αñòαÑÇ αñàαñ¬αÑÇαñ▓ αñòαÑÇαÑñ αñòαñ╣αñ╛ αñ╣αñ╛αñ▓αñ┐αñ»αñ╛ αñ╣αñ«αñ▓αÑïαñé αñ╕αÑç αñòαÑìαñ╖αÑçαññαÑìαñ░ αñ«αÑçαñé αñ¼αñíαñ╝αÑç αñ»αÑüαñªαÑìαñº αñòαñ╛ αñûαññαñ░αñ╛ αñ¼αñóαñ╝ αñùαñ»αñ╛ αñ╣αÑêαÑñ\n2:15\n2 minutes, 15 seconds\nαñêαñ░αñ╛αñ¿ αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñ¬αñ░αñ«αñ╛αñúαÑü αñ╡αñ╛αñ░αÑìαññαñ╛ αñ«αÑçαñé αñ¿αñ»αñ╛ αñ¬αÑçαñÜ αñ½αñéαñ╕αñ╛αÑñ αñêαñ░αñ╛αñ¿ αñ¿αÑç αñíαÑìαñ░αñ╛αñ½αÑìαñƒ αñ«αÑçαñ«αÑïαñ░αÑçαñéαñíαñ« αñ«αÑçαñé αñòαñ┐αñÅ αñùαñÅ αñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñ¼αñªαñ▓αñ╛αñ╡αÑïαñé αñòαÑï αñ¿αñ╛αñ«αñ£αÑéαñ░ αñòαñ┐αñ»αñ╛αÑñ αñòαñ╣αñ╛\n2:23\n2 minutes, 23 seconds\nαñ½αÑìαñ░αÑÇ αñ╕αñéαñ¬αññαÑìαññαñ┐αñ»αñ╛αñé αñ£αñ╛αñ░αÑÇ αñ╣αÑïαñ¿αÑç αñöαñ░ αñ¬αÑìαñ░αññαñ┐αñ¼αñéαñº αñ╣αñƒαñ¿αÑç αññαñò αñòαÑïαñê αñ╕αñ«αñ¥αÑîαññαñ╛ αñ╕αñéαñ¡αñ╡ αñ╣αÑÇ αñ¿αñ╣αÑÇαñéαÑñ\n2:31\n2 minutes, 31 seconds\nαñêαñ░αñ╛αñ¿ αñòαÑÇ αñ╕αñ░αñòαñ╛αñ░αÑÇ αñÅαñ£αÑçαñéαñ╕αÑÇ αñ¿αÑç αñ£αñ╛αñ░αÑÇ αñòαñ┐αñ»αñ╛ αñ╣αÑëαñ░αñ░αñ«αÑéαñ╕ αñòαñ╛ αñÅαñò αñ¿αñ»αñ╛ αñ╡αÑÇαñíαñ┐αñ»αÑïαÑñ αñ╡αÑÇαñíαñ┐αñ»αÑï αñ«αÑçαñé αñªαñ╛αñ╡αñ╛ αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛ αñ╣αÑê αñòαñ┐ αñ╣αÑëαñ░αñ«αÑéαñ╕ αñ¬αñ░ αñ½αñ┐αñ▓αñ╣αñ╛αñ▓ αñêαñ░αñ╛αñ¿ αñòαñ╛ αñ¿αñ┐αñ»αñéαññαÑìαñ░αñú αñ╣αÑêαÑñ αñ╕αÑêαñ¿αñ┐αñ»αñ╛ αñ«αñéαñ£αÑéαñ░αÑÇ αñòαÑç αñ¼αñùαÑêαñ░ αñ£αñ╣αñ╛αñ£αÑïαñé αñòαÑÇ αñåαñ╡αñ╛αñ£αñ╛αñ╣αÑÇ αñ╕αñéαñ¡αñ╡ αñ╣αÑÇ αñ¿αñ╣αÑÇαñéαÑñ\n2:44\n2 minutes, 44 seconds\nαñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑç αñ¬αÑÇαñÅαñ« αñ¿αÑç αñ»αñ╛αñ╣αÑé αñòαñ╛ αñ¼αñ»αñ╛αñ¿ αñòαñ╣αñ╛ αñ╣αÑê αñ╣αÑ¢αñ¼αÑüαñ▓αÑìαñ▓αñ╛ αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñ£αñ╛αñ░αÑÇ αñ╣αÑê αñçαñ£αñ░αñ▓αÑÇαñ» αñ╕αÑçαñ¿αñ╛ αñòαñ╛ αñæαñ¬αñ░αÑçαñ╢αñ¿αÑñ αñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑï αñ╕αÑçαñ▓αÑìαñ½ αñíαñ┐αñ½αÑçαñéαñ╕ αñòαñ╛ αñ¬αÑéαñ░αñ╛ αñàαñºαñ┐αñòαñ╛αñ░ αñ╣αÑêαÑñ αñçαñ╕αñòαñ╛ αñ¬αÑéαñ░αÑÇ αññαñ░αñ╣ αñ╕αÑç αñòαñ░αÑçαñéαñùαÑç αñçαñ╕αÑìαññαÑçαñ«αñ╛αñ▓αÑñ\n2:56\n2 minutes, 56 seconds\nαñöαñ░ αñàαñ¼ αñ¼αñ╛αññ αñòαñ░αÑçαñéαñùαÑç αñ░αñ╛αñ£αñ¿αÑÇαññαñ┐ αñòαÑÇ αñûαñ¼αñ░αÑïαñé αñòαÑÇαÑñ\n2:58\n2 minutes, 58 seconds\nαñ«αñ«αññαñ╛ αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñòαÑï αñÅαñò αñòαÑç αñ¼αñ╛αñª αñÅαñò αñ¥αñƒαñòαÑç αñ«αñ┐αñ▓ αñ░αñ╣αÑç αñ╣αÑêαñéαÑñ αñ╡αñ┐αñºαñ╛αñ¿αñ╕αñ¡αñ╛ αñòαÑç αñ¼αñ╛αñª αñàαñ¼ αñ╕αñéαñ╕αñª αñ«αÑçαñé αñ¡αÑÇ αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñòαÑç αñƒαÑéαñƒαñ¿αÑç αñòαÑÇ αñàαñƒαñòαñ▓αÑçαñé αññαÑçαñ£ αñ╣αÑï αñùαñê αñ╣αÑêαñéαÑñ\n3:04\n3 minutes, 4 seconds\nαññαÑï αñ╡αñ╣αÑÇαñé αñòαñ▓ αñªαñ┐αñ▓αÑìαñ▓αÑÇ αñ«αÑçαñé αñ╣αÑüαñê αñçαñéαñíαñ┐αñ»αñ╛ αñùαñáαñ¼αñéαñºαñ¿ αñòαÑÇ αñ¼αÑêαñáαñò αñ«αÑçαñé αñ╕αñ¡αÑÇ αñªαñ▓αÑïαñé αñòαÑç αñ¬αñ╛αñéαñÜ αñ«αÑüαñªαÑìαñªαÑïαñé αñ¬αñ░ αñ╕αñ¡αÑÇ αñªαñ▓αÑïαñé αñòαÑÇ αññαñ░αñ½ αñ╕αÑç αñ╕αñ╣αñ«αññαñ┐ αñ¼αñ¿ αñùαñê αñ╣αÑêαÑñ αñ¬αÑéαñ░αÑÇ αñ£αñ╛αñ¿αñòαñ╛αñ░αÑÇ αñåαñ¬αñòαÑï αñªαÑç αñªαÑçαññαÑç αñ╣αÑêαñé αñ╣αñ« αñ¿αÑîαñ╕αÑçαñò αñ¿αÑìαñ»αÑéαñ£αñ╝ αñ«αÑçαñé αñ½αñƒαñ╛αñ½αñƒαÑñ\n3:17\n3 minutes, 17 seconds\nαñ¬αñ╢αÑìαñÜαñ┐αñ« αñ¼αñéαñùαñ╛αñ▓ αñ╡αñ┐αñºαñ╛αñ¿αñ╕αñ¡αñ╛ αñòαÑç αñ¼αñ╛αñª αñ╕αñéαñ╕αñª αñ«αÑçαñé αñ¡αÑÇ αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñƒαÑéαñƒαÑÇαÑñ αñ¼αñ╛αñùαÑÇ αñùαÑüαñƒ αñòαñ╛ αñªαñ╛αñ╡αñ╛αÑñ αñ╣αñ«αñ╛αñ░αÑç αñ¬αñ╛αñ╕ αñ╣αÑê 20 αñ╕αñ╛αñéαñ╕αñªαÑïαñé αñòαñ╛ αñ╕αñ«αñ░αÑìαñÑαñ¿αÑñ αñòαñ╣αñ╛ αñ¼αñ¿αñ╛αñÅαñéαñùαÑç αñÅαñò αñàαñ▓αñù αñùαÑüαñƒαÑñ\n3:27\n3 minutes, 27 seconds\nαñ░αñ╛αñ£αÑìαñ»αñ╕αñ¡αñ╛ αñ╕αÑç αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ╕αñ╛αñéαñ╕αñª αñ╕αÑüαñûαÑçαñéαñªαÑìαñ░ αñ╢αÑçαñûαñ░ αñ░αÑëαñ» αñòαñ╛ αñçαñ╕αÑìαññαÑÇαñ½αñ╛αÑñ αñ«αñ«αññαñ╛ αñ¬αñ░ αñ▓αñùαñ╛αñ»αñ╛ αñåαñ░αÑïαñ¬αÑñ αñåαñ¿αÑç αñ╡αñ╛αñ▓αÑç αñªαñ┐αñ¿αÑïαñé αñ«αÑçαñé αñ░αñ╛αñ£αÑìαñ»αñ╕αñ¡αñ╛ αñ╕αÑç αñ╣αÑï αñ╕αñòαññαÑç αñ╣αÑêαñé αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñòαÑç αñòαñê αñöαñ░ αñ╕αñ╛αñéαñ╕αñªαÑïαñé αñòαÑç αñçαñ╕αÑìαññαÑÇαñ½αÑçαÑñ\n3:37\n3 minutes, 37 seconds\nαñòαÑçαñéαñªαÑìαñ░αÑÇαñ» αñ«αñéαññαÑìαñ░αÑÇ αñ¡αÑéαñ¬αÑçαñéαñªαÑìαñ░ αñ»αñ╛αñªαñ╡ αñòαÑç αñÿαñ░αÑñ\n3:39\n3 minutes, 39 seconds\nαñƒαÑÇαñÅαñ«αñ╕αÑÇ αñòαÑç αñ¼αñ╛αñùαÑÇ αñ╕αñ╛αñéαñ╕αñªαÑïαñé αñ╕αÑç αñ«αñ┐αñ▓αÑç αñ╕αÑÇαñÅαñ« αñ╢αÑüαñ¡αÑçαñéαñªαÑü αñàαñºαñ┐αñòαñ╛αñ░αÑÇαÑñ αñ¼αÑêαñáαñò αñ«αÑçαñé 14 αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ╕αñ╛αñéαñ╕αñªαÑïαñé αñòαÑç αñ«αÑîαñ£αÑéαñª αñ╣αÑïαñ¿αÑç αñöαñ░ αñòαÑüαñ¢ αñòαÑç αñæαñ¿αñ▓αñ╛αñçαñ¿ αñ£αÑüαñíαñ╝αñ¿αÑç αñòαñ╛ αñªαñ╛αñ╡αñ╛ αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛αÑñ\n3:49\n3 minutes, 49 seconds\n20 αñ╕αñ╛αñéαñ╕αñªαÑïαñé αñòαÑç αñªαñ╛αñ╡αÑç αñòαÑï αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ╕αñ╛αñéαñ╕αñª αñòαÑÇαñ░αÑìαññαñ┐ αñåαñ£αñ╛αñª αñ¿αÑç αñ¼αññαñ╛αñ»αñ╛ αñ½αñ░αÑìαñ£αÑÇαÑñ αñòαñ╣αñ╛ αñ¡αÑéαñ¬αÑçαñéαñªαÑìαñ░ αñ»αñ╛αñªαñ╡ αñòαÑç αñÿαñ░ αñ¬αñ░ αñ╣αÑüαñê αñ¼αÑêαñáαñò αñ«αÑçαñé αñòαÑçαñ╡αñ▓ 13 αñ╕αñ╛αñéαñ╕αñª αñ¿αñ╛ αñòαñ┐ 20 αñ╕αñ╛αñéαñ╕αñªαÑñ\n4:00\n4 minutes\nαñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ¿αÑçαññαñ╛ αñ«αñ╣αñ╡αñ╛ αñ«αÑïαñ╣αññαÑìαñ░αñ╛ αñòαñ╛ αñ¼αñ╛αñùαñ┐αñ»αÑïαñé αñ¬αñ░ αññαÑÇαñûαñ╛ αñ╣αñ«αñ▓αñ╛αÑñ αñòαñ╣αñ╛ αñòαñ┐ αñçαñ╕αÑìαññαÑÇαñ½αñ╛ αñªαÑçαñòαñ░ αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñòαÑç αñƒαñ┐αñòαñƒ αñ¬αñ░ αñ▓αñíαñ╝αÑç αñÜαÑüαñ¿αñ╛αñ╡αÑñ αñªαÑçαñûαññαÑç αñ╣αÑêαñé αñåαñ¬ αñòαñ┐αññαñ¿αÑç αñ¼αñíαñ╝αÑç αñ╣αÑÇαñ░αÑï αñ╣αÑêαñéαÑñ\n4:11\n4 minutes, 11 seconds\nαñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ«αÑçαñé αñƒαÑéαñƒ αñòαÑï αñ▓αÑçαñòαñ░ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñ¿αÑçαññαñ╛ αñ£αñ» αñ░αñ╛αñ« αñ░αñ«αÑçαñ╢ αñòαñ╛αÑñ αñ¡αÑéαñ¬αÑçαñéαñªαÑìαñ░ αñ»αñ╛αñªαñ╡ αñ¬αñ░ αñ¿αñ┐αñ╢αñ╛αñ¿αñ╛αÑñ αñòαñ╣αñ╛ αñ╢αñ┐αñòαñ╛αñ░ αñ░αÑïαñòαñ¿αÑç αñ╡αñ╛αñ▓αÑç αñ«αñéαññαÑìαñ░αÑÇ αñ¼αñ¿αÑç αñ╢αñ┐αñòαñ╛αñ░αÑÇαÑñ\n4:17\n4 minutes, 17 seconds\n[αñ╕αñéαñùαÑÇαññ] αñàαñ╡αÑêαñº αñ╢αñ┐αñòαñ╛αñ░ αñ«αÑçαñé αñ¼αñ┐αññαñ╛αñ»αñ╛ αñªαñ┐αñ¿αÑñ\n4:23\n4 minutes, 23 seconds\nαñƒαÑÇαñÅαñ«αñ╕αÑÇ αñòαÑç αñ¼αñ╛αñùαñ┐αñ»αÑïαñé αñòαñ╛ αñ¡αÑÇ αñ╕αñ╛αñéαñ╕αñª αñ╣αÑïαñ¿αÑç αñòαñ╛ αñªαñ╛αñ╡αñ╛αÑñ αñòαÑçαñéαñªαÑìαñ░αÑÇαñ» αñ«αñéαññαÑìαñ░αÑÇ αñùαñ┐αñ░αñ┐αñ░αñ╛αñ£ αñ╕αñ┐αñéαñ╣ αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñàαñ¼ αñûαññαÑìαñ«αÑñ αñíαÑéαñ¼αññαÑÇ αñ¿αñ╛αñ╡ αñ¬αñ░ αñòαÑîαñ¿ αñ¼αÑêαñáαÑçαñùαñ╛? αñàαñ¼\n4:34\n4 minutes, 34 seconds\nαñçαñéαñíαñ┐αñ»αñ╛ αñùαñáαñ¼αñéαñºαñ¿ αñòαÑÇ αñ¼αÑêαñáαñò αñ«αÑçαñé αñ¬αñ╛αñéαñÜ αñ«αÑüαñªαÑìαñªαÑïαñé αñòαÑï αñëαñáαñ╛αñ¿αÑç αñ¬αñ░ αñ╕αñ╣αñ«αññαñ┐ αñ¼αñ¿ αñùαñê αñ╣αÑêαÑñ αñÅαñò αñ«αññ αñ╕αÑç αñ«αñ╛αñéαñùαñ╛ αñùαñ»αñ╛ αñ╣αÑê αñºαñ░αÑìαñ«αÑçαñéαñªαÑìαñ░ αñ¬αÑìαñ░αñºαñ╛αñ¿ αñòαñ╛ αñçαñ╕αÑìαññαÑÇαñ½αñ╛αÑñ αñÜαÑÇαñ½ αñ£αñ╕αÑìαñƒαñ┐αñ╕ αñòαÑï αñÅαñÅαñ╕αñåαñêαñåαñ░ αñÜαÑüαñ¿αñ╛αñ╡ αñ«αÑçαñé\n4:42\n4 minutes, 42 seconds\nαñ╡αÑçαñƒ αñòαÑÇ αñ╡αÑïαñƒ αñòαÑÇ αñ▓αÑéαñƒαÑñ αñÜαÑïαñ░αÑÇ αñòαÑç αñ«αÑüαñªαÑìαñªαÑç αñ¬αñ░ αñ▓αñ┐αñûαñ╛ αñ£αñ╛αñÅαñùαñ╛ αñ¬αññαÑìαñ░αÑñ\n4:49\n4 minutes, 49 seconds\nαñçαñéαñíαñ┐αñ»αñ╛ αñùαñáαñ¼αñéαñºαñ¿ αñòαÑÇ αñ¼αÑêαñáαñò αñ«αÑçαñé αñ░αñ╛αñ╣αÑüαñ▓ αñùαñ╛αñéαñºαÑÇ αñ¿αÑç αñòαñ╣αñ╛ αñ╕αñ░αñòαñ╛αñ░ αñòαÑÇ αñ╡αñ┐αñªαÑçαñ╢ αñ¿αÑÇαññαñ┐ αñ½αÑçαñ▓ αñ╣αÑüαñêαÑñ αñ¬αñ╢αÑìαñÜαñ┐αñ« αñÅαñ╢αñ┐αñ»αñ╛ αñ╕αñéαñòαñƒ αñ¬αñ░ αñ╕αñ░αñòαñ╛αñ░ αñòαñ╛ αñ░αÑüαñû αñ╕αñ╛αñ½ αñ¿αñ╣αÑÇαñé αñ░αñ╣αñ╛αÑñ\n4:58\n4 minutes, 58 seconds\nαñ¼αÑçαñ░αÑïαñ£αñùαñ╛αñ░αÑÇ, αñ«αñ╣αñéαñùαñ╛αñê αñöαñ░ αñ£αñ¿ αñ╕αñ░αÑïαñòαñ╛αñ░αÑïαñé αñ╕αÑç αñ£αÑüαñíαñ╝αÑç αñ╣αÑüαñÅ αñ«αÑüαñªαÑìαñªαÑïαñé αñ¬αñ░ αñ╕αñ░αÑìαñ╡αñªαñ▓αÑÇαñ» αñ¼αÑêαñáαñò αñ¼αÑüαñ▓αñ╛αñ¿αÑç αñòαÑÇ αñ«αñ╛αñéαñùαÑñ αñ╣αñ░ αñªαÑï αñ«αñ╣αÑÇαñ¿αÑç αñ¬αñ░ αñ╣αÑïαñùαÑÇ αñçαñéαñíαñ┐αñ»αñ╛ αñùαñáαñ¼αñéαñºαñ¿ αñòαÑÇ αñ¼αÑêαñáαñòαÑñ αñ╣αÑêαñªαñ░αñ╛αñ¼αñ╛αñª αñ«αÑçαñé αñ╣αÑïαñùαÑÇ αñàαñùαñ▓αÑÇ [αñ╕αñéαñùαÑÇαññ] αñ¼αÑêαñáαñòαÑñ\n5:10\n5 minutes, 10 seconds\nαñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñòαñ╛ αñçαñéαñíαñ┐αñ»αñ╛ αñùαñáαñ¼αñéαñºαñ¿ αñ¬αñ░ αñ¬αñ▓αñƒαñ╡αñ╛αñ░αÑñ αñ╕αñ«αñ┐αññ αñ¬αñ╛αññαÑìαñ░αñ╛ αñ¿αÑç αñ╡αñ┐αñ¬αñòαÑìαñ╖αÑÇ αñªαñ▓αÑïαñé αñòαÑÇ αñÅαñòαñ£αÑüαñƒαññαñ╛ αñöαñ░ αñ░αñ╛αñ£αñ¿αÑÇαññαñ┐αñò αñ╕αÑìαñÑαñ┐αññαñ┐ αñ¬αñ░ αñ╕αñ╡αñ╛αñ▓ αñëαñáαñ╛αñÅαÑñ αñòαñ╣αñ╛ αñ╡αÑïαñƒ αñ¿αñ╣αÑÇαñé αñçαñéαñíαñ┐αñ»αñ╛ αñùαñáαñ¼αñéαñºαñ¿ αñòαñ╛ αñ╡αñ£αÑéαñª αñÜαÑïαñ░αÑÇ αñ╣αÑüαñåαÑñ\n5:22\n5 minutes, 22 seconds\nαñ╕αñ«αñ┐αññ αñ¬αñ╛αññαÑìαñ░αñ╛ αñòαÑç αñ¼αñ»αñ╛αñ¿ αñ¬αñ░ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñ¿αÑçαññαñ╛ αñ¡αÑéαñ¬αÑçαñ╢ αñ¼αñÿαÑçαñ▓ αñ¼αÑïαñ▓αÑç αññαÑçαñ▓ αñùαÑêαñ╕ αñòαÑÇ αñ¼αñóαñ╝αññαÑÇ αñòαÑÇαñ«αññαÑïαñé αñ¼αñ┐αñ£αñ▓αÑÇ αñòαÑÇ αñòαñƒαÑîαññαÑÇ αñ¬αñ░ αñºαÑìαñ»αñ╛αñ¿ αñªαÑçαñéαÑñ αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñ¿αñ╣αÑÇαñé αñòαñ░αñ╡αñ╛ αñ¬αñ╛ αñ░αñ╣αÑÇ αñÅαñò αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛ αññαñòαÑñ\n5:33\n5 minutes, 33 seconds\nαñàαñûαñ┐αñ▓αÑçαñ╢ αñ»αñ╛αñªαñ╡ αñ¬αñ░ αñ»αÑéαñ¬αÑÇ αñòαÑç αñíαñ┐αñ¬αÑìαñƒαÑÇ αñ╕αÑÇαñÅαñ« αñ░αñ╛αñ£αÑçαñ╢ αñ¬αñ╛αñáαñò αñòαñ╛ αñ¿αñ┐αñ╢αñ╛αñ¿αñ╛αÑñ αñòαñ╣αñ╛ αñ¼αñ╛αñ¼αñ░αñ╡αñ╛αñªαÑÇ αñ╣αÑê αñ╕αÑïαñÜαÑñ 2027 αñ«αÑçαñé αñ╕αñ«αñ╛αñ£αñ╡αñ╛αñªαÑÇ αñ¬αñ╛αñ░αÑìαñƒαÑÇ αñòαÑï αñ«αñ┐αñ▓αÑçαñùαÑÇ αñ╣αñ╛αñ░αÑñ\n5:43\n5 minutes, 43 seconds\nαñ░αñ╛αñ« αñ«αñéαñªαñ┐αñ░ αñòαÑç αñÜαñóαñ╝αñ╛αñ╡αÑç αñ¬αñ░ αñ╕αñ┐αñ»αñ╛αñ╕αÑÇ αñÿαñ«αñ╛αñ╕αñ╛αñ¿ αñ£αñ╛αñ░αÑÇ αñ╣αÑêαÑñ αñåαñ« αñåαñªαñ«αÑÇ αñ¬αñ╛αñ░αÑìαñƒαÑÇ αñòαÑç αñ╕αñ╛αñéαñ╕αñª αñ╕αñéαñ£αñ» αñ╕αñ┐αñéαñ╣ αñ¿αÑç αñ▓αñùαñ╛αñ»αñ╛ αñÜαÑïαñ░αÑÇ αñòαñ╛ αñåαñ░αÑïαñ¬αÑñ αñòαñ╣αñ╛ αñÜαñéαñªαñ╛ αñÜαÑïαñ░ αñùαñªαÑìαñªαÑÇ αñ¢αÑïαñíαñ╝αÑçαÑñ\n5:54\n5 minutes, 54 seconds\nαñàαñûαñ┐αñ▓αÑçαñ╢ αñ»αñ╛αñªαñ╡ αñ¬αñ░ αñôαñ¬αÑÇ αñ░αñ╛αñ£αñ¡αñ░ αñ¿αÑç αñùαÑüαñ«αñ░αñ╛αñ╣ αñòαñ░αñ¿αÑç αñòαÑç αñåαñ░αÑïαñ¬ αñ▓αñùαñ╛αñÅαÑñ αñòαñ╣αñ╛ αñ╣αÑê αñòαñ┐ αñàαñûαñ┐αñ▓αÑçαñ╢ αñòαÑìαñ»αñ╛ αñòαñ¡αÑÇ αñùαñÅ αñ╣αÑêαñé αñàαñ»αÑïαñºαÑìαñ»αñ╛ αñòαÑç αñ░αñ╛αñ« αñ«αñéαñªαñ┐αñ░? αñ»αñ╣ αñ╕αñ¼ αñ¥αÑéαñá αñ¼αÑïαñ▓αñ¿αÑç αñ╡αñ╛αñ▓αÑç αñ▓αÑïαñù αñ╣αÑêαñéαÑñ\n6:05\n6 minutes, 5 seconds\nαñ░αñ╛αñ« αñ«αñéαñªαñ┐αñ░ αñòαÑç αñÜαñóαñ╝αñ╛αñ╡αÑç αñ╕αÑç αñ£αÑüαñíαñ╝αÑç αñ╣αÑüαñÅ αñàαñûαñ┐αñ▓αÑçαñ╢ αñòαÑç αñåαñ░αÑïαñ¬αÑïαñé αñ¬αñ░ αñ╕αñ┐αñ»αñ╛αñ╕αÑÇ αñÿαñ«αñ╛αñ╕αñ╛αñ¿ αñ£αñ╛αñ░αÑÇ αñ╣αÑêαÑñ\n6:09\n6 minutes, 9 seconds\nαñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñ¿αÑç αñòαñ╣αñ╛ αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñöαñ░ αñåαñ░αñÅαñ╕αñÅαñ╕ αñºαñ░αÑìαñ« αñòαÑÇ αñåαñíαñ╝ αñ«αÑçαñé αñ¢αñ┐αñ¬αñòαñ░ αñ░αñ╛αñ£αñ¿αÑÇαññαñ┐ [αñ╕αñéαñùαÑÇαññ] αñòαñ░αññαÑç αñ╣αÑêαñéαÑñ\n6:16\n6 minutes, 16 seconds\nαñåαñ░αñ£αÑçαñíαÑÇ αñòαÑç αñÅαñ╕αñ╕αÑÇ αñÅαñ╕αñƒαÑÇ αñòαÑç αñàαñºαÑìαñ»αñòαÑìαñ╖ αñ¬αñª αñ╕αÑç αñ╢αñ┐αñ╡αñÜαñéαñªαÑìαñ░ αñ░αñ╛αñ« αñòαñ╛ αñçαñ╕αÑìαññαÑÇαñ½αñ╛αÑñ αñ¬αÑìαñ░αÑçαñ╕ αñòαÑëαñ¿αÑìαñ½αÑìαñ░αÑçαñéαñ╕ αñ«αÑçαñé αñ░αÑï αñ¬αñíαñ╝αÑç αñ¬αÑéαñ░αÑìαñ╡ αñ«αñéαññαÑìαñ░αÑÇ αñöαñ░ αñåαñ░αñ£αÑçαñíαÑÇ αñòαÑç αñ¿αÑçαññαñ╛αÑñ αñÅαñ«αñÅαñ▓αñ╕αÑÇ αñëαñ«αÑìαñ«αÑÇαñªαñ╡αñ╛αñ░ αñ¿αñ╣αÑÇαñé αñ¼αñ¿αñ╛αñÅ αñ£αñ╛αñ¿αÑç αñ╕αÑç αñ¿αñ╛αñ░αñ╛αñ£ αñ╣αÑêαñéαÑñ\n6:27\n6 minutes, 27 seconds\nαñàαñ¬αñ¿αÑç αñ¼αÑçαñƒαÑç αñªαÑÇαñ¬αñò αñ¬αÑìαñ░αñòαñ╛αñ╢ αñòαÑï αñÅαñ«αñÅαñ▓αñ╕αÑÇ αñ¿αñ╣αÑÇαñé αñ¼αñ¿αñ╛αñÅ αñ£αñ╛αñ¿αÑç αñòαÑç αñ╕αñ╡αñ╛αñ▓ αñ¬αñ░ αñ¼αÑïαñ▓αÑç αñëαñ¬αÑçαñéαñªαÑìαñ░ αñòαÑüαñ╢αñ╡αñ╛αñ╣αñ╛αÑñ αñ£αñ¼ αññαñò αñòαÑç αñ▓αñ┐αñÅ αñ▓αÑïαñùαÑïαñé αñ¿αÑç αñ¼αñ¿αñ╛αñ»αñ╛ αñ«αñéαññαÑìαñ░αÑÇ αññαñ¼ αññαñò αñ░αñ╣αÑçαñéαñùαÑç αñªαÑÇαñ¬αñò αñ¬αÑìαñ░αñòαñ╛αñ╢ αñ¼αñ¿αÑç αñ░αñ╣αÑçαñéαñùαÑç αñÅαñ¿αñíαÑÇαñÅ αñòαÑç αñ╕αñ╛αñÑαÑñ\n6:40\n6 minutes, 40 seconds\nαñöαñ░ αñåαñçαñÅ αñ¿αÑìαñ»αÑéαñ£αñ╝ αñ«αÑçαñé αñàαñ¼ αñåαñ¬αñòαÑï αñªαñ┐αñûαñ╛ αñªαÑçαññαÑç αñ╣αÑêαñé αñ½αñƒαñ╛αñ½αñƒ αñªαÑçαñ╢ αñòαÑÇ αññαñ«αñ╛αñ« αñ¼αñíαñ╝αÑÇ αñûαñ¼αñ░αÑçαñéαÑñ\n6:47\n6 minutes, 47 seconds\nαñòαÑïαñÜαñ┐αñéαñù αñ╡αñ┐αñ╡αñ╛αñª αñ«αÑçαñé αñûαñ╛αñ¿ αñ╕αñ░ αñòαÑï αñòαÑïαñ░αÑìαñƒ αñ╕αÑç αñ«αñ┐αñ▓αÑÇ αñ░αñ╛αñ╣αññαÑñ αñòαÑïαñ░αÑìαñƒ αñ¿αÑç αñûαñ╛αñ¿ αñ╕αñ░ αñòαÑÇ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░αÑÇ αñ¬αñ░ αñ░αÑïαñò αñ▓αñùαñ╛ αñªαÑÇ αñ╣αÑêαÑñ 5 αñ£αÑéαñ¿ αñòαÑï αñ½αñ╛αñ»αñ░αñ┐αñéαñù αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñªαñ░αÑìαñ£ [αñ╕αñéαñùαÑÇαññ] αñ╣αÑüαñê αñÑαÑÇ αñÅαñ½αñåαñêαñåαñ░αÑñ\n6:57\n6 minutes, 57 seconds\nαñÅαñ¿αñ╕αÑÇαñ¬αÑÇ αñòαÑç 27αñ╡αÑçαñé αñ╕αÑìαñÑαñ╛αñ¬αñ¿αñ╛ αñªαñ┐αñ╡αñ╕ αñòαñ╛αñ░αÑìαñ»αñòαÑìαñ░αñ« αñ«αÑçαñé αñ¼αñªαñ▓αñ╛αñ╡ αñ╣αÑüαñå αñ╣αÑêαÑñ αñ╕αÑüαñ¿αÑÇαñ▓ αññαñƒαñòαñ░αÑÇ αñ¿αÑç αñòαñ╣αñ╛ 11 αñ£αÑéαñ¿ αñòαÑï αñ╣αÑïαñùαñ╛ αñåαñ»αÑïαñ£αñ┐αññαÑñ 10 αñ£αÑéαñ¿ αñòαÑï αñªαñ┐αñ▓αÑìαñ▓αÑÇ αñ«αÑçαñé αñ¬αÑÇαñÅαñ« αñ«αÑïαñªαÑÇ αñ¿αÑç αñ¼αÑüαñ▓αñ╛αñê αñ╣αÑê αñÅαñ¿αñíαÑÇαñÅ αñòαÑÇ αñ¼αÑêαñáαñòαÑñ\n7:08\n7 minutes, 8 seconds\nαñ«αñ╣αñ╛αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░ αñòαÑêαñ¼αñ┐αñ¿αÑçαñƒ αñòαÑÇ αñ¼αÑêαñáαñò αñåαñ£ αñ╣αÑïαñ¿αÑÇ αñ╣αÑêαÑñ\n7:10\n7 minutes, 10 seconds\nαñÅαñòαñ¿αñ╛αñÑ αñ╢αñ┐αñéαñª αñòαÑÇ αñ«αÑîαñ£αÑéαñªαñùαÑÇ αñ¬αñ░ αñ¿αñ£αñ░ αñ░αñ╣αñ¿αÑç αñ╡αñ╛αñ▓αÑÇ αñ╣αÑêαÑñ αñ¬αñ┐αñ¢αñ▓αÑÇ αñ¼αÑêαñáαñò αñ«αÑçαñé αñ¿αñ╛αñ░αñ╛αñ£αñùαÑÇ αñòαÑÇ αñ╡αñ£αñ╣ αñ╢αñ┐αñéαñª αñòαÑç αñ¿αñ╣αÑÇαñé αñ╢αñ╛αñ«αñ┐αñ▓ αñ╣αÑïαñ¿αÑç αñòαÑÇ αñûαñ¼αñ░ αñ╕αñ╛αñ«αñ¿αÑç αñåαñê αñÑαÑÇαÑñ\n7:19\n7 minutes, 19 seconds\nαñ»αñ«αÑüαñ¿αñ╛ αñ¿αñªαÑÇ αñòαÑç αñòαñ╛αñ»αñ╛αñòαñ▓αÑìαñ¬ αñòαÑç αñ▓αñ┐αñÅ αñªαñ┐αñ▓αÑìαñ▓αÑÇ αñ«αÑçαñé αñòαÑçαñéαñªαÑìαñ░αÑÇαñ» αñùαÑâαñ╣ αñ«αñéαññαÑìαñ░αÑÇ αñàαñ«αñ┐αññ αñ╢αñ╛αñ╣ αñ¿αÑç αñ¼αÑêαñáαñò αñòαÑÇαÑñ αñªαñ┐αñ▓αÑìαñ▓αÑÇ αñòαÑç αñ╕αÑÇαñÅαñ« αñöαñ░ αñ░αñ╛αñ£αÑìαñ»αñ¬αñ╛αñ▓ αñ¡αÑÇ αñ╢αñ╛αñ«αñ┐αñ▓ αñ╣αÑüαñÅαÑñ\n7:25\n7 minutes, 25 seconds\nαñòαñ╣αñ╛ αñ╕αñƒαÑÇαñò αñ¬αñ░αñ┐αñúαñ╛αñ« αñÜαñ╛αñ╣αñ┐αñÅαÑñ\n7:29\n7 minutes, 29 seconds\nαñªαñ┐αñ▓αÑìαñ▓αÑÇ αñ«αÑçαñé αñ»αñ«αÑüαñ¿αñ╛ αñÿαñ╛αñƒ αñ╕αñ½αñ╛αñê αñàαñ¡αñ┐αñ»αñ╛αñ¿αÑñ αñªαñ┐αñ▓αÑìαñ▓αÑÇ αñòαÑÇ αñ╕αÑÇαñÅαñ« αñ░αÑçαñûαñ╛ αñùαÑüαñ¬αÑìαññαñ╛ αñ¿αÑç αñòαÑÇ αñ▓αÑïαñùαÑïαñé αñ╕αÑç αñ£αÑüαñíαñ╝αñ¿αÑç αñòαÑÇ αñàαñ¬αÑÇαñ▓αÑñ αñòαñ╣αñ╛ αñòαÑüαñ¢ αñÿαñéαñƒαÑç αñªαÑçαñé αñöαñ░ αñ▓αñ╛αñÅαñé αñ¼αñªαñ▓αñ╛αñ╡αÑñ\n7:39\n7 minutes, 39 seconds\nαñåαñ£ αñ▓αÑêαñéαñí αñ¬αÑëαñƒ αñ«αÑêαñ¿αÑçαñ£αñ«αÑçαñéαñƒ αñ╕αñ┐αñ╕αÑìαñƒαñ« αñòαñ╛ αñ╢αÑüαñ¡αñ╛αñ░αñéαñ¡αÑñ\n7:41\n7 minutes, 41 seconds\nαñòαÑçαñéαñªαÑìαñ░αÑÇαñ» αñùαÑâαñ╣ αñ«αñéαññαÑìαñ░αÑÇ αñàαñ«αñ┐αññ αñ╢αñ╛αñ╣ αñòαñ░αÑçαñéαñùαÑç αñëαñªαÑìαñÿαñ╛αñƒαñ¿αÑñ αñ╕αÑÇαñ«αñ╛ αñ¬αñ╛αñ░ αñ╡αÑìαñ»αñ╛αñ¬αñ╛αñ░αÑñ αñ»αñ╛αññαÑìαñ░αñ┐αñ»αÑïαñé αñòαÑÇ αñåαñ╡αñ╛αñ£αñ╛αñ╣αÑÇ αñ╣αÑïαñùαÑÇ αñåαñ╕αñ╛αñ¿ αñöαñ░ αñ╣αÑïαñùαÑÇ αñ╕αÑüαñ░αñòαÑìαñ╖αñ┐αññ αñ¡αÑÇαÑñ\n7:51\n7 minutes, 51 seconds\nαñ£αÑïαñ£αñ┐αñ▓αñ╛ αñ╕αÑüαñ░αñéαñù αñ¬αñ░αñ┐αñ»αÑïαñ£αñ¿αñ╛ αñòαñ╛ αñåαñ£ αñàαñ╣αñ« αñ¬αñíαñ╝αñ╛αñ╡ αñ╣αÑêαÑñ αñåαñ£ αñªαÑïαñ¿αÑïαñé αññαñ░αñ½ αñ╕αÑç αñ«αñ┐αñ▓ αñ£αñ╛αñÅαñéαñùαÑÇ αñ╕αÑüαñ░αñéαñùαÑñ\n7:55\n7 minutes, 55 seconds\nαñ¿αñ┐αññαñ┐αñ¿ αñùαñíαñòαñ░αÑÇ αñ░αñ╣αÑçαñéαñùαÑç αñ«αÑîαñ£αÑéαñªαÑñ αñ╕αÑìαñÑαñ╛αñ¿αÑÇαñ» αñ▓αÑïαñùαÑïαñé αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñ╕αñ½αñ░ αñ╣αÑïαñùαñ╛ αñåαñ╕αñ╛αñ¿ αñöαñ░ αñ¼αñóαñ╝αÑçαñùαñ╛ αñ¬αñ░αÑìαñ»αñƒαñ¿αÑñ\n8:03\n8 minutes, 3 seconds\nαñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ¬αññαñ┐ αñ¡αñ╡αñ¿ αñ«αÑçαñé αñåαñ»αÑïαñ£αñ┐αññ αñ░αñòαÑìαñ╖αñ╛ αñàαñ▓αñéαñòαñ░αñú αñ╕αñ«αñ╛αñ░αÑïαñ╣αÑñ αñ╡αÑÇαñ░αÑïαñé αñòαÑï αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ¬αññαñ┐ αñ¿αÑç [αñ╕αñéαñùαÑÇαññ] αñ╡αÑÇαñ░ αñÜαñòαÑìαñ░ αñöαñ░ αñ╢αÑîαñ░αÑìαñ» αñÜαñòαÑìαñ░ αñ╕αÑç αñ¿αñ╡αñ╛αñ£αñ╛αÑñ αñ╢αñ╣αÑÇαñª αñ╕αÑêαñ¿αñ┐αñò αñòαÑÇ αñ«αñ╛αñé αñòαÑï αñ╢αñ╛αñéαññ αñ¼αñ¿αñ╛αñ¿αñ╛ αñªαÑÇαÑñ\n8:14\n8 minutes, 14 seconds\nαñªαñ┐αñ▓αÑìαñ▓αÑÇ αñ«αÑçαñé αñ¼αÑÇαñÅαñ╕αñÅαñ½ αñöαñ░ αñ¼αñ╛αñéαñùαÑìαñ▓αñ╛αñªαÑçαñ╢ αñ¼αÑëαñ░αÑìαñíαñ░ αñùαñ╛αñ░αÑìαñíαÑìαñ╕ αñòαÑÇ αñ¼αÑêαñáαñòαÑñ αñíαÑÇαñ£αÑÇ αñ╕αÑìαññαñ░ αñòαÑÇ αñ¼αñ╛αññαñÜαÑÇαññ αñòαÑç αñ¬αñ╣αñ▓αÑç αñªαñ┐αñ¿ αñ¡αñ╛αñ░αññ αñ¿αÑç αñëαñáαñ╛αñ»αñ╛ αñùαÑêαñ░ αñòαñ╛αñ¿αñ╛αñ¿αÑéαñ¿αÑÇ αñÿαÑüαñ╕αñ¬αÑêαñá αñöαñ░ αñ¼αÑÇαñÅαñ╕αñÅαñ½ αñ£αñ╡αñ╛αñ¿αÑïαñé αñ¬αñ░ αñ╣αñ«αñ▓αÑç αñòαñ╛ αñ¡αÑÇ αñ«αÑüαñªαÑìαñªαñ╛αÑñ\n8:26\n8 minutes, 26 seconds\n10 αñ╕αñ╛αñ▓ αñòαÑç αñçαñéαññαñ£αñ╛αñ░ αñòαÑç αñ¼αñ╛αñª αñ¼αñ¿αñ╛ αñ«αÑüαñéαñ¼αñê αñ«αÑçαñé αñ½αÑìαñ▓αñ╛αñê αñôαñ╡αñ░αÑñ αñùαÑüαñúαñ╡αññαÑìαññαñ╛ αñöαñ░ αñ½αñ┐αñ¿αñ┐αñ╢αñ┐αñéαñù αñ¬αñ░ αñëαñá αñ░αñ╣αÑç αñ╕αñ╡αñ╛αñ▓αÑñ αñ¼αÑÇαñÅαñÅαñ«αñ╕αÑÇ αñ¼αÑïαñ▓αÑÇ αñ½αÑìαñ▓αñ╛αñê αñôαñ╡αñ░ αñòαÑÇ αñùαÑüαñúαñ╡αññαÑìαññαñ╛ αñ╕αÑç αñ╕αñ«αñ¥αÑîαññαñ╛ αñ¿αñ╣αÑÇαñé αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛αÑñ\n8:37\n8 minutes, 37 seconds\nαñ░αñ╛αñ»αñ¬αÑüαñ░ αñ«αÑçαñé αñòαñéαñùαñ¿αñ╛ αñ░αñ¿αÑîαññ αñòαÑÇ αñ½αñ┐αñ▓αÑìαñ« αñ¡αñ╛αñ░αññ αñ¡αñ╛αñùαÑìαñ» αñ╡αñ┐αñºαñ╛αññαñ╛ αñòαÑÇ αñ¬αÑìαñ░αÑÇαñ▓αÑëαñ¿αÑìαñÜαÑì αñ╕αÑìαñòαÑìαñ░αÑÇαñ¿αñ┐αñéαñùαÑñ\n8:41\n8 minutes, 41 seconds\nαñ«αÑüαñûαÑìαñ»αñ«αñéαññαÑìαñ░αÑÇ αñ╡αñ┐αñ╖αÑìαñúαÑüαñªαÑçαñ╡ αñ╕αñ╛αñ» αñ¿αÑç αñ¬αñ░αñ┐αñ╡αñ╛αñ░ αñöαñ░ αñ«αñéαññαÑìαñ░αñ┐αñ«αñéαñíαñ▓ αñòαÑç αñ╕αñ╛αñÑ αñ½αñ┐αñ▓αÑìαñ« αñòαÑï αñªαÑçαñûαñ╛αÑñ αñ½αñ┐αñ▓αÑìαñ« αñ«αÑçαñé αñ▓αÑÇαñí αñ░αÑïαñ▓ αñ«αÑçαñé αñ╣αÑê αñòαñéαñùαñ¿αñ╛ αñ░αñ¿αÑîαññαÑñ\n8:50\n8 minutes, 50 seconds\nαñöαñ░ αñåαñçαñÅ αñàαñ¼ αñ¿αÑî αñ╕αÑç αñ¿αÑìαñ»αÑéαñ£αñ╝ αñ«αÑçαñé αñåαñ¬αñòαÑï αñªαñ┐αñûαñ╛ αñªαÑçαññαÑç αñ╣αÑêαñé αñªαÑçαñ╢ αñòαÑç αñàαñ▓αñù-αñàαñ▓αñù αñ░αñ╛αñ£αÑìαñ»αÑïαñé αñòαÑÇ αñ¼αñíαñ╝αÑÇ αñûαñ¼αñ░αÑçαñé αñ½αñƒαñ╛αñ½αñƒαÑñ\n8:59\n8 minutes, 59 seconds\nαñ╡αñ┐αñ╢αñ╛αñûαñ╛αñ¬αñƒαñ¿αñ« αñ╕αÑìαñƒαÑÇαñ▓ αñ¬αÑìαñ▓αñ╛αñéαñƒ αñ«αÑçαñé αñ╣αÑüαñå αñ¼αñíαñ╝αñ╛ αñ╣αñ╛αñªαñ╕αñ╛αÑñ αñ¬αñ┐αñÿαñ▓αñ╛ αñ╣αÑüαñå αñ╕αÑìαñƒαÑÇαñ▓ αñùαñ┐αñ░αñ¿αÑç αñ╕αÑç αñåαñá αñ«αñ£αñªαÑéαñ░αÑïαñé αñòαÑÇ αñ«αÑîαññ αñ╣αÑï αñùαñêαÑñ αñòαñ░αÑìαñ£αÑÇ αñ«αñ£αñªαÑéαñ░αÑïαñé αñòαÑç αñ¥αÑüαñ▓αñ╕αñ¿αÑç αñòαÑÇ αñ£αñ╛αñ¿αñòαñ╛αñ░αÑÇαÑñ αñ╣αñ╛αñªαñ╕αÑç αñòαÑÇ αñ╡αñ£αñ╣ αñ╕αÑç αñ¬αÑìαñ▓αñ╛αñéαñƒ αñ«αÑçαñé αñàαñ½αñ░αñ╛αññαñ½αñ░αÑÇ αñ«αñÜ αñùαñêαÑñ\n9:12\n9 minutes, 12 seconds\nαñ«αñ╣αñ╛αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░ αñòαÑç αñ¿αñ╛αñùαñ¬αÑüαñ░ αñ«αÑçαñé αñ«αÑïαñƒαñ░ αñòαñéαñ¬αñ¿αÑÇ αñòαÑç αñ╢αÑïαñ░αÑéαñ« αñ«αÑçαñé αñ¡αÑÇαñ╖αñú αñåαñù αñ▓αñùαÑÇαÑñ αñòαñê αñƒαÑé αñ╡αÑìαñ╣αÑÇαñ▓αñ░ αñ£αñ▓αñòαñ░ αñûαñ╛αñò αñ╣αÑï αñùαñêαÑñ 3 αñÿαñéαñƒαÑç αñ«αÑçαñé αñåαñù αñ¬αñ░ αñòαñ╛αñ¼αÑé αñ¬αñ╛αñ»αñ╛ αñ£αñ╛ αñ╕αñòαñ╛αÑñ\n9:21\n9 minutes, 21 seconds\nαñëαññαÑìαññαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñ╕αÑïαñ¿αñ¡αñªαÑìαñ░ αñ«αÑçαñé αñ¼αñ╛αñçαñò αñ«αÑçαñé αñ▓αñùαÑÇ αñåαñùαÑñ αñªαÑçαñûαññαÑç αñ╣αÑÇ αñªαÑçαñûαññαÑç αñ¬αÑéαñ░αÑÇ αñ¼αñ╛αñçαñò αñ£αñ▓αñòαñ░ αñûαñ╛αñòαÑñ αñ╢αÑëαñ░αÑìαñƒ αñ╕αñ░αÑìαñòαñ┐αñƒ αñòαÑÇ αñ╡αñ£αñ╣ αñ╕αÑç αñåαñù αñ▓αñùαñ¿αÑç αñòαÑÇ αñåαñ╢αñéαñòαñ╛αÑñ\n9:30\n9 minutes, 30 seconds\nαñ¼αñ┐αñ╣αñ╛αñ░ αñòαÑç αñ¼αÑçαñùαÑéαñ╕αñ░αñ╛αñ» αñòαÑç αñ╕αñªαñ░ αñàαñ╕αÑìαñ¬αññαñ╛αñ▓ αñ«αÑçαñé αñåαñù αñ¬αñ░ αñòαñ╛αñ¼αÑé αñ¬αñ╛ αñ▓αñ┐αñ»αñ╛ αñùαñ»αñ╛ αñ╣αÑêαÑñ αñÜαñ┐αñ▓αÑìαñíαÑìαñ░αñ¿ αñ╡αñ╛αñ░αÑìαñí αñ«αÑçαñé αñ▓αñùαÑÇ αñÑαÑÇ αñ»αñ╣αñ╛αñé αñ¬αñ░ αñåαñùαÑñ αñ╢αÑëαñ░αÑìαñƒ αñ╕αñ░αÑìαñòαñ┐αñƒ αñ╕αÑç αñåαñù αñ▓αñùαñ¿αÑç αñòαÑÇ αñåαñ╢αñéαñòαñ╛αÑñ αñ╕αñ¡αÑÇ αñ«αñ░αÑÇαñ£ αñòαñ░αÑìαñ«αñÜαñ╛αñ░αÑÇ αñàαñ╕αÑìαñ¬αññαñ╛αñ▓ αñòαÑç αñ╕αñ¡αÑÇ αñ╕αÑüαñ░αñòαÑìαñ╖αñ┐αññ αñ╣αÑêαñéαÑñ\n9:42\n9 minutes, 42 seconds\nαñòαÑüαñ░αÑüαñòαÑìαñ╖αÑçαññαÑìαñ░ αñ«αÑçαñé αñ¬αñƒαñ░αÑÇ αñ╕αÑç αñëαññαñ░αÑÇ αñ«αñ╛αñ▓αñùαñ╛αñíαñ╝αÑÇ αñòαÑç αññαÑÇαñ¿ αñíαñ┐αñ¼αÑìαñ¼αÑçαÑñ αñòαÑüαñ░αÑüαñòαÑìαñ╖αÑçαññαÑìαñ░ αñòαÑç αñ¬αñ┐αñ╣αÑïαñ╡αñ╛ αñ░αÑïαñí αñ╕αÑìαñƒαÑçαñ╢αñ¿ αñòαÑç αñ¼αÑÇαñÜ αñ╣αñ╛αñªαñ╕αñ╛ αñ╣αÑüαñå αñ╣αÑêαÑñ αñòαñ╛αñ½αÑÇ αñªαÑçαñ░ αññαñò αñ¼αñ╛αñºαñ┐αññ αñ░αñ╣αñ╛ αñ░αÑçαñ▓ αñ»αñ╛αññαñ╛αñ»αñ╛αññαÑñ\n9:54\n9 minutes, 54 seconds\nαñ╣αñ░αñªαÑïαñê αñ«αÑçαñé αñ¬αÑìαñ░αÑçαñ«αÑÇ αñòαÑÇ αñ╢αñ╛αñªαÑÇ αññαñ» αñ╣αÑïαñ¿αÑç αñ╕αÑç αñ¿αñ╛αñ░αñ╛αñ£ αñ»αÑüαñ╡αññαÑÇ αñ«αÑïαñ¼αñ╛αñçαñ▓ αñƒαñ╛αñ╡αñ░ αñ¬αñ░ αñÜαñóαñ╝ αñùαñêαÑñ αñ╕αÑéαñÜαñ¿αñ╛ αñ¬αñ░ αñ¬αñ╣αÑüαñéαñÜαÑÇ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñÿαñéαñƒαÑïαñé αñòαÑÇ αñ«αñ╢αñòαÑìαñòαññ αñòαÑç αñ¼αñ╛αñª αñ»αÑüαñ╡αññαÑÇ αñòαÑï αñ╕αÑüαñ░αñòαÑìαñ╖αñ┐αññ αñ¿αÑÇαñÜαÑç αñëαññαñ╛αñ░αñ╛αÑñ\n10:04\n10 minutes, 4 seconds\nαñªαñ┐αñ▓αÑìαñ▓αÑÇ αñòαÑç αñ╡αñ┐αñòαñ╛αñ╕αñ¬αÑüαñ░αÑÇ αñ«αÑçαñé αñàαññαñ┐αñòαÑìαñ░αñ«αñú αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñòαñ╛αñ░αñ╡αñ╛αñê αñòαÑÇ αñùαñêαÑñ αñ¬αÑÇαñíαñ¼αÑìαñ▓αÑìαñ»αÑéαñíαÑÇ αñ¿αÑç αñªαÑüαñòαñ╛αñ¿αÑïαñé αñòαÑç αñ¼αñ╛αñ╣αñ░ αñ¼αñ¿αÑç αñ░αÑêαñéαñ¬ αñöαñ░ αñ╕αÑÇαñóαñ╝αñ┐αñ»αÑïαñé αñ¬αñ░ αñÜαñ▓αñ╛αñ»αñ╛ αñ¼αÑüαñ▓αñíαÑïαñ£αñ░αÑñ αñ╕αñ░αñòαñ╛αñ░αÑÇ αñ£αñ«αÑÇαñ¿ αñ╕αÑç αñ╣αñƒαñ╛αñ»αñ╛ αñùαñ»αñ╛ αñàαñ╡αÑêαñº αñòαñ¼αÑìαñ£αñ╛αÑñ\n10:16\n10 minutes, 16 seconds\nαñ«αñºαÑìαñ» αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñ¿αñ░αñ╕αñ┐αñéαñ╣αñ¬αÑüαñ░ αñ«αÑçαñé αñ╕αñ░αñòαñ╛αñ░αÑÇ αñ£αñ«αÑÇαñ¿ αñ╕αÑç αñòαñ¼αÑìαñ£αñ╛ αñ╣αñƒαñ╛αñ¿αÑç αñòαñ╛ αñ╡αñ┐αñ░αÑïαñº αñ╣αÑüαñåαÑñ αñùαÑìαñ░αñ╛αñ«αÑÇαñúαÑïαñé αñ¿αÑç αñòαñ┐αñ»αñ╛ αñ¼αÑüαñ▓αñíαÑïαñ£αñ░αÑñ αñòαñ╛αñ░αñ╡αñ╛αñ╣αÑÇ αñòαñ╛ αñ╡αñ┐αñ░αÑïαñºαÑñ\n10:22\n10 minutes, 22 seconds\nαñ£αÑçαñ╕αÑÇαñ¼αÑÇ αñòαÑç αñ╕αñ╛αñ«αñ¿αÑç αñûαñíαñ╝αÑç αñ╣αÑï αñùαñÅ αñ▓αÑïαñùαÑñ αñ╣αñéαñùαñ╛αñ«αÑÇ αñòαÑç αñÜαñ▓αññαÑç αñ¬αÑìαñ░αñ╢αñ╛αñ╕αñ¿ αñòαÑï αñ░αÑïαñòαñ¿αÑÇ αñ¬αñíαñ╝αÑÇ αñòαñ╛αñ░αñ╡αñ╛αñêαÑñ\n10:28\n10 minutes, 28 seconds\nαñëαññαÑìαññαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñ╕αñéαñ¡αñ▓ αñ«αÑçαñé αñºαñ╕αÑìαññαÑÇαñòαñ░αñú αñòαÑÇ αñòαñ╛αñ░αñ╡αñ╛αñ╣αÑÇ αñòαÑç αñ¼αñ╛αñª αñ«αñ▓αñ¼αñ╛ αñ╣αñƒαñ╛αñ¿αÑç αñòαñ╛ αñòαñ╛αñ« αñ£αñ╛αñ░αÑÇ αñ╣αÑêαÑñ αñ¼αÑüαñ▓αñíαÑïαñ£αñ░ αñòαÑÇ αñ«αñªαñª αñ╕αÑç αñ╣αñƒαñ╛αñ»αñ╛ αñ£αñ╛ αñ░αñ╣αñ╛ αñ╕αñíαñ╝αñò αñòαÑç αñåαñ╕αñ¬αñ╛αñ╕ αñòαÑç αñçαñ▓αñ╛αñòαÑïαñé αñ╕αÑç αñ«αñ▓αñ¼αñ╛αÑñ αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñòαÑç αñ«αñªαÑìαñªαÑçαñ¿αñ£αñ░ αñ¬αÑÇαñÅαñ╕αÑÇ αññαÑêαñ¿αñ╛αññαÑñ\n10:40\n10 minutes, 40 seconds\nαñ«αñºαÑìαñ» αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñ╕αÑÇαñ╣αÑïαñ░ αñ«αÑçαñé αñ╕αñéαñ╡αñ┐αñªαñ╛ αñ¬αñ░ αñòαñ╛αñ« αñòαñ░ αñ╕αÑìαñ╡αñ╛αñ╕αÑìαñÑαÑìαñ» αñòαñ░αÑìαñ«αñ┐αñ»αÑïαñé αñòαñ╛ αñ¬αÑìαñ░αñªαñ░αÑìαñ╢αñ¿αÑñ αñ¡αÑêαñéαñ╕ αñòαÑç αñåαñùαÑç αñ¼αÑÇαñ¿ αñ¼αñÜαñ╛αñòαñ░ αñ╡αñ┐αñ░αÑïαñº αñ╡αÑìαñ»αñòαÑìαññ αñòαñ┐αñ»αñ╛αÑñ αñàαñ¬αñ¿αÑÇ\n10:47\n10 minutes, 47 seconds\nαñ«αñ╛αñéαñùαÑïαñé αñòαÑï αñ▓αÑçαñòαñ░ αñòαñê αñªαñ┐αñ¿αÑïαñé αñ╕αÑç αñºαñ░αñ¿αñ╛ αñªαÑç αñ░αñ╣αÑç αñòαñ░αÑìαñ«αñÜαñ╛αñ░αÑÇαÑñ\n10:54\n10 minutes, 54 seconds\nαñ░αñ╛αñ£αñ╕αÑìαñÑαñ╛αñ¿ αñòαÑç αñíαÑÇαñíαñ╡αñ╛αñ¿αñ╛ αñ«αÑçαñé αñåαñ░αñÅαñ▓αñ¬αÑÇ αñòαñ╛ αñ╣αñ▓αÑìαñ▓αñ╛ αñ¼αÑïαñ▓ αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αÑÇαñ» αñ▓αÑïαñòαññαñ╛αñéαññαÑìαñ░αñ┐αñò αñ¬αñ╛αñ░αÑìαñƒαÑÇ αñòαÑç αñ╕αÑüαñ¬αÑìαñ░αÑÇαñ«αÑï αñ╣αñ¿αÑüαñ«αñ╛αñ¿ αñ¼αÑçαñ¿αÑÇαñ╡αñ╛αñ▓ αñòαÑÇ αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñ╣αñƒαñ╛αñ¿αÑç αñòαñ╛ αñ╡αñ┐αñ░αÑïαñº αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛ αñöαñ░ αñ¬αÑìαñ░αñªαñ░αÑìαñ╢αñ¿ αñòαñ┐αñ»αñ╛αÑñ\n11:06\n11 minutes, 6 seconds\nαñùαÑìαñ░αÑçαñƒαñ░ αñ¿αÑïαñÅαñíαñ╛ αñ«αÑçαñé αñûαñ╛αñ¿αñ╛ αñûαñ╛αñ¿αÑç αñòαÑç αñ¼αñ╛αñª αñ¼αñ┐αñùαñíαñ╝αÑÇ αñÅαñò αñ╣αÑÇ αñ¬αñ░αñ┐αñ╡αñ╛αñ░ αñòαÑç αññαÑÇαñ¿ αñ▓αÑïαñùαÑïαñé αñòαÑÇ αññαñ¼αÑÇαñ»αññαÑñ αñçαñ▓αñ╛αñ£ αñòαÑç αñªαÑîαñ░αñ╛αñ¿ αñªαÑï αñ¼αñÜαÑìαñÜαÑïαñé αñòαÑÇ αñ«αÑîαññ αñ╣αÑï αñùαñêαÑñ αñ«αñ╣αñ┐αñ▓αñ╛ αñòαÑÇ αñ╕αÑìαñÑαñ┐αññαñ┐ αñùαñéαñ¡αÑÇαñ░ αñ╣αÑêαÑñ αñ£αñ╛αñéαñÜ αñòαñ░ αñ░αñ╣αÑÇ αñ╣αÑê αñ¬αÑüαñ▓αñ┐αñ╕αÑñ\n11:18\n11 minutes, 18 seconds\nαñ«αÑüαñ░αñ╛αñªαñ╛αñ¼αñ╛αñª αñ«αÑçαñé αñæαñòαÑìαñ╕αÑÇαñ£αñ¿ αñ╕αñ┐αñ▓αÑçαñéαñíαñ░ αñûαÑïαñ▓αñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ αñ╣αñÑαÑîαñíαñ╝αÑç αñòαñ╛ αñçαñ╕αÑìαññαÑçαñ«αñ╛αñ▓ αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛αÑñ\n11:21\n11 minutes, 21 seconds\nαñÅαñéαñ¼αÑüαñ▓αÑçαñéαñ╕ αñ«αÑçαñé αñ«αñ░αÑÇαñ£ αñòαÑï αñæαñòαÑìαñ╕αÑÇαñ£αñ¿ αñ▓αñùαñ╛αñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ αñ╣αñÑαÑîαñíαñ╝αÑç αñ╕αÑç αñûαÑïαñ▓αñ¿αñ╛ αñ¬αñíαñ╝ αñùαñ»αñ╛ αñ╕αñ┐αñ▓αÑçαñéαñíαñ░αÑñ αñëαñ£αñ╛αñùαñ░ αñ╣αÑüαñê αñ╕αÑìαñ╡αñ╛αñ╕αÑìαñÑαÑìαñ» αñ╡αñ┐αñ¡αñ╛αñù αñòαÑÇ αñ▓αñ╛αñ¬αñ░αñ╡αñ╛αñ╣αÑÇαÑñ\n11:30\n11 minutes, 30 seconds\nαñ¡αñ╛αñ░αññαÑÇαñ» αñ¿αÑîαñ╕αÑçαñ¿αñ╛ αñ¿αÑç αñ░αñ╛αñ«αÑçαñ╢αÑìαñ╡αñ░αñ« αñ«αÑçαñé αñòαñ┐αñ»αñ╛ αññαñƒαÑÇαñ» αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñòαÑï αñ▓αÑçαñòαñ░ αñ╕αÑêαñ¿αÑìαñ» αñàαñ¡αÑìαñ»αñ╛αñ╕αÑñ αñ¿αÑîαñ╕αÑçαñ¿αñ╛ αñ¿αÑç αñòαÑç αñ╣αÑçαñ▓αÑÇαñòαÑëαñ¬αÑìαñƒαñ░αÑìαñ╕ αñ¿αÑç αññαñƒαÑÇαñ» αñçαñ▓αñ╛αñòαÑïαñé αñ«αÑçαñé αñòαñ« αñèαñéαñÜαñ╛αñê αñ¬αñ░ αñëαñíαñ╝αñ╛αñ¿ αñ¡αñ░αÑÇαÑñ\n11:42\n11 minutes, 42 seconds\nαñ╣αÑêαñªαñ░αñ╛αñ¼αñ╛αñª αñ╕αñÜαñ┐αñ╡αñ╛αñ▓αñ» αñòαÑç αñ¬αñ╛αñ╕ αñ«αÑêαñ¿ αñ╣αÑïαñ▓ αñ«αÑçαñé αñ½αñéαñ╕αñ╛ αñ¼αñÜαÑìαñÜαÑç αñòαñ╛ αñ¬αÑêαñ░αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñöαñ░ αñ½αñ╛αñ»αñ░ αñ╕αñ░αÑìαñ╡αñ┐αñ╕ αñ¿αÑç αñòαñ╛αñ½αÑÇ αñ«αñ╢αñòαÑìαñòαññ αñòαÑç αñ¼αñ╛αñª αñ¼αñÜαÑìαñÜαÑç αñòαÑï αñ╕αÑüαñ░αñòαÑìαñ╖αñ┐αññ αñ¿αñ┐αñòαñ╛αñ▓αñ╛αÑñ\n11:53\n11 minutes, 53 seconds\nαñùαÑìαñ░αÑçαñƒαñ░ αñ¿αÑïαñÅαñíαñ╛ αñòαÑç αñòαñê αñçαñ▓αñ╛αñòαÑïαñé αñ«αÑçαñé αñåαñ╡αñ╛αñ░αñ╛ αñòαÑüαññαÑìαññαÑïαñé αñòαñ╛ αñåαññαñéαñò αñ¼αñ░αñòαñ░αñ╛αñ░αÑñ αñòαÑüαññαÑìαññαÑïαñé αñòαÑç αñ¥αÑüαñéαñí αñ¿αÑç αñ¼αñÜαÑìαñÜαÑÇ αñ¬αñ░ αñòαñ┐αñ»αñ╛ αñ╣αñ«αñ▓αñ╛αÑñ αñ¼αñÜαÑìαñÜαÑÇ αñòαÑï αñòαñ╛αñƒαñòαñ░ αñÿαñ╛αñ»αñ▓ αñòαñ┐αñ»αñ╛αÑñ αñÿαñƒαñ¿αñ╛ αñ╣αÑüαñê αñ╡αñ╣αñ╛αñé αñ▓αñùαÑç αñ╕αÑÇαñ╕αÑÇαñƒαÑÇαñ╡αÑÇ αñòαÑêαñ«αñ░αÑç αñ«αÑçαñé αñ░αñ┐αñ¬αÑïαñ░αÑìαñƒαÑñ\n12:06\n12 minutes, 6 seconds\nαñ╣αñ░αñ┐αñªαÑìαñ╡αñ╛αñ░ αñòαÑç αñ╕αñ░αñ╛αñ» αñçαñ▓αñ╛αñòαÑç αñ«αÑçαñé αñÅαñò αñÿαñ░ αñòαÑç αñàαñéαñªαñ░ αñ░αÑçαñéαñù αñ╕αÑç αñ«αñ┐αñ▓αÑç 27 αñ╕αñ╛αñéαñ¬αÑñ αñƒαñéαñòαÑÇ αñòαÑç αñàαñéαñªαñ░ 27 αñ╕αñ╛αñéαñ¬ αñòαÑç αñ╕αñ¬αÑïαñ▓αÑç αñªαÑçαñûαñòαñ░ αñ╣αÑêαñ░αñ╛αñ¿ αñ░αñ╣ αñùαñÅ αñ▓αÑïαñùαÑñ αñ╡αñ¿\n12:15\n12 minutes, 15 seconds\nαñ╡αñ┐αñ¡αñ╛αñù αñ¿αÑç αñ╕αñ¡αÑÇ αñòαÑï αñòαñ¼αÑìαñ£αÑç αñ«αÑçαñé αñ▓αÑçαñòαñ░ αñ£αñéαñùαñ▓ αñ«αÑçαñé αñ¢αÑïαñíαñ╝ αñªαñ┐αñ»αñ╛ αñ╣αÑêαÑñ\n12:20\n12 minutes, 20 seconds\nαñªαñ┐αñ▓αÑìαñ▓αÑÇ αñÅαñ¿αñ╕αÑÇαñåαñ░ αñ«αÑçαñé αñàαñùαñ▓αÑç 3 αñªαñ┐αñ¿ αññαñò αñ£αñ╛αñ░αÑÇ αñ░αñ╣ αñ╕αñòαññαÑÇ αñ╣αÑê αñ╣αÑÇαñƒ αñ╡αÑçαñ╡αÑñ αññαñ╛αñ¬αñ«αñ╛αñ¿ 42 αñ╕αÑç 44 αñíαñ┐αñùαÑìαñ░αÑÇ αñòαÑç αñ¼αÑÇαñÜ αñ░αñ╣αñ¿αÑç αñòαñ╛ αñàαñ¿αÑüαñ«αñ╛αñ¿ αñ╣αÑêαÑñ 11 αñ£αÑéαñ¿ αñòαÑç αñ¼αñ╛αñª αñùαñ░αÑìαñ«αÑÇ αñ╕αÑç αñòαÑüαñ¢ αñ░αñ╛αñ╣αññ αñ«αñ┐αñ▓ αñ╕αñòαññαÑÇ αñ╣αÑêαÑñ\n12:34\n12 minutes, 34 seconds\nαñàαñùαñ▓αÑç αñ╕αñ╛αññ αñªαñ┐αñ¿αÑïαñé αñòαÑç αñªαÑîαñ░αñ╛αñ¿ αñòαÑçαñ░αñ▓, αñòαñ░αÑìαñ¿αñ╛αñƒαñò, αññαñ«αñ┐αñ▓αñ¿αñ╛αñíαÑü αñöαñ░ αñëαññαÑìαññαñ░αñ¬αÑéαñ░αÑìαñ╡αÑÇ αñ¡αñ╛αñ░αññ αñ«αÑçαñé αñòαÑüαñ¢ αñ£αñùαñ╣αÑïαñé αñ¬αñ░ αñ¼αñ╣αÑüαññ αñ¡αñ╛αñ░αÑÇ αñ¼αñ╛αñ░αñ┐αñ╢ αñòαñ╛ αñàαñ▓αñ░αÑìαñƒ αñ£αñ╛αñ░αÑÇ αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛ αñ╣αÑêαÑñ αñåαñ£ αñòαñ░αÑìαñ¿αñ╛αñƒαñò αñöαñ░ αñòαÑçαñ░αñ▓ αñ«αÑçαñé αñ╣αÑï αñ╕αñòαññαÑÇ [αñ╕αñéαñùαÑÇαññ] αñ╣αÑê αñ¡αñ╛αñ░αÑÇ αñ¼αñ╛αñ░αñ┐αñ╢αÑñ\n12:46\n12 minutes, 46 seconds\nαñöαñ░ αñåαñçαñÅ αñàαñ¼ αñ¿αÑî αñ╕αÑç αñ¿αÑìαñ»αÑéαñ£αñ╝ αñ«αÑçαñé αñåαñ¬αñòαÑï αñªαñ┐αñûαñ╛ αñªαÑçαññαÑç αñ╣αÑêαñé αñàαñ¬αñ░αñ╛αñº αñ£αñùαññ αñòαÑÇ αñ¼αñíαñ╝αÑÇ αñûαñ¼αñ░αÑçαñé αñ½αñƒαñ╛αñ½αñƒ αñàαñéαñªαñ╛αñ£ αñ«αÑçαñéαÑñ\n12:54\n12 minutes, 54 seconds\nαñëαññαÑìαññαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñ╣αñ╛αñ¬αÑüαñíαñ╝ αñ«αÑçαñé αñ¿αñ╡αñ╡αñ┐αñ╡αñ╛αñ╣αñ┐αññ αñòαÑÇ αñ╕αñéαñªαñ┐αñùαÑìαñº αñ╣αñ╛αñ▓αññ αñ«αÑçαñé αñ«αÑîαññ αñ╣αÑï αñùαñêαÑñ αñ«αñ╣αÑÇαñ¿αÑç αñ¡αñ░ αñ¬αñ╣αñ▓αÑç αñ╣αÑÇ αñ╢αñ╛αñªαÑÇ αñ╣αÑüαñê αñÑαÑÇαÑñ αñ«αñ╛αñ»αñòαÑç αñ╡αñ╛αñ▓αÑç αñ¿αÑç αñ£αññαñ╛αñ»αñ╛ αñ╣αññαÑìαñ»αñ╛ αñòαñ╛ αñ╢αñòαÑñ αñ«αñ╛αñ«αñ▓αÑç αñòαÑÇ αñ¢αñ╛αñ¿αñ¼αÑÇαñ¿ αñ«αÑçαñé αñ£αÑüαñƒαÑÇ αñ╣αÑê αñ¬αÑüαñ▓αñ┐αñ╕αÑñ\n13:04\n13 minutes, 4 seconds\nαñ▓αñûαñ¿αñè αñòαÑç αñ¬αñ╛αñ░αñ╛ αñçαñ▓αñ╛αñòαÑç αñ«αÑçαñé αñ«αñ╣αñ┐αñ▓αñ╛ αñàαñ¡αÑìαñ»αñ░αÑìαñÑαñ┐αñ»αÑïαñé αñòαÑç αñ╕αñ╛αñÑ αñ¢αÑçαñíαñ╝αñûαñ╛αñ¿αÑÇ αñòαñ╛ αñ«αñ╛αñ«αñ▓αñ╛αÑñ αñåαñ░αÑïαñ¬αÑÇ αñæαñƒαÑï αñÜαñ╛αñ▓αñò αñ¬αÑüαñ▓αñ┐αñ╕ αñòαÑç αñ╕αñ╛αñÑ αñ╣αÑüαñê αñ«αÑüαñáαñ¡αÑçαñíαñ╝ αñ«αÑçαñé αñÿαñ╛αñ»αñ▓ αñ╣αÑüαñåαÑñ\n13:11\n13 minutes, 11 seconds\nαñ¬αñ╣αñ▓αÑç αñ¡αÑÇ αñ░αÑçαñ¬ αñòαÑç αñåαñ░αÑïαñ¬ αñ«αÑçαñé αñ£αÑçαñ▓ αñ£αñ╛ αñÜαÑüαñòαñ╛ αñ╣αÑê αñåαñ░αÑïαñ¬αÑÇαÑñ\n13:17\n13 minutes, 17 seconds\nαñ«αÑüαñéαñ¼αñê αñ«αÑçαñé 19 αñ╕αñ╛αñ▓ αñ╕αÑç αñ½αñ░αñ╛αñ░ αñåαñ░αÑïαñ¬αÑÇ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛ αñ╣αÑêαÑñ αñÜαÑïαñ░αÑÇ αñòαÑç αñòαÑçαñ╕ αñ«αÑçαñé αñ¼αñ╛αñ░-αñ¼αñ╛αñ░ αñòαÑïαñ░αÑìαñƒ αñ╕αÑç αñ╣αÑï αñ░αñ╣αÑÇ αñÑαÑÇ αñùαÑêαñ░ αñ╣αñ╛αñ£αñ┐αñ░ αñ╣αÑï αñ░αñ╣αñ╛ αñÑαñ╛ αñùαÑêαñ░ αñ╣αñ╛αñ£αñ┐αñ░αÑñ αñòαÑïαñ░αÑìαñƒ αñ¿αÑç αñ£αñ╛αñ░αÑÇ αñòαñ┐αñ»αñ╛ αñÑαñ╛ αñ¿αÑïαñƒαñ┐αñ╕αÑñ\n13:29\n13 minutes, 29 seconds\nαñëαññαÑìαññαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñ╣αñ╛αñÑαñ░αñ╕ αñòαÑç αñÑαñ╛αñ¿αñ╛ αñ╕αñ╣αñ¬αñè αñòαÑìαñ╖αÑçαññαÑìαñ░ αñ«αÑçαñé αñ╕αñ╛αñºαÑü αñòαÑÇ αñ╣αññαÑìαñ»αñ╛αÑñ αñ«αñéαñªαñ┐αñ░ αñ¬αñ░αñ┐αñ╕αñ░ αñ«αÑçαñé αñûαÑéαñ¿ αñ╕αÑç αñ▓αñÑαñ¬αñÑ αñ«αñ┐αñ▓αñ╛ αñ╢αñ╡αÑñ αñ¬αñ┐αñ¢αñ▓αÑç αñòαñ╛αñ½αÑÇ αñ╕αñ«αñ»\n13:36\n13 minutes, 36 seconds\nαñ╕αÑç [αñ╕αñéαñùαÑÇαññ] αñ«αñéαñªαñ┐αñ░ αñ«αÑçαñé αñ¬αÑéαñ£αñ╛ αñ¬αñ╛αñá αñòαñ╛ αñòαñ╛αñ« αñòαñ░αññαÑç αñÑαÑç αñªαñ┐αñ▓αÑÇαñ¬αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñªαñ░αÑìαñ£ αñòαñ┐αñ»αñ╛ αñ«αñ╛αñ«αñ▓αñ╛αÑñ\n13:42\n13 minutes, 42 seconds\nαñ«αñºαÑìαñ» αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñùαÑìαñ╡αñ╛αñ▓αñ┐αñ»αñ░ αñ«αÑçαñé αñÅαñò αñÿαñ░ αñ«αÑçαñé αñ╣αÑüαñê αñÜαÑïαñ░αÑÇ αñ«αÑçαñé αñûαÑüαñ▓αñ╛αñ╕αñ╛ αñ╣αÑüαñå αñ╣αÑêαÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ¬αñíαñ╝αÑïαñ╕αÑÇ αñ«αñ╣αñ┐αñ▓αñ╛ αñòαÑï αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñÜαÑïαñ░αÑÇ αñòαñ╛ αñ«αñ╛αñ▓ αñ¼αñ░αñ╛αñ«αñª αñòαñ┐αñ»αñ╛αÑñ\n13:51\n13 minutes, 51 seconds\nαñ»αÑéαñ¬αÑÇ αñòαÑç αñòαÑîαñ╢αñ╛αñéαñ¼αÑÇ αñ«αÑçαñé αñ£αñéαñùαñ▓ αñ«αÑçαñé αñ«αñ┐αñ▓αÑÇ αñ¼αñ┐αñ£αñ▓αÑÇ αñòαñ░αÑìαñ«αñÜαñ╛αñ░αÑÇ αñòαÑÇ αñ╕αñ░ αñòαñƒαÑÇ αñ▓αñ╛αñ╢αÑñ αñÿαñ░ αñ╕αÑç αñíαÑìαñ»αÑéαñƒαÑÇ αñòαÑç αñ▓αñ┐αñÅ αñ¿αñ┐αñòαñ▓αñ╛ αñÑαñ╛ αñ»αÑüαñ╡αñòαÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ╢αñ╡ αñòαÑï αñòαñ¼αÑìαñ£αÑç αñ«αÑçαñé αñ▓αÑçαñòαñ░ αñ¬αÑïαñ╕αÑìαñƒαñ«αñ╛αñ░αÑìαñƒαñ« αñòαÑç αñ▓αñ┐αñÅ αñ¡αÑçαñ£αñ╛αÑñ αñòαñ┐αñ»αñ╛ αñ«αñ╛αñ«αñ▓αñ╛ αñªαñ░αÑìαñ£αÑñ\n14:02\n14 minutes, 2 seconds\nαñ▓αñûαñ¿αñè αñòαÑç αñ«αñ╛αñ▓ αñÑαñ╛αñ¿αñ╛ αñòαÑìαñ╖αÑçαññαÑìαñ░ αñ«αÑçαñé αñ¬αññαñ┐ αñ¬αñ░ αñ¬αññαÑìαñ¿αÑÇ αñòαÑÇ αñ╣αññαÑìαñ»αñ╛ αñòαñ╛ αñåαñ░αÑïαñ¬ αñ▓αñùαñ╛ αñ╣αÑêαÑñ αñºαñ╛αñ░αñªαñ╛αñ░ αñ╣αñÑαñ┐αñ»αñ╛αñ░ αñ╕αÑç αñëαññαñ╛αñ░αñ╛ αñ«αÑîαññ αñòαÑç αñÿαñ╛αñƒαÑñ αñåαñ░αÑïαñ¬αÑÇ αñ¿αÑç αñûαÑüαñª αñ¡αÑÇ αñ£αñ╣αñ░αÑÇαñ▓αñ╛ αñ¬αñªαñ╛αñ░αÑìαñÑ αñûαñ╛αñ»αñ╛ αñàαñ╕αÑìαñ¬αññαñ╛αñ▓ αñ«αÑçαñé αñ¡αñ░αÑìαññαÑÇαÑñ\n14:14\n14 minutes, 14 seconds\nαñ¬αñéαñ£αñ╛αñ¼ αñ«αÑçαñé αñ«αÑüαñáαñ¡αÑçαñíαñ╝ αñòαÑç αñ¼αñ╛αñª αñ¬αñòαñíαñ╝αñ╛ αñùαñ»αñ╛ αñ╢αÑéαñƒαñ░αÑñ\n14:16\n14 minutes, 16 seconds\nαñ½αñ┐αñ░αÑïαñ£αñ¬αÑüαñ░ αñ«αÑçαñé αñ«αÑüαñáαñ¡αÑçαñíαñ╝ αñòαÑç αñªαÑîαñ░αñ╛αñ¿ αñ¬αÑüαñ▓αñ┐αñ╕ αñòαÑÇ αñùαÑïαñ▓αÑÇ αñ▓αñùαñ¿αÑç αñ╕αÑç αñ╡αñ┐αñ╖αÑìαñúαÑü αñ¿αñ╛αñ« αñòαñ╛ αñåαñ░αÑïαñ¬αÑÇ αñÿαñ╛αñ»αñ▓ αñ╣αÑüαñåαÑñ\n14:24\n14 minutes, 24 seconds\nαññαÑï αñ╡ αñëαññαÑìαññαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñ╕αÑÇαññαñ╛αñ¬αÑüαñ░ αñ«αÑçαñé αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñòαñ┐αñ»αñ╛ αñºαñ░αÑìαñ«αñ╛αñéαññαñ░αñú αñòαñ╛ αñûαÑüαñ▓αñ╛αñ╕αñ╛αÑñ αñåαñ░αÑìαñÑαñ┐αñò αñ░αÑéαñ¬ αñ╕αÑç αñòαñ«αñ£αÑïαñ░αÑñ αñ▓αÑïαñùαÑïαñé αñòαÑï αñ¿αñ┐αñ╢αñ╛αñ¿αñ╛ αñ¼αñ¿αñ╛αñòαñ░ αñòαñ░αñ╡αñ╛αññαÑç αñÑαÑç αñºαñ░αÑìαñ«αñ╛αñéαññαñ░αñúαÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñÜαñ╛αñ░ αñåαñ░αÑïαñ¬αñ┐αñ»αÑïαñé αñòαÑï αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛ αñ╣αÑêαÑñ\n14:36\n14 minutes, 36 seconds\nαñÜαñéαñªαÑïαñ▓αÑÇ αñ«αÑçαñé αñ«αñ¿αÑïαñ£ αñ¿αñ╛αñ« αñòαÑç αñ╢αñûαÑìαñ╕ αñòαÑÇ αñ╣αññαÑìαñ»αñ╛ αñ«αÑçαñé αñ╣αÑüαñå αñûαÑüαñ▓αñ╛αñ╕αñ╛αÑñ αñ¬αÑêαñ╕αÑïαñé αñòαÑç αñ▓αÑçαñ¿αñªαÑçαñ¿ αñòαÑç αñ╡αñ┐αñ╡αñ╛αñª αñ«αÑçαñé αñ╣αÑüαñê αñÑαÑÇ αñ╡αñ╛αñ░αñªαñ╛αññαÑñ αñ▓αÑïαñòαÑï αñ¬αñ╛αñ»αñ▓αñƒ αñ¿αÑç Γé╣1.5 αñ▓αñ╛αñû\n14:43\n14 minutes, 43 seconds\nαñ╕αÑüαñ¬αñ╛αñ░αÑÇ αñªαÑçαñòαñ░ αñòαñ░αñ╡αñ╛αñê αñÑαÑÇ αñ╣αññαÑìαñ»αñ╛αÑñ αñ▓αÑïαñòαÑï αñ¬αñ╛αñ»αñ▓αñƒ αñ╕αñ«αÑçαññ αñ╕αñ¡αÑÇ αñåαñ░αÑïαñ¬αÑÇ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñÅ αñùαñÅαÑñ\n14:50\n14 minutes, 50 seconds\nαñ¼αñ┐αñ╣αñ╛αñ░ αñòαÑç αñ¿αñ╡αñ╛αñªαñ╛ αñ«αÑçαñé αñÜαÑçαñòαñ┐αñéαñù αñòαÑç αñªαÑîαñ░αñ╛αñ¿ αñ¼αñ░αñ╛αñ«αñª αñ╣αÑüαñê 57 αñ▓αÑÇαñƒαñ░ αñàαñ╡αÑêαñº αñ╡αñ┐αñªαÑçαñ╢αÑÇ αñ╢αñ░αñ╛αñ¼αÑñ αñ╡αñ╛αñ╣αñ¿ αñòαÑç αñàαñéαñªαñ░ αññαñ╣αñûαñ╛αñ¿αñ╛ αñ¼αñ¿αñ╛αñòαñ░ αñ¢αñ┐αñ¬αñ╛αñê αñùαñê αñÑαÑÇ αñ╢αñ░αñ╛αñ¼αÑñ\n14:57\n14 minutes, 57 seconds\nαñ¿αñ╡αñ╛αñªαñ╛ αñÜαÑçαñò αñ¬αÑïαñ╕αÑìαñƒ αñ¬αñ░ αñÜαÑçαñòαñ┐αñéαñù αñòαÑç αñªαÑîαñ░αñ╛αñ¿ αñ╣αÑüαñå αñûαÑüαñ▓αñ╛αñ╕αñ╛αÑñ αñòαÑêαñƒαñò αñ«αÑçαñé 5 αñ╕αñ╛αñ▓ αñòαÑç αñ¼αñÜαÑìαñÜαÑç αñòαÑï αñªαñ┐αñ»αñ╛ αñùαñ»αñ╛ αñ£αñ╣αñ░αÑñ\n15:05\n15 minutes, 5 seconds\nαñùαñéαñ¡αÑÇαñ░ αñ╣αñ╛αñ▓αññ αñ«αÑçαñé αñàαñ╕αÑìαñ¬αññαñ╛αñ▓ αñ«αÑçαñé αñ¡αñ░αÑìαññαÑÇ αñ╕αñéαñ¬αññαÑìαññαñ┐ αñ╡αñ┐αñ╡αñ╛αñª αñ«αÑçαñé αñ╡αñ╛αñ░αñªαñ╛αññαÑñ αñ¬αñ░αñ┐αñ£αñ¿αÑïαñé αñ¿αÑç αñòαÑÇ αñòαñíαñ╝αÑÇ αñòαñ╛αñ░αñ╡αñ╛αñê αñòαÑÇ αñ«αñ╛αñéαñùαÑñ αñ«αÑüαñ░αñ╛αñªαñ╛αñ¼αñ╛αñª αñ«αÑçαñé αñ▓αñ┐αñ╡ αñçαñ¿ αñ░αñ┐αñ▓αÑçαñ╢αñ¿αñ╢αñ┐αñ¬ αñ╕αÑç αñ£αÑüαñíαñ╝αñ╛ αñ«αñ╛αñ«αñ▓αñ╛αÑñ αñ»αÑüαñ╡αññαÑÇ αñ¿αÑç\n15:14\n15 minutes, 14 seconds\nαñ£αñ╣αñ░αÑÇαñ▓αñ╛ αñ¬αñªαñ╛αñ░αÑìαñÑ αñûαñ╛αñòαñ░ αñåαññαÑìαñ«αñ╣αññαÑìαñ»αñ╛ αñòαÑÇαÑñ αñ¬αñ╣αñ▓αÑç αñ╕αÑç αñ╢αñ╛αñªαÑÇαñ╢αÑüαñªαñ╛ αñ╢αñûαÑìαñ╕ αñ¬αñ░ αñ»αÑüαñ╡αññαÑÇ αñòαñ╛ αñ╢αÑïαñ╖αñú αñòαñ░αñ¿αÑç αñòαñ╛ αñåαñ░αÑïαñ¬αÑñ αñ«αñ╛αñ«αñ▓αñ╛ αñ╣αÑüαñå αñªαñ░αÑìαñ£αÑñ\n15:21\n15 minutes, 21 seconds\nαñ«αÑüαñéαñ¼αñê αñ«αÑçαñé αñ¿αñòαñ▓αÑÇ αñ╢αñ░αñ╛αñ¼ αñòαÑÇ αñ½αÑêαñòαÑìαñƒαÑìαñ░αÑÇ αñòαñ╛ αñûαÑüαñ▓αñ╛αñ╕αñ╛ αñ╣αÑüαñåαÑñ αñ¡αñ╛αñ░αÑÇ αñ«αñ╛αññαÑìαñ░αñ╛ αñ«αÑçαñé αñ¿αñòαñ▓αÑÇ αñ╢αñ░αñ╛αñ¼ αñ¼αñ¿αñ╛αñ¿αÑç αñòαñ╛ αñ╕αñ╛αñ«αñ╛αñ¿ αñ¡αÑÇ αñ¼αñ░αñ╛αñ«αñª αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛ αñ╣αÑêαÑñ\n15:30\n15 minutes, 30 seconds\nαñ¬αÑüαñúαÑç αñ«αÑçαñé αñòαñ░αÑÇαñ¼ αñíαÑçαñóαñ╝ αñòαñ░αÑïαñíαñ╝ αñòαÑÇ αñ╢αñ░αñ╛αñ¼ αñ£αñ¼αÑìαññ αñòαÑÇ αñùαñê αñ╣αÑêαÑñ αñùαÑïαñ╡αñ╛ αñ╕αÑç αñ«αñ╣αñ╛αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░ αñ▓αñ╛αñê αñùαñê αñÑαÑÇ αñàαñ╡αÑêαñº αñ╢αñ░αñ╛αñ¼αÑñ αñòαñéαñƒαÑçαñ¿αñ░ αñ«αÑçαñé αñ«αñ┐αñ▓αñ╛ αñ╡αñ┐αñªαÑçαñ╢αÑÇ αñ╢αñ░αñ╛αñ¼ αñòαñ╛ αñ£αñûαÑÇαñ░αñ╛αÑñ\n15:41\n15 minutes, 41 seconds\nαñ¢αññαÑìαññαÑÇαñ╕αñùαñóαñ╝ αñòαÑç αñ¼αñ▓αÑîαñªαñ╛ αñ¼αñ╛αñ£αñ╛αñ░ αñ«αÑçαñé αñ£αÑçαñ▓ αñ╕αÑç αñ¢αÑéαñƒαññαÑç αñ╣αÑÇ αñåαñ░αÑïαñ¬αñ┐αñ»αÑïαñé αñ¿αÑç αñ░αÑÇαñ▓ αñ¼αñ¿αñ╛αñòαñ░ αñ╕αÑïαñ╢αñ▓ αñ«αÑÇαñíαñ┐αñ»αñ╛ αñ¬αñ░ αñ╡αñ╛αñ»αñ░αñ▓ αñòαÑÇαÑñ αñòαñ╛αñ░ αñöαñ░ αñ¼αñ╛αñçαñò αñ░αÑêαñ▓αÑÇ αñ¿αñ┐αñòαñ╛αñ▓αñòαñ░ αñ«αñÜαñ╛αñ»αñ╛ αñ╣αÑüαñíαñ╝αñªαñéαñùαÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç 10 αñåαñ░αÑïαñ¬αñ┐αñ»αÑïαñé αñòαÑï αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛αÑñ\n15:53\n15 minutes, 53 seconds\nαñàαñ«αñ░αÑïαñ╣αñ╛ αñ«αÑçαñé αñ¼αñÜαÑìαñÜαÑÇ αñòαÑç αñ╕αñ╛αñÑ αñªαñ░αñ┐αñéαñªαñùαÑÇ αñòαñ╛ αñ«αñ╛αñ«αñ▓αñ╛αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñåαñ░αÑïαñ¬αÑÇ αñ½αñ░αñ«αñ╛αñ¿ αñòαÑç αñÿαñ░ αñ¬αñ░ αñÜαñ▓αñ╛αñ»αñ╛ αñ¼αÑüαñ▓αñíαÑïαñ£αñ░αÑñ αñåαñ░αÑïαñ¬αÑÇ αñàαñ¡αÑÇ αñ¡αÑÇ αñ¬αÑüαñ▓αñ┐αñ╕ αñòαÑÇ αñùαñ┐αñ░αñ½αÑìαññ αñ╕αÑç αñ¼αñ╛αñ╣αñ░ αñ╣αÑêαÑñ\n16:03\n16 minutes, 3 seconds\nαñ«αñºαÑìαñ» αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñòαñƒαñ¿αÑÇ αñ«αÑçαñé αñ¬αÑüαñ▓αñ┐αñ╕ αñ¬αñ░ αñ¿αñ╛αñ¼αñ╛αñ▓αñ┐αñò αñòαÑÇ αñ¬αñ┐αñƒαñ╛αñê αñòαñ╛ αñåαñ░αÑïαñ¬ αñ▓αñùαñ╛ αñ╣αÑêαÑñ αñ¿αñ╛αñ░αñ╛αñ£ αñùαÑìαñ░αñ╛αñ«αÑÇαñúαÑïαñé αñ¿αÑç αñÜαñòαÑìαñòαñ╛ αñ£αñ╛αñ« αñòαñ░ αñªαñ┐αñ»αñ╛αÑñ αñ╣αñéαñùαñ╛αñ«αÑç αñòαÑÇ αñ╡αñ£αñ╣ αñ╕αÑç αñ╕αñíαñ╝αñò αñ¬αñ░ αñ▓αñùαñ╛ αñ▓αñéαñ¼αñ╛ αñ£αñ╛αñ«αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñàαñºαñ┐αñòαñ╛αñ░αñ┐αñ»αÑïαñé αñòαÑç αñ╕αñ«αñ¥αñ╛αñ¿αÑç αñ¬αñ░ αñ«αñ╛αñ«αñ▓αñ╛ αñ╢αñ╛αñéαññ αñ╣αÑüαñåαÑñ\n16:15\n16 minutes, 15 seconds\nαñëαññαÑìαññαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñ¼αñ░αÑçαñ▓αÑÇ αñ«αÑçαñé αñ«αñ╣αñ┐αñ▓αñ╛ αñòαñ╛ αñ╢αÑïαñ╖αñú αñöαñ░ αñºαñ░αÑìαñ« αñ¬αñ░αñ┐αñ╡αñ░αÑìαññαñ¿ αñòαñ╛ αñªαñ¼αñ╛αñ╡ αñ¼αñ¿αñ╛αñ¿αÑç αñòαñ╛ αñ«αñ╛αñ«αñ▓αñ╛αÑñ\n16:19\n16 minutes, 19 seconds\nαñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñåαñ░αÑïαñ¬αÑÇ αñ»αÑüαñ╡αñò αñàαñ░αñ¼αñ╛αñ£ αñòαÑï αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛αÑñ αñºαñ░αÑìαñ« αñ¢αñ┐αñ¬αñ╛αñòαñ░ αñëαññαÑìαñ¬αÑÇαñíαñ╝αñ¿ αñòαñ╛ αñåαñ░αÑïαñ¬ αñ╣αÑêαÑñ\n16:27\n16 minutes, 27 seconds\nαñëαññαÑìαññαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñ╣αñ╛αñ¬αÑüαñíαñ╝ αñ«αÑçαñé αñ¬αÑüαñ▓αñ┐αñ╕ αñ¡αñ░αÑìαññαÑÇ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛ αñòαÑçαñéαñªαÑìαñ░ αñòαÑç αñàαñéαñªαñ░ αñ«αÑïαñ¼αñ╛αñçαñ▓ αñ▓αÑçαñòαñ░ αñ¬αñ╣αÑüαñéαñÜαñ╛ αñ»αÑüαñ╡αñò αñ╡αñ╛αñ╢αñ░αÑéαñ« αñòαÑç αñàαñéαñªαñ░αÑñ αñ«αÑïαñ¼αñ╛αñçαñ▓ αñòαÑç αñ╕αñ╛αñÑ αñ¬αñòαñíαñ╝αñ╛ αñùαñ»αñ╛ αñ»αÑüαñ╡αñòαÑñ αñ▓αñ╛αñ¬αñ░αñ╡αñ╛αñ╣αÑÇ αñ¬αñ░ αñªαÑï\n16:35\n16 minutes, 35 seconds\nαñªαñ╛αñ░αÑïαñùαñ╛ αñ╕αñ«αÑçαññ αñ¢αñ╣ αñ¿αñ┐αñ▓αñéαñ¼αñ┐αññ [αñ╕αñéαñùαÑÇαññ] αñòαñ┐αñÅ αñùαñÅ	f	2026-06-09 13:23:26.079798
32	UCRWFSbif-RFENbBrSiez1DA	National	General	Transcript\nSearch transcript\n0:03\n3 seconds\nαñ╡αñ┐αñ╢αñ╛αñûαñ╛αñ¬αñƒαñ¿αñ« αñ╕αÑìαñƒαÑÇαñ▓ αñ¬αÑìαñ▓αñ╛αñéαñƒ αñ«αÑçαñé αñ¼αñíαñ╝αñ╛ αñ╣αñ╛αñªαñ╕αñ╛αÑñ\n0:05\n5 seconds\nαñ¬αñ┐αñÿαñ▓αñ╛ αñ╣αÑüαñå αñ╕αÑìαñƒαÑÇαñ▓ αñùαñ┐αñ░αñ¿αÑç αñòαÑÇ αñ╡αñ£αñ╣ αñ╕αÑç αñåαñá αñ«αñ£αñªαÑéαñ░αÑïαñé αñòαÑÇ αñ«αÑîαññ αñ╣αÑï αñùαñêαÑñ αñòαñê αñ«αñ£αñªαÑéαñ░ αñ¥αÑüαñ▓αñ╕ αñùαñÅ αñ╣αÑêαñéαÑñ αñ╣αñ╛αñªαñ╕αÑç αñòαÑÇ αñ╡αñ£αñ╣ αñ╕αÑç αñ¬αÑìαñ▓αñ╛αñéαñƒ αñ«αÑçαñé αñàαñ½αñ░αñ╛αññαñ½αñ░αÑÇ αñòαñ╛ αñ«αñ╛αñ╣αÑîαñ▓ αñ¼αñ¿ αñùαñ»αñ╛αÑñ\n0:15\n15 seconds\nαñ╡αñ┐αñ╢αñ╛αñûαñ╛αñ¬αñƒαñ¿αñ« αñ╣αñ╛αñªαñ╕αÑç αñ¬αñ░ αñ¬αÑÇαñÅαñ« αñ«αÑïαñªαÑÇ αñ¿αÑç αñ¡αÑÇ αñªαÑüαñû αñ╡αÑìαñ»αñòαÑìαññ αñòαñ┐αñ»αñ╛αÑñ αñ«αÑâαññαñòαÑïαñé αñòαÑç αñ¬αñ░αñ┐αñ£αñ¿αÑïαñé αñòαÑï αñªαÑï αñ▓αñ╛αñû αñöαñ░ αñÿαñ╛αñ»αñ▓αÑïαñé αñòαÑï 50-500 αñòαÑÇ αñåαñ░αÑìαñÑαñ┐αñò αñ╕αñ╣αñ╛αñ»αññαñ╛ αñ«αñ┐αñ▓αÑçαñùαÑÇαÑñ\n0:26\n26 seconds\nαñ▓αñûαñ¿αñè αñòαÑç αñ¬αñ╛αñ░αñ╛ αñçαñ▓αñ╛αñòαÑç αñ«αÑçαñé αñ«αñ╣αñ┐αñ▓αñ╛ αñàαñ¡αÑìαñ»αñ░αÑìαñÑαñ┐αñ»αÑïαñé αñòαÑç αñ╕αñ╛αñÑ αñ¢αÑçαñíαñ╝αñûαñ╛αñ¿αÑÇ αñòαñ╛ αñ«αñ╛αñ«αñ▓αñ╛αÑñ αñåαñ░αÑïαñ¬αÑÇ αñæαñƒαÑï αñÜαñ╛αñ▓αñò αñ¬αÑüαñ▓αñ┐αñ╕ αñòαÑç αñ╕αñ╛αñÑ αñ«αÑüαñáαñ¡αÑçαñíαñ╝ αñ«αÑçαñé αñÿαñ╛αñ»αñ▓ αñ╣αÑüαñåαÑñ αñ¬αñ╣αñ▓αÑç αñ¡αÑÇ αñ░αÑçαñ¬ αñòαÑç αñåαñ░αÑïαñ¬ αñ«αÑçαñé αñ£αÑçαñ▓ αñ£αñ╛ αñÜαÑüαñòαñ╛ αñ╣αÑê αñåαñ░αÑïαñ¬αÑÇαÑñ\n0:38\n38 seconds\nαñàαñ«αñ░αÑïαñ╣αñ╛ αñ«αÑçαñé αñ¼αñÜαÑìαñÜαÑÇ αñòαÑç αñ╕αñ╛αñÑ αñªαñ░αñ┐αñéαñªαñùαÑÇ αñòαñ╛ αñ«αñ╛αñ«αñ▓αñ╛αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñåαñ░αÑïαñ¬αÑÇ αñ½αñ░αñ╣αñ╛αñ¿ αñòαÑç αñÿαñ░ αñ¬αñ░ αñÜαñ▓αñ╛αñ»αñ╛ αñ¼αÑüαñ▓αñíαÑïαñ£αñ░αÑñ αñåαñ░αÑïαñ¬αÑÇ αñàαñ¡αÑÇ αñ¡αÑÇ αñ¬αÑüαñ▓αñ┐αñ╕ αñòαÑÇ αñùαñ┐αñ░αñ½αÑìαññ αñ╕αÑç αñ¼αñ╛αñ╣αñ░ αñ╣αÑêαÑñ\n0:49\n49 seconds\nαñ«αñºαÑìαñ» αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑÇ αñòαñƒαñ¿αÑÇ αñ«αÑçαñé αñ¬αÑüαñ▓αñ┐αñ╕ αñ¬αñ░ αñ¿αñ╛αñ¼αñ╛αñ▓αñ┐αñò αñòαÑÇ αñ¬αñ┐αñƒαñ╛αñê αñòαñ╛ αñåαñ░αÑïαñ¬ αñ╣αÑêαÑñ αñ¿αñ╛αñ░αñ╛αñ£ αñùαÑìαñ░αñ╛αñ«αÑÇαñúαÑïαñé αñ¿αÑç αñÜαñòαÑìαñòαñ╛ αñ£αñ╛αñ« αñòαñ░ αñªαñ┐αñ»αñ╛αÑñ αñ╣αñéαñùαñ╛αñ«αÑç αñòαÑÇ αñ╡αñ£αñ╣ αñ╕αÑç αñ╕αñíαñ╝αñò αñ¬αñ░ αñ£αñ╛αñ« αñ▓αñù αñùαñ»αñ╛αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñàαñºαñ┐αñòαñ╛αñ░αñ┐αñ»αÑïαñé αñòαÑç αñ╕αñ«αñ¥αñ╛αñ¿αÑç αñ¬αñ░ αñ▓αÑïαñù αñ╢αñ╛αñéαññ αñ╣αÑüαñÅαÑñ\n1:02\n1 minute, 2 seconds\nαñ£αÑïαñ░αñ£αñ┐αñ▓αñ╛ αñ╕αÑüαñ░αñéαñù αñ¬αñ░αñ┐αñ»αÑïαñ£αñ¿αñ╛ αñòαñ╛ αñåαñ£ αñàαñ╣αñ« αñ¬αñíαñ╝αñ╛αñ╡ αñ╣αÑêαÑñ αñåαñ£ αñªαÑïαñ¿αÑïαñé αññαñ░αñ½ αñ╕αÑç αñ«αñ┐αñ▓ αñ£αñ╛αñÅαñéαñùαÑÇ αñ╕αÑüαñ░αñéαñùαÑñ\n1:06\n1 minute, 6 seconds\nαñ¿αñ┐αññαñ┐αñ¿ αñùαñíαñòαñ░αÑÇ αñ░αñ╣αÑçαñéαñùαÑç αñ«αÑîαñ£αÑéαñªαÑñ αñ╕αÑìαñÑαñ╛αñ¿αÑÇαñ» αñ▓αÑïαñùαÑïαñé αñ¿αÑç αñòαñ╣αñ╛ αñ╕αñ½αñ░ αñåαñ╕αñ╛αñ¿ αñ╣αÑïαñùαñ╛αÑñ αñ¬αñ░αÑìαñ»αñƒαñ¿ αñ¡αÑÇ αñ¼αñóαñ╝αÑçαñùαñ╛αÑñ\n1:14\n1 minute, 14 seconds\nαñ¬αñ╢αÑìαñÜαñ┐αñ« αñ¼αñéαñùαñ╛αñ▓ αñ╡αñ┐αñºαñ╛αñ¿αñ╕αñ¡αñ╛ αñòαÑç αñ¼αñ╛αñª αñàαñ¼ αñ╕αñéαñ╕αñª αñ«αÑçαñé αñ¡αÑÇ αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñƒαÑéαñƒαÑÇαÑñ αñ¼αñ╛αñùαÑÇ αñùαÑüαñƒ αñòαñ╛ αñªαñ╛αñ╡αñ╛ αñ╣αñ«αñ╛αñ░αÑç αñ¬αñ╛αñ╕ αñ╣αÑêαÑñ 20 αñ╕αñ╛αñéαñ╕αñªαÑïαñé αñòαñ╛ αñ╕αñ«αñ░αÑìαñÑαñ¿αÑñ αñòαñ╣αñ╛ αñ¼αñ¿αñ╛αñÅαñéαñùαÑç αñàαñ▓αñù αñùαÑüαñƒαÑñ\n1:26\n1 minute, 26 seconds\nαñ░αñ╛αñ£αÑìαñ»αñ╕αñ¡αñ╛ αñ╕αÑç αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ╕αñ╛αñéαñ╕αñª αñ╕αÑüαñûαÑçαñéαñªαÑìαñ░ αñ╢αÑçαñûαñ░ αñ░αÑëαñ» αñòαñ╛ αñçαñ╕αÑìαññαÑÇαñ½αñ╛αÑñ αñ«αñ«αññαñ╛ αñ¬αñ░ αñ▓αñùαñ╛αñÅ αñ╣αÑêαñé αñåαñ░αÑïαñ¬αÑñ\n1:31\n1 minute, 31 seconds\nαñåαñ¿αÑç αñ╡αñ╛αñ▓αÑç αñªαñ┐αñ¿αÑïαñé αñ«αÑçαñé αñ░αñ╛αñ£αÑìαñ»αñ╕αñ¡αñ╛ αñ╕αÑç αñ╣αÑï αñ╕αñòαññαÑç αñ╣αÑêαñé αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñòαÑç αñòαñê αñöαñ░ αñ╕αñ╛αñéαñ╕αñªαÑïαñé αñòαÑç αñçαñ╕αÑìαññαÑÇαñ½αÑçαÑñ\n1:38\n1 minute, 38 seconds\nαñ╕αÑïαñ«αñ╡αñ╛αñ░ αñòαÑï αñçαñéαñíαñ┐αñ»αñ╛ αñùαñáαñ¼αñéαñºαñ¿ αñòαÑÇ αñ¼αÑêαñáαñò αñ╕αÑç αñ¬αñ╣αñ▓αÑç αñƒαÑéαñƒ αñùαñê αñƒαÑÇαñÅαñ«αñ╕αÑÇαÑñ αñ░αñ╡αñ┐αñ╡αñ╛αñ░ αñòαÑï αñ«αñ«αññαñ╛ αñåαñê αñÑαÑÇ αñªαñ┐αñ▓αÑìαñ▓αÑÇαÑñ αñëαñ¿αÑìαñ╣αÑÇαñé αñòαÑÇ αñ«αñ╛αñéαñù αñ¬αñ░ αñ╣αÑüαñê αñÑαÑÇ αñçαñéαñíαñ┐αñ»αñ╛ αñùαñáαñ¼αñéαñºαñ¿ αñòαÑÇ αñ¼αÑêαñáαñòαÑñ\n1:49\n1 minute, 49 seconds\nαñòαÑçαñéαñªαÑìαñ░αÑÇαñ» αñ«αñéαññαÑìαñ░αÑÇ αñ¡αÑéαñ¬αÑçαñéαñªαÑìαñ░ αñ»αñ╛αñªαñ╡ αñòαÑç αñÿαñ░αÑñ\n1:51\n1 minute, 51 seconds\nαñƒαÑÇαñÅαñ«αñ╕αÑÇ αñòαÑç αñ¼αñ╛αñùαÑÇ αñ╕αñ╛αñéαñ╕αñªαÑïαñé αñ╕αÑç αñ«αñ┐αñ▓αÑç αñ╕αÑÇαñÅαñ« αñ╢αÑüαñ¡αÑçαñéαñªαÑü αñàαñºαñ┐αñòαñ╛αñ░αÑÇαÑñ αñ¼αÑêαñáαñò αñ«αÑçαñé 14 αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ╕αñ╛αñéαñ╕αñªαÑïαñé αñòαÑç αñ«αÑîαñ£αÑéαñª αñ╣αÑïαñ¿αÑç αñöαñ░ αñ½αñ┐αñ░ αñòαÑüαñ¢ αñòαÑç αñæαñ¿αñ▓αñ╛αñçαñ¿ αñ£αÑüαñíαñ╝αñ¿αÑç αñòαñ╛ αñ¡αÑÇ αñªαñ╛αñ╡αñ╛ αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛αÑñ\n2:02\n2 minutes, 2 seconds\n20 αñ╕αñ╛αñéαñ╕αñªαÑïαñé αñòαÑç αñªαñ╛αñ╡αÑç αñòαÑï αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ╕αñ╛αñéαñ╕αñª αñòαÑÇαñ░αÑìαññαñ┐ αñåαñ£αñ╛αñª αñ¿αÑç αñ½αñ░αÑìαñ£αÑÇ αñ¼αññαñ╛αñ»αñ╛ αñÑαñ╛αÑñ αñ¡αÑéαñ¬αÑçαñéαñªαÑìαñ░ αñ»αñ╛αñªαñ╡ αñòαÑç αñÿαñ░ αñ¬αñ░ αñ¼αÑêαñáαñò αñ╣αÑüαñê αñ£αñ┐αñ╕αñ«αÑçαñé αñòαÑçαñ╡αñ▓ 13 αñ╕αñ╛αñéαñ╕αñª αñÑαÑç αñ¿αñ╛ αñòαñ┐ 20 αñ╕αñ╛αñéαñ╕αñªαÑñ\n2:13\n2 minutes, 13 seconds\nαñ¼αñéαñùαñ╛αñ▓ αñ╡αñ┐αñºαñ╛αñ¿αñ╕αñ¡αñ╛ αñòαÑç αñ¼αñ╛αñª αñ╕αñéαñ╕αñª αñ«αÑçαñé αñ¡αÑÇ αñ«αñ«αññαñ╛ αñòαÑï αñ¥αñƒαñòαñ╛αÑñ αñƒαÑé αñƒαÑÇαñƒαÑÇαñÅαñ«αñ╕αÑÇαÑñ αñåαñ£ αñòαñ▓αÑìαñ»αñ╛αñú αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñöαñ░ αñòαÑÇαñ░αÑìαññαñ┐ αñåαñ£αñ╛αñª αñòαñ░αÑçαñéαñùαÑç αñ¬αÑìαñ░αÑçαñ╕ αñòαÑëαñ¿αÑìαñ½αÑìαñ░αÑçαñéαñ╕αÑñ\n2:24\n2 minutes, 24 seconds\nαñ¼αñ╛αñùαÑÇ αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ╕αñ╛αñéαñ╕αñª αñòαñ╛αñòαÑïαñ▓αÑÇ αñÿαÑïαñ╖ αñ¼αÑïαñ▓αÑÇ αñòαÑïαñê αñíαñ░ αñ¿αñ╣αÑÇαñéαÑñ αñ«αÑêαñé αñ»αñ╣αñ╛αñé 40 αñ╕αñ╛αñ▓ αñ╕αÑç αñ▓αñíαñ╝ αñ░αñ╣αÑÇ αñ▓αÑçαñòαñ┐αñ¿ αñ«αñ«αññαñ╛ αñ«αÑüαñûαÑìαñ»αñ«αñéαññαÑìαñ░αÑÇ αñ¼αñ¿αñ¿αÑç αñòαÑç αñ¼αñ╛αñª αñ»αñ╣αñ╛αñé αñ¬αñ░ αñåαñê αñ¿αñ╣αÑÇαñéαÑñ\n2:35\n2 minutes, 35 seconds\nαñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ╕αñ╛αñéαñ╕αñªαÑïαñé αñòαÑÇ αñƒαÑéαñƒ αñòαÑç αñ¼αÑÇαñÜ αñòαÑïαñ▓αñòαñ╛αññαñ╛ αñ«αÑçαñé αñ«αñ«αññαñ╛ αñòαÑç αñåαñ╡αñ╛αñ╕ αñ¬αñ░ αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ¿αÑçαññαñ╛ αñ¬αñ╣αÑüαñéαñÜαÑçαÑñ αñòαÑüαñúαñ╛αñ▓ αñÿαÑïαñ╖ αñ¼αÑïαñ▓αÑç αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñòαÑç αñ¿αñ┐αñ╢αñ╛αñ¿αÑç αñ¬αñ░αÑñ\n2:42\n2 minutes, 42 seconds\nαñƒαÑÇαñÅαñ«αñ╕αÑÇ αñòαÑç αñ¿αñ┐αñ╢αñ╛αñ¿ αñ¬αñ░ αñ£αÑÇαññαñ¿αÑç αñ╡αñ╛αñ▓αÑç αñ»αñ╛αñª αñ░αñûαÑçαñé αñ£αñ¿αññαñ╛ αñªαÑçαñû αñ░αñ╣αÑÇ αñ╣αÑêαÑñ\n2:49\n2 minutes, 49 seconds\nαñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ¿αÑçαññαñ╛ αñ«αñ╣αñ╡αñ╛ αñ«αÑïαñ╣αññαÑìαñ░αñ╛ αñòαÑç αñ¼αñ╛αñùαñ┐αñ»αÑïαñé αñ¬αñ░ αññαÑÇαñûαñ╛ αñ╣αñ«αñ▓αñ╛αÑñ αñòαñ╣αñ╛ αñòαñ┐ αñçαñ╕αÑìαññαÑÇαñ½αñ╛ αñªαÑçαñòαñ░ αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñòαÑç αñƒαñ┐αñòαñƒ αñ¬αñ░ αñ▓αñíαñ╝αÑç αñÜαÑüαñ¿αñ╛αñ╡αÑñ αñªαÑçαñûαññαÑç αñ╣αÑêαñé αñåαñ¬ αñòαñ┐αññαñ¿αÑç αñ¼αñíαñ╝αÑç αñ╣αÑÇαñ░αÑïαÑñ\n2:59\n2 minutes, 59 seconds\nαñƒαÑÇαñÅαñ«αñ╕αÑÇ αñòαÑç αñ¼αñ╛αñùαñ┐αñ»αÑïαñé αñòαñ╛ 20 αñ╕αñ╛αñéαñ╕αñª αñ╣αÑïαñ¿αÑç αñòαñ╛ αñªαñ╛αñ╡αñ╛αÑñ αñòαÑçαñéαñªαÑìαñ░αÑÇαñ» αñ«αñéαññαÑìαñ░αÑÇ αñùαñ┐αñ░αñ┐αñ░αñ╛αñ£ αñ╕αñ┐αñéαñ╣ αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñàαñ¼ αñûαññαÑìαñ«αÑñ αñíαÑéαñ¼αññαÑÇ αñ¿αñ╛αñ╡ αñ¬αñ░ αñàαñ¼ αñòαÑîαñ¿ αñ¼αÑêαñáαñ¿αñ╛ αñÜαñ╛αñ╣αÑçαñùαñ╛?\n3:09\n3 minutes, 9 seconds\nαñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ«αÑçαñé αñƒαÑéαñƒ αñòαÑï αñ▓αÑçαñòαñ░ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñ¿αÑçαññαñ╛ αñ£αñ»αñ░αñ╛αñ« αñ░αñ«αÑçαñ╢ αñòαñ╛ αñ¡αÑéαñ¬αÑçαñéαñªαÑìαñ░ αñ»αñ╛αñªαñ╡ αñ¬αñ░ αñ¿αñ┐αñ╢αñ╛αñ¿αñ╛αÑñ\n3:13\n3 minutes, 13 seconds\nαñòαñ╣αñ╛ αñòαñ┐ αñ╢αñ┐αñòαñ╛αñ░ αñ░αÑïαñòαñ¿αÑç αñ╡αñ╛αñ▓αÑç αñ«αñéαññαÑìαñ░αÑÇ αñ¼αñ¿αÑç αñ╢αñ┐αñòαñ╛αñ░αÑÇαÑñ αñàαñ╡αÑêαñº αñ╢αñ┐αñòαñ╛αñ░ αñ«αÑçαñé αñ¼αñ┐αññαñ╛αñ»αñ╛ αñªαñ┐αñ¿αÑñ\n3:20\n3 minutes, 20 seconds\nαñëαññαÑìαññαñ░αÑÇ αñçαñ░αñ╛αñò αñ«αÑçαñé αñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñáαñ┐αñòαñ╛αñ¿αÑïαñé αñ¬αñ░ αñêαñ░αñ╛αñ¿ αñ¿αÑç αñ╣αñ«αñ▓αÑç αñòαñ┐αñÅ αñ╣αÑêαñéαÑñ αñ╕αÑïαñ╛αñ¿ αñöαñ░ αñûαñ▓αÑÇαñ½αñ╛αñ¿ αñòαÑç αñèαñ¬αñ░ αñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñÅαñ»αñ░ αñíαñ┐αñ½αÑçαñéαñ╕ αñ╕αñ┐αñ╕αÑìαñƒαñ« αñ¿αÑç αñòαñê αñíαÑìαñ░αÑïαñéαñ╕ αñòαÑï αñçαñéαñƒαñ░αñ╕αÑçαñ¬αÑìαñƒ αñòαñ┐αñ»αñ╛αÑñ\n3:32\n3 minutes, 32 seconds\nαñ»αñ«αñ¿ αñòαÑçαÑéαñªαÑÇ αñ╡αñ┐αñªαÑìαñ░αÑïαñ╣αñ┐αñ»αÑïαñé αñ¿αÑç αñçαñ£αñ░αñ╛αñçαñ▓ αñ¬αñ░ αñ«αñ┐αñ╕αñ╛αñçαñ▓ αñàαñƒαÑêαñò αñòαñ╛ αñªαñ╛αñ╡αñ╛ αñòαñ┐αñ»αñ╛ αñ╣αÑêαÑñ αñòαñ╣αñ╛ αñ╣αÑê αñòαñ┐ αñ▓αñ╛αñ▓ αñ╕αñ╛αñùαñ░ αñ«αÑçαñé αñçαñ£αñ░αñ╛αñçαñ▓ αñ╕αÑç αñ£αÑüαñíαñ╝αÑç αñ£αñ╣αñ╛αñ£αÑïαñé αñ¬αñ░ αñÅαñò αñ¼αñ╛αñ░ αñ½αñ┐αñ░ αñ╕αÑç αñ╣αñ«αñ▓αÑç αñ╣αÑïαñéαñùαÑçαÑñ\n3:42\n3 minutes, 42 seconds\nαñ╣αñ┐αñ£αñ¼αÑüαñ▓αÑìαñ▓αñ╛ αñ¿αÑç αñòαñ┐αñ»αñ╛ αñçαñ£αñ░αñ▓αÑÇαñ» αñ╕αÑçαñ¿αñ╛ αñòαÑç αñƒαÑêαñéαñò αñ¬αñ░ αñ╣αñ«αñ▓αÑç αñòαñ╛ αñªαñ╛αñ╡αñ╛αÑñ αñªαñòαÑìαñ╖αñ┐αñúαÑÇ αñ▓αÑçαñ¼αñ¿αñ╛αñ¿ αñ«αÑçαñé αñçαñ£αñ░αñ»αñ▓αÑÇ αñ¼αñ░αñòαñ╛αñ╡αñ╛ αñƒαÑêαñéαñò αñ¬αñ░ αñíαÑìαñ░αÑïαñ¿ αñ╕αÑç αñàαñƒαÑêαñò αñòαñ░αñ¿αÑç αñòαñ╛ αñ╡αÑÇαñíαñ┐αñ»αÑï αñ¡αÑÇ αñ╕αñ╛αñ«αñ¿αÑç αñåαñ»αñ╛αÑñ\n3:53\n3 minutes, 53 seconds\nαñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñ╕αÑçαñ¿αñ╛ αñ¿αÑç αñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑÇ αñôαñ░ αñªαñ╛αñùαÑÇ αñùαñê αñêαñ░αñ╛αñ¿αÑÇ αñ«αñ┐αñ╕αñ╛αñçαñ▓αÑïαñé αñòαÑï αñçαñéαñƒαñ░αñ╕αÑçαñ¬αÑìαñƒ αñòαñ░αñ¿αÑç αñ«αÑçαñé αñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑÇ αñ«αñªαñª αñòαÑÇαÑñ αñ«αÑÇαñíαñ┐αñ»αñ╛ αñ░αñ┐αñ¬αÑïαñ░αÑìαñƒαÑìαñ╕ αñ«αÑçαñé αñªαñ╛αñ╡αñ╛ αñòαñ┐αñ»αñ╛ αñ£αñ╛ αñ░αñ╣αñ╛ αñ╣αÑê αñòαñ┐ αñàαñ«αÑçαñ░αñ┐αñòαÑÇ\n4:01\n4 minutes, 1 second\nαñàαñºαñ┐αñòαñ╛αñ░αñ┐αñ»αÑïαñé αñòαÑç αñ╣αñ╡αñ╛αñ▓αÑç αñ╕αÑç αñ¡αÑÇ αñ£αñ╛αñ¿αñòαñ╛αñ░αÑÇ αñ«αñ┐αñ▓αÑçαñùαÑÇαÑñ\n4:06\n4 minutes, 6 seconds\nαñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑç αñ¬αÑÇαñÅαñ« αñ¿αñ┐αññαñ┐αñ¿ αñ»αñ╛αñ╣αÑé αñ¿αÑç αñƒαÑìαñ░αñéαñ¬ αñ╕αÑç αñòαñ╣αñ╛ αñêαñ░αñ╛αñ¿ αñòαÑç αñ╣αñ«αñ▓αÑç αñòαñ╛ αñ£αñ╡αñ╛αñ¼ αñ¿αñ╛ αñªαÑçαñ¿αñ╛ αñçαñ£αñ░αñ╛αñçαñ▓ αñöαñ░ αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñªαÑïαñ¿αÑïαñé αñòαÑç αñ▓αñ┐αñÅ αñ¼αÑüαñ░αñ╛ αñ╣αÑïαñùαñ╛αÑñ αñíαÑÇαñ▓ αñòαÑç αñ▓αñ┐αñÅ αñ¡αÑÇ αñ╣αÑïαñùαñ╛ αñ¿αÑüαñòαñ╕αñ╛αñ¿αñªαÑçαñ╣αÑñ\n4:17\n4 minutes, 17 seconds\nαñ╕αÑéαññαÑìαñ░αÑïαñé αñòαÑç αñ╣αñ╡αñ╛αñ▓αÑç αñ╕αÑç αñûαñ¼αñ░ αñ¿αñ┐αññαñ┐αñ¿ αñ»αñ╛αñ╣αÑé αñ¿αÑç αñƒαÑìαñ░αñéαñ¬ αñ╕αÑç αñòαñ╣αñ╛ αñàαñùαñ░ αñòαñ╛αñ░αñ╡αñ╛αñê αñ¿αñ╣αÑÇαñé αñòαÑÇ αñùαñê αññαÑï αñ╕αñéαñªαÑçαñ╢ αñ£αñ╛αñÅαñùαñ╛ αñòαñ┐ αñêαñ░αñ╛αñ¿ αñòαñ╛ αñ¬αñ▓αñíαñ╝αñ╛ αñ¡αñ╛αñ░αÑÇ αñ╣αÑêαÑñ\n4:23\n4 minutes, 23 seconds\nαñêαñ░αñ╛αñ¿ αñ░αÑïαñò αñ╕αñòαññαñ╛ αñ╣αÑê αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñöαñ░ αñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑÇ αñ╕αÑêαñ¿αÑìαñ» αñòαñ╛αñ░αñ╡αñ╛αñêαÑñ αñêαñ░αñ╛αñ¿ αñòαÑÇ αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñöαñ░ αñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑï αñÜαÑçαññαñ╛αñ╡αñ¿αÑÇαÑñ\n4:32\n4 minutes, 32 seconds\nαñòαñ╣αñ╛ αññαñ¿αñ╛αñ╡ αñ¼αñóαñ╝αñ╛αñ¿αÑç αñòαÑÇ αñòαÑïαñ╢αñ┐αñ╢ αñÑαÑÇαÑñ αññαÑï αñ«αñ┐αñ▓αÑçαñùαñ╛ αñ«αÑüαñéαñ╣αññαÑïαñíαñ╝ αñ£αñ╡αñ╛αñ¼αÑñ αñêαñ░αñ╛αñ¿ αñöαñ░ αñëαñ¿αñòαÑç αñ╕αñ╣αñ»αÑïαñùαñ┐αñ»αÑïαñé αñòαÑç αñ¬αñ╛αñ╕ αñ£αñ╡αñ╛αñ¼ αñªαÑçαñ¿αÑç αñòαÑÇ αñòαÑìαñ╖αñ«αññαñ╛αÑñ\n4:41\n4 minutes, 41 seconds\nαñçαñ£αñ░αñ▓αÑÇ αñ¬αÑìαñ░αñºαñ╛αñ¿αñ«αñéαññαÑìαñ░αÑÇ αñ¼αÑçαñéαñ£αñ╛αñ« αñ¿αÑç αñ¿αñ┐αññαñ¿ αñ»αñ╛αÑé αñ¿αÑç αñòαñ╣αñ╛ αñ½αñ░αñ╣αñ╛αñ░ αñêαñ░αñ╛αñ¿ αñòαÑç αñ╕αñ╛αñÑ αñÑαñ« αñùαñê αñ╣αÑê αñ▓αñíαñ╝αñ╛αñêαÑñ\n4:46\n4 minutes, 46 seconds\nαñêαñ░αñ╛αñ¿ αñ¿αÑç αñªαÑïαñ¼αñ╛αñ░αñ╛ αñ╣αñ«αñ▓αñ╛ αñòαñ┐αñ»αñ╛ αññαÑï αñçαñ£αñ░αñ╛αñçαñ▓ αñªαÑçαñùαñ╛ αñ¬αÑéαñ░αÑÇ αññαñ╛αñòαññ αñòαÑç αñ╕αñ╛αñÑ αñ£αñ╡αñ╛αñ¼αÑñ\n4:52\n4 minutes, 52 seconds\nαñíαÑëαñ¿αñ▓αÑìαñí αñƒαÑìαñ░αñéαñ¬ αñ¿αÑç αñ¿αñ┐αññαñ¿ αñ»αñ╛αÑé αñòαÑï αñªαÑÇ αñÑαÑÇ αñ╣αñ┐αñªαñ╛αñ»αññαÑñ αñòαñ╣αñ╛ αñòαñ┐ αñêαñ░αñ╛αñ¿ αñòαÑç αñ╕αñ╛αñÑ αñ½αñ┐αñ░ αñ╕αÑç αñ»αÑüαñªαÑìαñº αñ«αÑçαñé αñûαññαñ░αÑçαÑñ αññαÑï αñëαñ¿αÑìαñ╣αÑçαñé αñàαñòαÑçαñ▓αÑç αñ╣αÑÇ αñ▓αñíαñ╝αñ¿αñ╛ αñ¬αñíαñ╝αññαñ╛ αñ╣αÑêαÑñ αñ¬αñíαñ╝ αñ╕αñòαññαñ╛ αñ╣αÑê αñ»αÑüαñªαÑìαñºαÑñ αñÉαñ╕αñ╛ αñòαñ┐αñ»αñ╛ αññαÑï αñàαñ▓αñù-αñÑαñ▓αñù αñ¬αñíαñ╝ αñ£αñ╛αñÅαñùαñ╛ αñçαñ£αñ░αñ╛αñçαñ▓αÑñ\n5:05\n5 minutes, 5 seconds\nαñêαñ░αñ╛αñ¿ αñòαÑç αñëαñ¬αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ¬αññαñ┐ αñ«αÑïαñ╣αñ«αÑìαñ«αñª αñ░αñ£αñ╛ αñåαñ░αñ┐αñ½ αñòαñ╛ αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñöαñ░ αñçαñ£αñ░αñ╛αñçαñ▓ αñ¬αñ░ αñ¿αñ┐αñ╢αñ╛αñ¿αñ╛αÑñ αñòαñ╣αñ╛ αñªαÑüαñ╢αÑìαñ«αñ¿ αñªαÑçαñ╢αÑïαñé αñòαÑï αñ¼αñ╣αÑüαññ αñòαñ« αñ╕αñ«αñ» αñ«αÑçαñé αñ╣αÑüαñå αñêαñ░αñ╛αñ¿ αñòαÑÇ\n5:12\n5 minutes, 12 seconds\nαññαñ╛αñòαññ αñòαñ╛ αñÅαñ╣αñ╕αñ╛αñ╕αÑñ αñ»αÑüαñªαÑìαñº αñ╡αñ┐αñ░αñ╛αñ« αñ╕αÑìαñ╡αÑÇαñòαñ╛αñ░ αñòαñ░αñ¿αÑç αñòαÑÇ αñùαÑüαñ╣αñ╛αñ░ αñ▓αñùαñ╛αñ¿αÑç αñ¬αñ░ αñ«αñ£αñ¼αÑéαñ░ αñòαñ┐αñ»αñ╛αÑñ\n5:19\n5 minutes, 19 seconds\nαñ½αÑìαñ░αñ╛αñéαñ╕ αñ«αÑçαñé αñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑç αñ░αñ╛αñ£αñªαÑéαññ αñ£αÑïαñ╢αÑüαñå αñ£αÑìαñ╡αñ╛αñ░αñòαñ╛ αñòαñ╛ αñ¼αñ»αñ╛αñ¿αÑñ αñòαñ╣αñ╛ αñòαñ┐ αñçαñ£αñ░αñ╛αñçαñ▓ αñöαñ░ αñêαñ░αñ╛αñ¿ αñòαÑç αñ¼αÑÇαñÜ αñ▓αñíαñ╝αñ╛αñê αñ½αñ┐αñ░ αñ╕αÑç αñ╢αÑüαñ░αÑé αñòαñ░αñ¿αÑç αñòαñ╛ αñ½αÑêαñ╕αñ▓αñ╛\n5:26\n5 minutes, 26 seconds\nαñêαñ░αñ╛αñ¿ αñòαñ╛ αñÑαñ╛αÑñ αñ»αÑüαñªαÑìαñºαñ╡αñ┐αñ░αñ╛αñ« αñòαÑç αñ¼αñ╛αñª αñ╕αÑç αñªαÑïαñ¿αÑïαñé αñ¬αñòαÑìαñ╖αÑïαñé αñòαÑç αñ¼αÑÇαñÜ αñ¬αñ╣αñ▓αÑÇ αñ¼αñ╛αñ░ αñ╣αñ«αñ▓αÑç αñ╣αÑüαñÅαÑñ\n5:33\n5 minutes, 33 seconds\nαñ╕αñéαñ»αÑüαñòαÑìαññ αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░ αñ¿αÑç αñ«αñ┐αñíαñ┐αñ▓ αñêαñ╕αÑìαñƒ αñ«αÑçαñé αñ¼αñóαñ╝αññαÑç αññαñ¿αñ╛αñ╡ αñ¬αñ░ αñÅαñò αñ¼αñ╛αñ░ αñ½αñ┐αñ░ αñ╕αÑç αñÜαñ┐αñéαññαñ╛ αñ╡αÑìαñ»αñòαÑìαññ αñòαÑÇαÑñ\n5:36\n5 minutes, 36 seconds\nαñ╕αñ¡αÑÇ αñ¬αñòαÑìαñ╖αÑïαñé αñ╕αÑç αñ╕αñéαñ»αñ« αñ¼αñ░αññαñ¿αÑç αñòαÑÇ αñàαñ¬αÑÇαñ▓ αñòαÑÇαÑñ αñòαñ╣αñ╛ αñ╣αñ╛αñ▓αñ┐αñ»αñ╛ αñ╣αñ«αñ▓αÑïαñé αñ╕αÑç αñòαÑìαñ╖αÑçαññαÑìαñ░ αñ«αÑçαñé αñ¼αñíαñ╝αÑç αñ»αÑüαñªαÑìαñº αñòαñ╛ αñûαññαñ░αñ╛ αñ¼αñóαñ╝ αñùαñ»αñ╛ αñ╣αÑêαÑñ\n5:46\n5 minutes, 46 seconds\nαñêαñ░αñ╛αñ¿ αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñ¬αñ░αñ«αñ╛αñúαÑü αñ╡αñ╛αñ░αÑìαññαñ╛ αñ«αÑçαñé αñ¿αñ»αñ╛ αñ¬αÑçαñ£ αñ½αñéαñ╕αñ╛ αñ╣αÑüαñå αñ╣αÑêαÑñ αñêαñ░αñ╛αñ¿αÑÇ αñàαñ½αñ╕αñ░αÑïαñé αñ¿αÑç αñíαÑìαñ░αñ╛αñ½αÑìαñƒ αñ«αÑçαñ«αÑïαñ░αÑçαñéαñíαñ« αñ«αÑçαñé αñòαñ┐αñÅ αñùαñÅ αñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñ¼αñªαñ▓αñ╛αñ╡αÑïαñé αñòαÑï αñ¿αñ╛αñ«αñéαñ£αÑéαñ░ αñòαñ░ αñªαñ┐αñ»αñ╛ αñ╣αÑêαÑñ αñòαñ╣αñ╛ αñ╣αÑê αñòαñ┐ αñ½αÑìαñ░αÑÇ\n5:55\n5 minutes, 55 seconds\nαñ╕αñéαñ¬αññαÑìαññαñ┐αñ»αñ╛αñé αñ£αñ╛αñ░αÑÇ αñ╣αÑïαñ¿αÑç αñöαñ░ αñ¬αÑìαñ░αññαñ┐αñ¼αñéαñº αñ╣αñƒαñ¿αÑç αññαñò αñòαÑïαñê αñ╕αñ«αñ¥αÑîαññαñ╛ αñ╕αñéαñ¡αñ╡ αñ¿αñ╣αÑÇαñéαÑñ\n6:02\n6 minutes, 2 seconds\nαñêαñ░αñ╛αñ¿ αñòαÑÇ αñ╕αñ░αñòαñ╛αñ░αÑÇ αñÅαñ£αÑçαñéαñ╕αÑÇ αñ¿αÑç αñ£αñ╛αñ░αÑÇ αñòαñ┐αñ»αñ╛ αñ╣αÑëαñ░αÑìαñ«αÑéαñ╕ αñ½αÑêαñòαÑìαñƒ αñ¿αÑçαÑñ αñàαñ¡αÑÇ αñ£αÑï αñ╡αÑÇαñíαñ┐αñ»αÑï αñ«αÑçαñé αñªαñ╛αñ╡αñ╛ αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛ αñòαñ┐ αñ╣αÑëαñ░αÑìαñ«αÑéαñ╕ αñ¬αñ░ αñ½αñ┐αñ▓αñ╣αñ╛αñ▓ αñêαñ░αñ╛αñ¿ αñòαñ╛ αñ¿αñ┐αñ»αñéαññαÑìαñ░αñú αñ╣αÑêαÑñ αñ╕αÑêαñ¿αÑìαñ» αñ«αñéαñ£αÑéαñ░αÑÇ αñòαÑç αñ¼αñùαÑêαñ░ αñ£αñ╣αñ╛αñ£αÑïαñé αñòαÑÇ αñåαñ╡αñ╛αñ£αñ╛αñ╣αÑÇ αñ╕αñéαñ¡αñ╡ αñ¿αñ╣αÑÇαñéαÑñ\n6:14\n6 minutes, 14 seconds\nαñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑç αñ¬αÑìαñ░αñºαñ╛αñ¿αñ«αñéαññαÑìαñ░αÑÇ αñ¿αññαñ¿ αñ»αñ╛αÑé αñòαñ╛ αñ¼αñ»αñ╛αñ¿αÑñ\n6:16\n6 minutes, 16 seconds\nαñòαñ╣αñ╛ αñ╣αñ┐αñ£αñ¼αÑüαñ▓αÑìαñ▓αñ╛ αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñ£αñ╛αñ░αÑÇ αñ╣αÑê αñçαñ£αñ░αñ▓αÑÇ αñ╕αÑçαñ¿αñ╛ αñòαñ╛ αñæαñ¬αñ░αÑçαñ╢αñ¿αÑñ αñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑï αñ╕αÑçαñ▓αÑìαñ½ αñíαñ┐αñ½αÑçαñéαñ╕ αñòαñ╛ αñ¬αÑéαñ░αñ╛ αñàαñºαñ┐αñòαñ╛αñ░ αñ╣αÑêαÑñ αñçαñ╕αñòαñ╛ αñ¬αÑéαñ░αÑÇ αññαñ░αñ╣ αñ╕αÑç αñòαñ░αÑçαñéαñùαÑç αñçαñ╕αÑìαññαÑçαñ«αñ╛αñ▓αÑñ\n6:27\n6 minutes, 27 seconds\nαñçαñéαñíαñ┐αñ»αñ╛ αñùαñáαñ¼αñéαñºαñ¿ αñòαÑÇ αñ¼αÑêαñáαñò αñ«αÑçαñé αñ¬αñ╛αñéαñÜ αñ«αÑüαñªαÑìαñªαÑïαñé αñòαÑï αñëαñáαñ╛αñ¿αÑç αñ¬αñ░ αñ╕αñ╣αñ«αññαñ┐ αñ¼αñ¿ αñùαñê αñ╣αÑêαÑñ αñÅαñò αñ«αññ αñ╕αÑç αñ«αñ╛αñéαñùαñ╛ αñºαñ░αÑìαñ«αÑçαñéαñªαÑìαñ░ αñ¬αÑìαñ░αñºαñ╛αñ¿ αñòαñ╛ αñçαñ╕αÑìαññαÑÇαñ½αñ╛αÑñ αñÜαÑÇαñ½ αñ£αñ╕αÑìαñƒαñ┐αñ╕ αñòαÑï αñÅαñ╕αñåαñêαñåαñ░ αñÜαÑüαñ¿αñ╛αñ╡ αñ«αÑçαñé αñ╡αÑïαñƒ αñòαÑÇ αñ▓αÑéαñƒ αñöαñ░ αñÜαÑïαñ░αÑÇ αñòαÑç αñ«αÑüαñªαÑìαñªαÑç αñ¬αñ░ αñ▓αñ┐αñûαñ╛ αñ£αñ╛αñÅαñùαñ╛ αñ▓αÑçαñƒαñ░αÑñ\n6:41\n6 minutes, 41 seconds\nαñçαñéαñíαñ┐αñ»αñ╛ αñùαñáαñ¼αñéαñºαñ¿ αñòαÑÇ αñ¼αÑêαñáαñò αñ«αÑçαñé αñ░αñ╛αñ╣αÑüαñ▓ αñùαñ╛αñéαñºαÑÇ αñ¿αÑç αñòαñ╣αñ╛ αñ╕αñ░αñòαñ╛αñ░ αñòαÑÇ αñ╡αñ┐αñªαÑçαñ╢ αñ¿αÑÇαññαñ┐ αñ½αÑçαñ▓ αñ╣αÑüαñêαÑñ αñ¬αñ╢αÑìαñÜαñ┐αñ« αñÅαñ╢αñ┐αñ»αñ╛ αñ╕αñéαñòαñƒ αñ¬αñ░ αñ╕αñ░αñòαñ╛αñ░ αñòαñ╛ αñ░αÑüαñû αñ╕αñ╛αñ½ αñ¿αñ╣αÑÇαñé αñ░αñ╣αñ╛αÑñ\n6:50\n6 minutes, 50 seconds\nαñ¼αÑçαñ░αÑïαñ£αñùαñ╛αñ░αÑÇ, αñ«αñ╣αñéαñùαñ╛αñê αñöαñ░ αñ£αñ¿ αñ╕αñ░αÑïαñòαñ╛αñ░αÑïαñé αñ╕αÑç αñ£αÑüαñíαñ╝αÑç αñ«αÑüαñªαÑìαñªαÑïαñé αñ¬αñ░ αñ╕αñ░αÑìαñ╡αñªαñ▓αÑÇαñ» αñ¼αÑêαñáαñò αñ¼αÑüαñ▓αñ╛αñ¿αÑç αñòαÑÇ αñ«αñ╛αñéαñù αñòαÑÇ αñ£αñ╛ αñ░αñ╣αÑÇ αñ╣αÑêαÑñ αñ╣αñ░ αñªαÑï αñ«αñ╣αÑÇαñ¿αÑç αñ¬αñ░ αñ╣αÑïαñùαÑÇ\n6:58\n6 minutes, 58 seconds\nαñçαñéαñíαñ┐αñ»αñ╛ αñùαñáαñ¼αñéαñºαñ¿ αñòαÑÇ αñ»αñ╣ αñ¼αÑêαñáαñòαÑñ αñ╣αÑêαñªαñ░αñ╛αñ¼αñ╛αñª αñ«αÑçαñé αñàαñùαñ▓αÑÇ αñ«αÑÇαñƒαñ┐αñéαñù αñòαñ╛ αñ¬αÑìαñ▓αñ╛αñ¿ αñ╣αÑêαÑñ\n7:04\n7 minutes, 4 seconds\nαñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñòαñ╛ αñçαñéαñíαñ┐αñ»αñ╛ αñùαñáαñ¼αñéαñºαñ¿ αñ¬αñ▓αñƒαñ╡αñ╛αñ░αÑñ αñàαñ«αñ┐αññ αñ¬αñ╛αñ£αñ╡αñ╛ αñ¿αÑç αñ╡αñ┐αñ¬αñòαÑìαñ╖αÑÇ αñªαñ▓αÑïαñé αñòαÑÇ αñÅαñòαñ£αÑüαñƒαññαñ╛ αñöαñ░ αñ░αñ╛αñ£αñ¿αÑÇαññαñ┐αñò αñ╕αÑìαñÑαñ┐αññαñ┐ αñ¬αñ░ αñ╕αñ╡αñ╛αñ▓ αñëαñáαñ╛αñÅαÑñ αñòαñ╣αñ╛ αñ╡αÑïαñƒ αñ¿αñ╣αÑÇαñé αñçαñéαñíαñ┐αñ»αñ╛ αñùαñáαñ¼αñéαñºαñ¿ αñòαñ╛ αñ╡αñ£αÑéαñª αñÜαÑïαñ░αÑÇ αñ╣αÑüαñåαÑñ\n7:16\n7 minutes, 16 seconds\nαñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñ¿αÑçαññαñ╛ αñ╕αñéαñ¼αñ┐αññ αñ¬αñ╛αññαÑìαñ░αñ╛ αñ¿αÑç αñòαñ╣αñ╛ αñòαÑçαñ░αñ▓ αñ«αÑçαñé αñ╕αñ░αñòαñ╛αñ░ αñ¼αñ¿ αñùαñê αññαÑï αñÅαñ╕αñåαñêαñåαñ░ αñòαÑï αñ¿αñ╣αÑÇαñé αñòαÑïαñ╕ αñ░αñ╣αÑçαÑñ αñ¼αñéαñùαñ╛αñ▓ αñ«αÑçαñé αñ╣αñ╛αñ░αÑç αññαÑï αñÅαñ╕αñåαñêαñåαñ░ αñòαÑï αñªαÑïαñ╖ αñªαÑç αñ░αñ╣αÑçαÑñ\n7:27\n7 minutes, 27 seconds\nαñ╕αñéαñ¼αñ┐αññ αñ¬αñ╛αññαÑìαñ░αñ╛ αñòαÑç αñ¼αñ»αñ╛αñ¿ αñ¬αñ░ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñ¿αÑçαññαñ╛ αñ¡αÑéαñ¬αÑçαñ╢ αñ¼αñÿαÑçαñ▓ αñ¿αÑç αñòαñ╣αñ╛ αññαÑçαñ▓ αñùαÑêαñ╕ αñòαÑÇ αñ¼αñóαñ╝αññαÑÇ αñòαÑÇαñ«αññαÑïαñé, αñ¼αñ┐αñ£αñ▓αÑÇ αñòαÑÇ αñòαñƒαÑîαññαÑÇ αñ¬αñ░ αñºαÑìαñ»αñ╛αñ¿ αñªαÑçαñéαÑñ\n7:33\n7 minutes, 33 seconds\nαñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñ¿αñ╣αÑÇαñé αñòαñ░αñ╡αñ╛ αñ¬αñ╛ αñ░αñ╣αÑÇ αñ╣αÑê αñÅαñò αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛αÑñ\n7:39\n7 minutes, 39 seconds\nαñçαñéαñíαñ┐αñ»αñ╛ αñùαñáαñ¼αñéαñºαñ¿ αñòαÑÇ αñ¼αÑêαñáαñò αñòαÑç αñ¼αñ╛αñª αñ¼αÑïαñ▓αÑç αñ╕αÑÇαñ¬αÑÇαñåαñêαñÅαñ« αñòαÑç αñ¿αÑçαññαñ╛ αñªαÑÇαñ¬αñ╛αñéαñò αñ¡αñƒαÑìαñƒαñ╛αñÜαñ╛αñ░αÑìαñ»αÑñ αñ╕αñéαñ╕αñª αñ╕αÑç αñ╕αñíαñ╝αñò αññαñò αñëαñáαñ╛αñ¿αÑç αñ╣αÑêαñé αñ«αÑüαñªαÑìαñªαÑçαÑñ αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ«αÑçαñé αñƒαÑéαñƒ αñ¬αñ░ αñòαñ╣αñ╛ αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñòαñ╛ αñòαñ╛αñ« αñ╣αÑê αññαÑïαñíαñ╝αñ¿αÑç αñòαñ╛αÑñ\n7:52\n7 minutes, 52 seconds\nαñ╢αñ┐αñ╡αñ╕αÑçαñ¿αñ╛ αñëαñªαÑìαñºαñ╡ αñùαÑüαñá αñòαÑç αñ¿αÑçαññαñ╛ αñ╕αñéαñ£αñ» αñ░αñ╛αñëαññ αñ¿αÑç αñòαñ╣αñ╛ αñ£αÑÇαñÅαñ«αñ¬αÑÇ αñòαñ╛ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñ╕αÑç αñùαñáαñ¼αñéαñºαñ¿ αñƒαÑéαñƒαñ╛ αñ▓αÑçαñòαñ┐αñ¿ αñ╡αÑï αñ¼αñ¿ αñ╕αñòαññαÑÇ αñ╣αÑê αñùαñáαñ¼αñéαñºαñ¿ αñòαÑÇ αñ╕αñªαñ╕αÑìαñ»αÑñ\n7:59\n7 minutes, 59 seconds\nαñëαñªαÑìαñºαñ╡ αñ¿αÑç αñªαñ┐αñ»αñ╛ αñùαñáαñ¼αñéαñºαñ¿ αñòαñ╛ αñ¬αÑÇαñÅαñ« αñÜαÑçαñ╣αñ░αñ╛ αñÿαÑïαñ╖αñ┐αññ αñòαñ░αñ¿αÑç αñòαñ╛ αñ╕αÑüαñ¥αñ╛αñ╡αÑñ\n8:05\n8 minutes, 5 seconds\nαñòαÑçαñéαñªαÑìαñ░αÑÇαñ» αñ«αñéαññαÑìαñ░αÑÇ αñùαñ┐αñ░αñ┐αñ░αñ╛αñ£ αñ╕αñ┐αñéαñ╣ αñ¿αÑç αñ╡αñ┐αñ¬αñòαÑìαñ╖αÑÇ αñ¿αÑçαññαñ╛αñôαñé αñ¬αñ░ αñ╕αñ╛αñºαñ╛ αñ¿αñ┐αñ╢αñ╛αñ¿αñ╛αÑñ αñòαñ╣αñ╛ αñ»αñ╣ αñ╡αñéαñ╢αñ░αñ╛αñ£ αñòαÑÇ αñ¬αÑïαñ╖αñò αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñàαñòαÑçαñ▓αÑç αñ¿αñ╣αÑÇαñé αñòαñ░ αñ╕αñòαññαÑÇ αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñòαñ╛ αñ«αÑüαñòαñ╛αñ¼αñ▓αñ╛αÑñ\n8:16\n8 minutes, 16 seconds\nαñ¬αñ░αñ┐αñ«αñ▓ αñ¿αñ╛αñÑαñ╡αñ╛αñ¿αÑÇ αñòαÑÇ αñëαñ«αÑìαñ«αÑÇαñªαñ╡αñ╛αñ░αÑÇ αñ¬αñ░ αñ£αÑçαñÅαñ«αñÅαñ« αñ¿αÑç αñ▓αÑÇ αñÜαÑüαñƒαñòαÑÇαÑñ αñòαñ╣αñ╛ αñòαñ┐ αñçαññαñ¿αÑÇ αñ¼αñíαñ╝αÑÇ-αñ¼αñíαñ╝αÑÇ αñ¼αñ╛αññαÑçαñé αñöαñ░ αñƒαñ┐αñòαñƒ αñ¼αÑçαñÜ αñªαñ┐αñ»αñ╛ αñòαñ« αñ╕αÑç αñòαñ« αñ╢αÑéαñ¿αÑìαñ» αñ╡αñ╛αñ▓αÑç αñòαÑï αñªαÑç αñªαÑçαÑñ\n8:28\n8 minutes, 28 seconds\nαñ░αñ╛αñ£αÑìαñ»αñ╕αñ¡αñ╛ αñÜαÑüαñ¿αñ╛αñ╡ αñòαÑï αñ▓αÑçαñòαñ░ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñ¡αÑÇ αñ╣αñ«αñ▓αñ╛αñ╡αñ░ αñ╣αÑêαÑñ αñ¬αñ╡αñ¿ αñûαÑçαñíαñ╝αñ╛ αñ¿αÑç αñòαñ╣αñ╛ αñ╕αñéαñûαÑìαñ»αñ╛ αñ¼αñ▓ αñ¿αñ╣αÑÇαñé αñ╣αÑïαññαÑç αñ╣αÑüαñÅ αñ¡αÑÇ αñ¥αñ╛αñ░αñûαñéαñí αñöαñ░ αñ«αñºαÑìαñ» αñ¬αÑìαñ░αñªαÑçαñ╢ αñ«αÑçαñé αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñ¿αÑç αñûαñíαñ╝αÑç αñòαñ┐αñÅ αñëαñ«αÑìαñ«αÑÇαñªαñ╡αñ╛αñ░αÑñ αñûαñ░αÑÇαñª αÑ₧αñ░αÑïαñûαÑìαññ αñòαÑÇ αñ«αñéαñ╢αñ╛ αñ╣αÑïαñ¿αÑç αñòαñ╛ αñ¡αÑÇ αñªαñ╛αñ╡αñ╛ αñòαñ┐αñ»αñ╛αÑñ\n8:41\n8 minutes, 41 seconds\nαñÅαñ¿αñ╕αÑÇαñ¬αÑÇ αñòαÑç 27αñ╡αÑçαñé αñ╕αÑìαñÑαñ╛αñ¬αñ¿αñ╛ αñªαñ┐αñ╡αñ╕ αñòαñ╛αñ░αÑìαñ»αñòαÑìαñ░αñ« αñ«αÑçαñé αñ¼αñªαñ▓αñ╛αñ╡αÑñ αñ╕αÑüαñ¿αÑÇαñ▓ αññαñƒαñòαñ░αÑÇ αñ¿αÑç αñòαñ╣αñ╛ 11 αñ£αÑéαñ¿ αñòαÑï αñ╣αÑïαñùαñ╛ αñåαñ»αÑïαñ£αñ┐αññ 10 αñ£αÑéαñ¿ αñòαÑï αñªαñ┐αñ▓αÑìαñ▓αÑÇ αñ«αÑçαñé αñ¬αÑÇαñÅαñ« αñ«αÑïαñªαÑÇ αñ¿αÑç αñ¼αÑüαñ▓αñ╛αñê αñ╣αÑê αñÅαñ¿αñíαÑÇαñÅ αñòαÑÇ αñ«αÑÇαñƒαñ┐αñéαñùαÑñ\n8:52\n8 minutes, 52 seconds\nαñ»αÑéαñ¬αÑÇ αñòαÑç αñ╢αñ╛αñ╣αñ£αñ╣αñ╛αñéαñ¬αÑüαñ░ αñ«αÑçαñé αñòαñ░αñúαÑÇ αñ╕αÑçαñ¿αñ╛ αñòαÑç αñàαñºαÑìαñ»αñòαÑìαñ╖ αñòαñ╛ αñÉαñ▓αñ╛αñ¿αÑñ αñòαñ╣αñ╛ αñòαñ┐ αñ«αñ╛αñéαñùαÑç αñ¿αñ╣αÑÇαñé αñ«αñ╛αñ¿αÑÇ αñùαñê αññαÑï 50 αñ╕αÑÇαñƒαÑïαñé αñ¬αñ░ αñ▓αñíαñ╝αÑçαñéαñùαÑç αñÜαÑüαñ¿αñ╛αñ╡αÑñ αñ«αñ╛αñéαñùαÑïαñé αñ«αÑçαñé αñ»αÑéαñ¬αÑÇ αñ«αÑçαñé αñ»αÑéαñ╕αÑÇαñ╕αÑÇ αñ▓αñ╛αñùαÑé αñòαñ░αñ¿αÑç αñòαÑÇ αñ¡αÑÇ αñ«αñ╛αñéαñù αñ╢αñ╛αñ«αñ┐αñ▓ αñ╣αÑêαÑñ\n9:05\n9 minutes, 5 seconds\nαñåαñ░αñ£αÑçαñíαÑÇ αñòαÑç αñÅαñ╕αñ╕αÑÇ αñÅαñ╕αñƒαÑÇ αñòαÑç αñàαñºαÑìαñ»αñòαÑìαñ╖ αñ¬αñª αñ╕αÑç αñ╢αñ┐αñ╡αñÜαñéαñªαÑìαñ░ αñ░αñ╛αñ« αñòαñ╛ αñçαñ╕αÑìαññαÑÇαñ½αñ╛αÑñ αñ¬αÑìαñ░αÑçαñ╕ αñòαÑëαñ¿αÑìαñ½αÑìαñ░αÑçαñéαñ╕ αñ«αÑçαñé αñ░αÑï αñ¬αñíαñ╝αÑç αñ¬αÑéαñ░αÑìαñ╡ αñ«αñéαññαÑìαñ░αÑÇ αñöαñ░ αñåαñ░αñ£αÑçαñíαÑÇ αñòαÑç αñ¿αÑçαññαñ╛αÑñ αñÅαñ«αñÅαñ▓αñ╕αÑÇ αñëαñ«αÑìαñ«αÑÇαñªαñ╡αñ╛αñ░ αñ¿αñ╣αÑÇαñé αñ¼αñ¿αñ╛αñÅ αñ£αñ╛αñ¿αÑç αñ╕αÑç αñ¿αñ╛αñ░αñ╛αñ£ αñ╣αÑêαñéαÑñ\n9:17\n9 minutes, 17 seconds\nαñ▓αñ╛αñ▓αÑé αñòαÑÇ αñ¼αÑçαñƒαÑÇ αñ░αÑïαñ╣αñ┐αñúαÑÇ αñåαñÜαñ╛αñ░αÑìαñ» αñ¿αÑç αñ¡αÑÇ αñ╕αÑüαñ¿αÑÇαñ▓ αñ╕αñ┐αñéαñ╣ αñòαÑï αñ▓αÑçαñòαñ░ αñ¿αñ╛αñ░αñ╛αñ£αñùαÑÇ αñ╡αÑìαñ»αñòαÑìαññ αñòαÑÇαÑñ αñòαñ╣αñ╛ αñëαñùαñ╛αñ╣αÑÇ αñöαñ░ αñ╡αñ╕αÑéαñ▓αÑÇ αñòαñ░αñ¿αÑç αñ╡αñ╛αñ▓αÑçαÑñ αñ¼αñ╣αñ¿ αñ¼αÑçαñƒαñ┐αñ»αÑïαñé αñòαÑç αñ¼αñ╛αñ░αÑç αñ«αÑçαñé αñôαñ¢αÑÇ αñ¼αñ╛αññαÑçαñé αñòαñ░αñ¿αÑç αñ╡αñ╛αñ▓αÑç αñòαÑï αñòαÑêαñ╕αÑç αñ¼αñ¿αñ╛ αñªαñ┐αñ»αñ╛ αñùαñ»αñ╛ αñ¬αÑìαñ░αññαÑìαñ»αñ╛αñ╢αÑÇαÑñ\n9:30\n9 minutes, 30 seconds\nαñàαñ¬αñ¿αÑç αñ¼αÑçαñƒαÑç αñªαÑÇαñ¬αñò αñ¬αÑìαñ░αñòαñ╛αñ╢ αñòαÑï αñÅαñ«αñÅαñ▓αñ╕αÑÇ αñ¿αñ╣αÑÇαñé αñ¼αñ¿αñ╛αñÅ αñ£αñ╛αñ¿αÑç αñòαÑç αñ╕αñ╡αñ╛αñ▓ αñ¬αñ░ αñëαñ¬αÑçαñéαñªαÑìαñ░ αñòαÑüαñ╢αñ╡αñ╛αñ╣αñ╛ αñ¼αÑïαñ▓αÑç αñ£αñ¼ αññαñò αñòαÑç αñ▓αñ┐αñÅ αñ▓αÑïαñùαÑïαñé αñ¿αÑç αñ¼αñ¿αñ╛αñ»αñ╛ αñ«αñéαññαÑìαñ░αÑÇ\n9:37\n9 minutes, 37 seconds\nαññαñ¼ αññαñò αñ░αñ╣αÑçαñéαñùαÑç αñªαÑÇαñ¬αñò αñ¬αÑìαñ░αñòαñ╛αñ╢ αñ¼αñ¿αÑç αñ░αñ╣αÑçαñéαñùαÑç αñÅαñ¿αñíαÑÇαñÅ αñòαÑç αñ╕αñ╛αñÑαÑñ\n9:43\n9 minutes, 43 seconds\nαñÅαñ▓αñ£αÑçαñ¬αÑÇαñåαñ░ αñ╕αñ╛αñéαñ╕αñª αñàαñ░αÑüαñú αñ¡αñ╛αñ░αññαÑÇ αñ¿αÑç αñòαñ╣αñ╛ αñùαñáαñ¼αñéαñºαñ¿ αñ«αÑçαñé αñ╕αñ¡αÑÇ αñòαÑï αñ░αñûαñ¿αñ╛ αñ¬αñíαñ╝αññαñ╛ αñ╣αÑê αñ¼αñíαñ╝αñ╛ αñªαñ┐αñ▓αÑñ αñ╣αñ░ αñªαñ┐αñ▓ αñòαÑï αñ╕αñ¼ αñòαÑüαñ¢ αñ«αñ┐αñ▓αññαñ╛ αñ¿αñ╣αÑÇαñé αñ╣αÑêαÑñ\n9:53\n9 minutes, 53 seconds\nαñëαñ¬αÑçαñéαñªαÑìαñ░ αñòαÑüαñ╢αñ╡αñ╛αñ╣αñ╛ αñòαÑç αñ¼αÑçαñƒαÑç αñòαÑç αñ«αñéαññαÑìαñ░αÑÇ αñ¼αñ¿αÑç αñ░αñ╣αñ¿αÑç αñòαÑï αñÜαñ┐αñ░αñ╛αñù αñ¬αñ╛αñ╕αñ╡αñ╛αñ¿ αñ¿αÑç αñ¼αññαñ╛αñ»αñ╛ αñ╕αñéαñ╡αÑêαñºαñ╛αñ¿αñ┐αñò αñûαññαñ░αñ╛αÑñ αññαÑçαñ▓ αñùαÑêαñ╕ αñòαÑç αñªαñ╛αñ« αñ¼αñóαñ╝αñ╛αñ¿αÑç αñ¬αñ░ αñòαñ╣αñ╛ αñòαñ┐ αñªαÑçαñ╢ αñòαÑï αñ╕αñéαñòαñƒ αñ╕αÑç αñ¼αñÜαñ╛αñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ αñòαÑÇαñ«αññαÑçαñé αñ¼αñóαñ╝αñ╛αñê αñùαñê αñ╣αÑêαÑñ\n10:05\n10 minutes, 5 seconds\nαñÅαñ╕αñåαñêαñåαñ░ αñòαÑï αñ▓αÑçαñòαñ░ αñ¼αÑïαñ▓αÑç αñàαñ╕αñªαÑüαñªαÑìαñªαÑÇαñ¿ αñôαñ╡αÑêαñ╕αÑÇ αñ╣αñ«αÑçαñé αñ»αñ╣ αñ¬αñòαÑìαñòαñ╛ αñòαñ░αñ¿αñ╛ αñ╣αÑïαñùαñ╛ αñòαñ┐ αñ▓αñ┐αñ╕αÑìαñƒ αñ«αÑçαñé αñ╢αñ╛αñ«αñ┐αñ▓ αñ╣αÑï αñ╣αñ«αñ╛αñ░αÑç αñ░αñ╛αñ£αñ¿αÑÇαññαñ┐αñò αñ╡αñ┐αñ░αÑïαñºαÑÇ αñòαÑç αñ¡αÑÇ αñ¿αñ╛αñ«αÑñ αñ¼αñéαñùαñ╛αñ▓\n10:12\n10 minutes, 12 seconds\nαñ«αÑçαñé αñªαÑçαñûαñ┐αñÅ αñòαÑêαñ╕αÑç αñ░αñªαÑìαñª αñ╣αÑï αñ░αñ╣αÑç αñ╣αÑêαñé αñ░αñ╛αñ╢αñ¿ αñòαñ╛αñ░αÑìαñíαÑìαñ╕ αñöαñ░ αñ¬αÑçαñéαñ╢αñ¿αÑñ\n10:19\n10 minutes, 19 seconds\nαñåαñ£ αñ▓αÑêαñéαñí αñ¬αÑïαñ░αÑìαñƒ αñ«αÑêαñ¿αÑçαñ£αñ«αÑçαñéαñƒ αñ╕αñ┐αñ╕αÑìαñƒαñ« αñòαñ╛ αñ╢αÑüαñ¡αñ╛αñ░αñéαñ¡αÑñ αñòαÑçαñéαñªαÑìαñ░αÑÇαñ» αñùαÑâαñ╣ αñ«αñéαññαÑìαñ░αÑÇ αñàαñ«αñ┐αññ αñ╢αñ╛αñ╣ αñëαñªαÑìαñÿαñ╛αñƒαñ¿ αñòαñ░αÑçαñéαñùαÑçαÑñ αñ╕αÑÇαñ«αñ╛ αñ¬αñ╛αñ░ αñ╡αÑìαñ»αñ╛αñ¬αñ╛αñ░ αñ»αñ╛αññαÑìαñ░αñ┐αñ»αÑïαñé αñòαÑÇ αñåαñ╡αñ╛αñ£αñ╛αñ╣αÑÇ αñåαñ╕αñ╛αñ¿ αñ╣αÑïαñùαÑÇ αñöαñ░ αñ╕αÑüαñ░αñòαÑìαñ╖αñ┐αññαÑñ\n10:32\n10 minutes, 32 seconds\nαñ╕αñÜαñ┐αñ¿ αñ¬αñ╛αñ»αñ▓αñƒ αñòαÑÇ αñ¬αÑìαñ░αñªαÑçαñ╢ αñàαñºαÑìαñ»αñòαÑìαñ╖ αñ¼αñ¿αñ¿αÑç αñòαÑÇ αñûαñ¼αñ░αÑïαñé αñòαÑç αñ¼αÑÇαñÜ αñùαñ╣αñ▓αÑïαññ αñòαÑÇ αñåαñòαÑìαñ░αñ╛αñ«αñò αññαÑçαñ╡αñ░αÑñ\n10:35\n10 minutes, 35 seconds\nαñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñ¿αÑç αñ╕αñ╛αñºαÑÇ αñÜαÑüαñ¬αÑìαñ¬αÑÇαÑñ αñ╕αñ╡αñ╛αñ▓ αñ╕αÑç αñ¼αñÜαññαÑç αñ╣αÑüαñÅ αñ¿αñ£αñ░ αñåαñÅ αñçαñ╕ αñ░αñ╛αñ£αñ╕αÑìαñÑαñ╛αñ¿ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñ¬αÑìαñ░αñªαÑçαñ╢ αñàαñºαÑìαñ»αñòαÑìαñ╖αÑñ\n10:43\n10 minutes, 43 seconds\nαñùαñ╣αñ▓αÑïαññ αñòαÑç αñ¼αñ»αñ╛αñ¿ αñ¬αñ░ αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñ¿αÑç αñ╕αñÜαñ┐αñ¿ αñ¬αñ╛αñ»αñ▓αñƒ αñ╕αÑç αñ╣αñ«αñªαñ░αÑìαñªαÑÇ αñ£αññαñ╛αñêαÑñ αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñ¿αÑçαññαñ╛ αñ╕αñéαñ¼αñ┐αññ αñ¬αñ╛αññαÑìαñ░αñ╛ αñ¼αÑïαñ▓αÑç αñ½αñ░αñùαÑç αñòαÑï αñòαÑìαñ»αñ╛-αñòαÑìαñ»αñ╛ αñ╕αÑüαñ¿αñ╛ αñ░αñ╣αÑç αñ╣αÑêαñé αñàαñ╢αÑïαñò αñùαñ╣αñ▓αÑïαññ?\n10:54\n10 minutes, 54 seconds\nαñºαÑÇαñ░αÑçαñéαñªαÑìαñ░ αñ╢αñ╛αñ╕αÑìαññαÑìαñ░αÑÇ αñòαÑï αñ«αñ┐αñ▓αñ╛ αñ░αñ╛αñ£αñ╕αÑìαñÑαñ╛αñ¿ αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñòαÑç αñ╡αñ┐αñºαñ╛αñ»αñò αñòαñ╛ αñ╕αñ╛αñÑαÑñ αñ¼αñ╛αñ▓αñ«αÑüαñòαÑüαñéαñª αñåαñÜαñ╛αñ░αÑìαñ» αñ¿αÑç αñ½αÑìαñ░αÑçαñéαñí αñ£αñ┐αñ╣αñ╛αñª αñ╡αñ╛αñ▓αÑç αñ¼αñ»αñ╛αñ¿ αñòαñ╛ αñ╕αñ«αñ░αÑìαñÑαñ¿ αñòαñ┐αñ»αñ╛αÑñ αñòαñ╣αñ╛ αñòαñ┐ αñ«αÑüαñùαñ▓αÑïαñé αñòαÑç αñ╕αñ«αñ» αñ╕αÑç αñ»αñ╣ αñ½αÑìαñ░αÑçαñéαñí αñ£αñ┐αñ╣αñ╛αñª αñòαñ╛ αñòαñ╛αñ« αñ╣αÑï αñ░αñ╣αñ╛ αñ╣αÑêαÑñ\n11:07\n11 minutes, 7 seconds\nαñàαñûαñ┐αñ▓αÑçαñ╢ αñ»αñ╛αñªαñ╡ αñ¬αñ░ αñ»αÑéαñ¬αÑÇ αñòαÑç αñíαÑçαñ¬αÑüαñƒαÑÇ αñ╕αÑÇαñÅαñ« αñ¼αÑâαñ£αÑçαñ╢ αñ¬αñ╛αñáαñò αñòαñ╛ αñ¿αñ┐αñ╢αñ╛αñ¿αñ╛αÑñ αñòαñ╣αñ╛ αñ¼αñ╛αñ¼αñ░αñ╡αñ╛αñªαÑÇ αñ╣αÑê αñ╕αÑïαñÜαÑñ\n11:13\n11 minutes, 13 seconds\n2027 αñ«αÑçαñé αñ╕αñ«αñ╛αñ£αñ╡αñ╛αñªαÑÇ αñ¬αñ╛αñ░αÑìαñƒαÑÇ αñòαÑï αñ«αñ┐αñ▓αÑçαñùαÑÇ αñ╣αñ╛αñ░αÑñ\n11:18\n11 minutes, 18 seconds\nαñ░αñ╛αñ« αñ«αñéαñªαñ┐αñ░ αñòαÑç αñÜαñóαñ╝αñ╛αñ╡αÑç αñ¬αñ░ αñ╕αñ┐αñ»αñ╛αñ╕αÑÇ αñÿαñ«αñ╛αñ╕αñ╛αñ¿ αñ£αñ╛αñ░αÑÇαÑñ αñåαñ« αñåαñªαñ«αÑÇ αñ¬αñ╛αñ░αÑìαñƒαÑÇ αñòαÑç αñ╕αñ╛αñéαñ╕αñª αñ╕αñéαñ£αñ» αñ╕αñ┐αñéαñ╣ αñ¿αÑç αñ▓αñùαñ╛αñ»αñ╛ αñÜαÑïαñ░αÑÇ αñòαñ╛ αñåαñ░αÑïαñ¬αÑñ αñòαñ╣αñ╛ αñÜαñéαñªαñ╛ αñÜαÑïαñ░ αñùαñªαÑìαñªαÑÇ αñ¢αÑïαñíαñ╝αÑçαÑñ\n11:29\n11 minutes, 29 seconds\nαñàαñûαñ┐αñ▓αÑçαñ╢ αñ»αñ╛αñªαñ╡ αñ¬αñ░ αñôαñ¬αÑÇ αñ░αñ╛αñ£αñ¡αñ░ αñ¿αÑç αñ▓αñùαñ╛αñ»αñ╛ αñùαÑüαñ«αñ░αñ╛αñ╣ αñòαñ░αñ¿αÑç αñòαñ╛ αñåαñ░αÑïαñ¬αÑñ αñòαñ╣αñ╛ αñòαñ┐ αñàαñûαñ┐αñ▓αÑçαñ╢ αñòαÑìαñ»αñ╛ αñòαñ¡αÑÇ αñùαñÅ αñ╣αÑêαñé αñàαñ»αÑïαñºαÑìαñ»αñ╛ αñòαÑç αñ░αñ╛αñ« αñ«αñéαñªαñ┐αñ░? αñ»αñ╣ αñ╕αñ¼ αñ¥αÑéαñá αñ¼αÑïαñ▓αñ¿αÑç αñ╡αñ╛αñ▓αÑç αñ▓αÑïαñù αñ╣αÑêαñéαÑñ\n11:40\n11 minutes, 40 seconds\nαñ░αñ╛αñ« αñ«αñéαñªαñ┐αñ░ αñòαÑç αñÜαñóαñ╝αñ╛αñ╡αÑç αñ╕αÑç αñ£αÑüαñíαñ╝αÑç αñàαñûαñ┐αñ▓αÑçαñ╢ αñòαÑç αñåαñ░αÑïαñ¬αÑïαñé αñ¬αñ░ αñ╕αñ┐αñ»αñ╛αñ╕αÑÇ αñÿαñ«αñ╛αñ╕αñ╛αñ¿ αñ£αñ╛αñ░αÑÇ αñ╣αÑêαÑñ\n11:44\n11 minutes, 44 seconds\nαñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñ¼αÑïαñ▓αÑÇ αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñöαñ░ αñåαñ░αñÅαñ╕αñÅαñ╕ αñºαñ░αÑìαñ« αñòαÑÇ αñåαñíαñ╝ αñ«αÑçαñé αñ¢αñ┐αñ¬αñòαñ░ αñ░αñ╛αñ£αñ¿αÑÇαññαñ┐ αñòαñ░αññαÑç αñ╣αÑêαñéαÑñ\n11:51\n11 minutes, 51 seconds\nαñàαñûαñ┐αñ▓αÑçαñ╢ αñ»αñ╛αñªαñ╡ αñ¿αÑç αñ╡αÑÇαñíαñ┐αñ»αÑï αñ¬αÑïαñ╕αÑìαñƒ αñòαñ░ αñ╕αÑÇαñÅαñ« αñ»αÑïαñùαÑÇ αñ╕αÑç αñ£αñ╡αñ╛αñ¼ αñ«αñ╛αñéαñùαñ╛αÑñ αñòαñ╣αñ╛ αñòαñ┐ αñªαÑï αñ╕αñ«αñ╛αñ£ αñòαñ╛ αñ╣αÑüαñå αñàαñ¬αñ«αñ╛αñ¿αÑñ αñàαñùαñ░ αñ╡αÑÇαñíαñ┐αñ»αÑï αñ╣αÑê αñ╕αñ╣αÑÇ αññαÑï αñ£αñ╡αñ╛αñ¼ αñªαÑçαñéαÑñ\n12:01\n12 minutes, 1 second\nαñ╡αñ╛αñ░αñ╛αñúαñ╕αÑÇ αñ«αÑçαñé αñàαñ¬αñ¿αÑÇ αñ╣αÑÇ αñ¬αñ╛αñ░αÑìαñƒαÑÇ αñòαÑç αñ╡αñ┐αñºαñ╛αñ»αñò αñ╕αÑç αñ¿αñ╛αñ░αñ╛αñ£ αñ¿αñ£αñ░ αñåαñÅ αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñ¬αñ╛αñ░αÑìαñ╖αñªαÑñ αñòαÑêαñ«αñ░αÑç αñ¬αñ░ αñ¡αñ╛αñ╡αÑüαñò αñ╣αÑüαñÅ αñ╕αñéαñ£αñ» αñùαÑüαñ£αñ░αñ╛αññαÑÇ αñ¿αÑç αñòαñ╣αñ╛ αñ╕αñéαñùαñáαñ¿ αññαñò αñ¬αñ╣αÑüαñéαñÜαñ╛αñèαñéαñùαñ╛ αñçαñ╕ αñ¼αñ╛αññ αñòαÑïαÑñ\n12:12\n12 minutes, 12 seconds\nαñªαñ┐αñ▓αÑìαñ▓αÑÇ αñ«αÑçαñé αñ¼αÑÇαñÅαñ╕αñÅαñ½ αñöαñ░ αñ¼αñ╛αñéαñùαÑìαñ▓αñ╛αñªαÑçαñ╢ αñ¼αÑëαñ░αÑìαñíαñ░ αñùαñ╛αñ░αÑìαñíαÑìαñ╕ αñòαÑÇ αñ¼αÑêαñáαñòαÑñ αñíαÑÇαñ£αÑÇ αñ╕αÑìαññαñ░ αñòαÑÇ αñ¼αñ╛αññαñÜαÑÇαññ αñòαÑç αñ¬αñ╣αñ▓αÑç αñªαñ┐αñ¿ αñ¡αñ╛αñ░αññ αñ¿αÑç αñëαñáαñ╛αñ»αñ╛ αñùαÑêαñ░αñòαñ╛αñ¿αÑéαñ¿αÑÇ αñÿαÑüαñ╕αñ¬αÑêαñá αñöαñ░ αñ¼αÑÇαñÅαñ╕αñÅαñ½ αñ£αñ╡αñ╛αñ¿αÑïαñé αñ¬αñ░ αñ╣αñ«αñ▓αÑç αñòαñ╛ αñ«αÑüαñªαÑìαñªαñ╛αÑñ\n12:24\n12 minutes, 24 seconds\nαñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ¬αññαñ┐ αñ¡αñ╡αñ¿ αñ«αÑçαñé αñåαñ»αÑïαñ£αñ┐αññ αñ░αñòαÑìαñ╖αñ╛ αñàαñ▓αñéαñòαñ░αñú αñ╕αñ«αñ╛αñ░αÑïαñ╣αÑñ αñ╡αÑÇαñ░αÑïαñé αñòαÑï αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ¬αññαñ┐ αñ¿αÑç αñ╡αÑÇαñ░ αñÜαñòαÑìαñ░ αñöαñ░ αñ╢αÑîαñ░αÑìαñ» αñÜαñòαÑìαñ░ αñ╕αÑç αñ¿αñ╡αñ╛αñ£αñ╛αÑñ αñ╢αñ╣αÑÇαñª αñ╕αÑêαñ¿αñ┐αñòαÑïαñé αñòαÑÇ αñ«αñ╛αñé αñòαÑï αñ╢αñ╛αñéαññαñ┐ αñ¼αñ¿αñ╛ αñªαÑÇαÑñ\n12:36\n12 minutes, 36 seconds\nαñ»αñ«αÑüαñ¿αñ╛ αñòαÑç αñòαñ╛αñ»αñ╛αñòαñ▓αÑìαñ¬ αñòαÑç αñ▓αñ┐αñÅ αñªαñ┐αñ▓αÑìαñ▓αÑÇ αñ«αÑçαñé αñòαÑçαñéαñªαÑìαñ░αÑÇαñ» αñùαÑâαñ╣ αñ«αñéαññαÑìαñ░αÑÇ αñàαñ«αñ┐αññ αñ╢αñ╛αñ╣ αñ¿αÑç αñ¼αÑêαñáαñò αñòαÑÇαÑñ αñªαñ┐αñ▓αÑìαñ▓αÑÇ αñòαÑç αñ╕αÑÇαñÅαñ« αñöαñ░ αñ░αñ╛αñ£αÑìαñ»αñ¬αñ╛αñ▓ αñ¡αÑÇ αñ╢αñ╛αñ«αñ┐αñ▓ αñ╣αÑüαñÅαÑñ αñòαñ╣αñ╛ αñ╕αñƒαÑÇαñò αñ¬αñ░αñ┐αñúαñ╛αñ« αñÜαñ╛αñ╣αñ┐αñÅαÑñ\n12:46\n12 minutes, 46 seconds\nαñªαñ┐αñ▓αÑìαñ▓αÑÇ αñ«αÑçαñé αñ»αñ«αÑüαñ¿αñ╛ αñÿαñ╛αñƒ αñ╕αñ½αñ╛αñê αñàαñ¡αñ┐αñ»αñ╛αñ¿αÑñ αñªαñ┐αñ▓αÑìαñ▓αÑÇ αñòαÑÇ αñ╕αÑÇαñÅαñ« αñ░αÑçαñûαñ╛ αñùαÑüαñ¬αÑìαññαñ╛ αñ¿αÑç αñòαÑÇ αñ▓αÑïαñùαÑïαñé αñ╕αÑç αñ£αÑüαñíαñ╝αñ¿αÑç αñòαÑÇ αñàαñ¬αÑÇαñ▓αÑñ αñòαñ╣αñ╛ αñòαÑüαñ¢ αñÿαñéαñƒαÑç αñªαÑçαñé αñöαñ░ αñ▓αñ╛αñÅαñé αñ¼αñªαñ▓αñ╛αñ╡αÑñ\n12:55\n12 minutes, 55 seconds\nαñåαñ£ αñ╣αÑïαñùαÑÇ αñ«αñ╣αñ╛αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░ αñòαÑêαñ¼αñ┐αñ¿αÑçαñƒ αñòαÑÇ αñàαñ╣αñ« αñ¼αÑêαñáαñòαÑñ\n12:57\n12 minutes, 57 seconds\nαñÅαñòαñ¿αñ╛αñÑ αñ╢αñ┐αñéαñª αñòαÑÇ αñ«αÑîαñ£αÑéαñªαñùαÑÇ αñ«αÑçαñé αñ»αñ╣ αñ«αÑîαñ£αÑéαñªαñùαÑÇ αñ¬αñ░ αñ╕αñ¡αÑÇ αñòαÑÇ αñ¿αñ£αñ░ αñ░αñ╣αÑçαñùαÑÇαÑñ αñ¬αñ┐αñ¢αñ▓αÑÇ αñ¼αÑêαñáαñò αñ«αÑçαñé αñ¿αñ╛αñ░αñ╛αñ£αñùαÑÇ αñòαÑÇ αñ╡αñ£αñ╣ αñ╕αÑç αñ╢αñ┐αñéαñª αñòαÑç αñ¿αñ╣αÑÇαñé αñ╢αñ╛αñ«αñ┐αñ▓ αñ╣αÑïαñ¿αÑç αñòαÑÇ αñûαñ¼αñ░ αñ╕αñ╛αñ«αñ¿αÑç αñåαñê αñÑαÑÇαÑñ\n13:08\n13 minutes, 8 seconds\nαñ╕αñ╡αñ╛αñ▓αÑïαñé αñ«αÑçαñé 10 αñ╕αñ╛αñ▓ αñòαÑç αñçαñéαññαñ£αñ╛αñ░ αñòαÑç αñ¼αñ╛αñª αñ¼αñ¿αñ╛ αñ«αÑüαñéαñ¼αñê αñ«αÑçαñé αñ½αÑìαñ▓αñ╛αñê αñôαñ╡αñ░ αñùαÑüαñúαñ╡αññαÑìαññαñ╛ αñöαñ░ αñ½αñ┐αñ¿αñ┐αñ╢αñ┐αñéαñù αñ¬αñ░ αñ╕αñ╡αñ╛αñ▓ αñëαñá αñ░αñ╣αÑç αñ╣αÑêαñéαÑñ αñ¼αÑÇαñÅαñÅαñ«αñ╕αÑÇ αñ¼αÑïαñ▓αÑÇ αñ½αÑìαñ▓αñ╛αñê αñôαñ╡αñ░ αñòαÑÇ αñùαÑüαñúαñ╡αññαÑìαññαñ╛ αñ╕αÑç αñ╕αñ«αñ¥αÑîαññαñ╛ αñ¿αñ╣αÑÇαñé αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛αÑñ\n13:21\n13 minutes, 21 seconds\nαñòαÑïαñÜαñ┐αñéαñù αñ╡αñ┐αñ╡αñ╛αñª αñ«αÑçαñé αñàαñ¼ αññαñò αñ¬αÑüαñ▓αñ┐αñ╕ αñòαÑÇ αñ¬αñòαñíαñ╝ αñ╕αÑç αñªαÑéαñ░ αñ╣αÑêαñé αñ½αÑêαñ£αñ▓ αñûαñ╛αñ¿αÑñ αñåαñ£ αñàαñùαÑìαñ░αñ┐αñ« αñ£αñ«αñ╛αñ¿αññ αñ»αñ╛αñÜαñ┐αñòαñ╛ αñ¬αñ░ αñ╣αÑïαñùαÑÇ αñ╕αÑüαñ¿αñ╡αñ╛αñêαÑñ 5 αñ£αÑéαñ¿ αñòαÑï αñ½αñ╛αñ»αñ░αñ┐αñéαñù αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñªαñ░αÑìαñ£ αñ╣αÑüαñê αñÑαÑÇ αñÅαñ½αñåαñêαñåαñ░αÑñ\n13:32\n13 minutes, 32 seconds\nαñ£αñ»αñ¬αÑüαñ░ αñ«αÑçαñé αñ¼αñ╣αñ╛αñ▓ αñòαÑÇ αñùαñê αñ╣αÑê αñçαñéαñƒαñ░αñ¿αÑçαñƒ αñ╕αÑçαñ╡αñ╛αÑñ αñ╕αÑïαñ«αñ╡αñ╛αñ░ αñ░αñ╛αññ 8:00 αñ¼αñ£αÑç αñ½αñ┐αñ░ αñ╕αÑç αñ╢αÑüαñ░αÑé αñ╣αÑüαñêαÑñ\n13:37\n13 minutes, 37 seconds\nαñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñ¿αÑç αñ¬αÑìαñ░αñ╢αñ╛αñ╕αñ¿ αñòαÑç αñ½αÑêαñ╕αñ▓αÑç αñ¬αñ░ αñ╕αñ╡αñ╛αñ▓ αñëαñáαñ╛αñÅαÑñ\n13:42\n13 minutes, 42 seconds\nαñ╣αñ╛αñ¬αÑüαñíαñ╝ αñ«αÑçαñé αñ¿αñ╡αñ╡αñ┐αñ╡αñ╛αñ╣αñ┐αññ αñòαÑÇ αñ╕αñéαñªαñ┐αñùαÑìαñº αñ╣αñ╛αñ▓αññ αñ«αÑçαñé αñ«αÑîαññ αñ╣αÑï αñùαñêαÑñ αñ«αñ╣αÑÇαñ¿αÑç αñ¡αñ░ αñ¬αñ╣αñ▓αÑç αñ╣αÑÇ αñ╢αñ╛αñªαÑÇ αñ╣αÑüαñê αñÑαÑÇαÑñ\n13:46\n13 minutes, 46 seconds\nαñ«αñ╛αñ»αñòαÑç αñ╡αñ╛αñ▓αÑç αñ¿αÑç αñ╕αñ╕αÑüαñ░αñ╛αñ▓ αñ╡αñ╛αñ▓αÑïαñé αñòαÑç αñèαñ¬αñ░ αñ£αññαñ╛αñ»αñ╛ αñ╣αÑê αñ╣αññαÑìαñ»αñ╛ αñòαñ╛ αñ╢αñòαÑñ αñ«αñ╛αñ«αñ▓αÑç αñòαÑÇ αñ¢αñ╛αñ¿αñ¼αÑÇαñ¿ αñòαñ░ αñ░αñ╣αÑÇ αñ╣αÑê αñ¬αÑüαñ▓αñ┐αñ╕αÑñ\n13:54\n13 minutes, 54 seconds\nαñ╣αÑêαñªαñ░αñ╛αñ¼αñ╛αñª αñòαÑç αñòαÑüαñòαñáαñ¬αñ▓αÑìαñ▓αÑÇ αñ«αÑçαñé αñ¬αñ¼ αñ¬αñ░ αñ¢αñ╛αñ¬αñ╛αñ«αñ╛αñ░ αñòαñ╛αñ░αñ╡αñ╛αñê αñ╣αÑüαñêαÑñ αñ¢αñ╛αñ¿αñ¼αÑÇαñ¿ αñòαÑç αñªαÑîαñ░αñ╛αñ¿ αñ¬αñ¼ αñ«αÑçαñé αñ«αñ┐αñ▓αÑç αñùαÑêαñ░ αñòαñ╛αñ¿αñ╛αñ¿αÑéαñ¿αÑÇ αñùαññαñ┐αñ╡αñ┐αñºαñ┐αñ»αÑïαñé αñòαÑï αñ╕αñéαñÜαñ╛αñ▓αñ┐αññ αñòαñ░αñ¿αÑç\n14:02\n14 minutes, 2 seconds\nαñòαÑç αñ╕αñ¼αÑéαññαÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ«αñ╛αñ«αñ▓αñ╛ αñªαñ░αÑìαñ£ αñòαñ░ αñ«αñ╛αñ«αñ▓αÑç αñòαÑÇ αñ£αñ╛αñéαñÜ αñ╢αÑüαñ░αÑé αñòαÑÇαÑñ αñ¼αñ╕αÑìαññαÑÇ αñòαñ╛ αñ░αñ╣αñ¿αÑç αñ╡αñ╛αñ▓αñ╛ αñ»αÑüαñ╡αñò αñòαÑçαñ░αñ▓ αñ«αÑçαñé αñ£αñ┐αñéαñªαñ╛ αñ«αñ┐αñ▓αñ╛ αñ╣αÑêαÑñ αñ¬αñ╛αñ░αñ┐αñ╡αñ╛αñ░αñ┐αñò αñ░αñéαñ£αñ┐αñ╢\n14:10\n14 minutes, 10 seconds\nαñòαÑç αñÜαñ▓αññαÑç αñÿαñ░ αñ╕αÑç αñÜαñ▓αñ╛ αñùαñ»αñ╛ αñÑαñ╛ αñ»αÑüαñ╡αñòαÑñ αñ╕αñ╛αñ╕ αñöαñ░ αñ¼αñ╣αÑé αñòαÑï αñ«αñ┐αñ▓αÑÇ αñ╣αññαÑìαñ»αñ╛ αñòαÑç αñåαñ░αÑïαñ¬ αñ╕αÑç αñ«αÑüαñòαÑìαññαñ┐αÑñ\n14:16\n14 minutes, 16 seconds\nαñ╣αñ╛αñÑαñ░αñ╕ αñòαÑç αñÑαñ╛αñ¿αñ╛ αñ╕αñ╣αñ¬αñè αñòαÑìαñ╖αÑçαññαÑìαñ░ αñ«αÑçαñé αñ╕αñ╛αñºαÑü αñòαÑÇ αñ╣αññαÑìαñ»αñ╛αÑñ αñ«αñéαñªαñ┐αñ░ αñ¬αñ░αñ┐αñ╕αñ░ αñ«αÑçαñé αñûαÑéαñ¿ αñ╕αñ▓αñ╛αñûαññ αñ╣αñ╛αñ▓αññ αñòαÑÇ αñ╢αñ╡ αñ«αñ┐αñ▓αñ╛αÑñ αñ¬αñ┐αñ¢αñ▓αÑç αñòαñ╛αñ½αÑÇ αñ╕αñ«αñ» αñ╕αÑç αñ«αñéαñªαñ┐αñ░ αñ«αÑçαñé\n14:23\n14 minutes, 23 seconds\nαñ¬αÑéαñ£αñ╛ αñ¬αñ╛αñá αñòαñ╛ αñòαñ╛αñ░αÑìαñ» αñòαñ░αññαÑç αñÑαÑç αñªαñ┐αñ▓αÑÇαñ¬αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñªαñ░αÑìαñ£ αñòαñ┐αñ»αñ╛ αñ«αñ╛αñ«αñ▓αñ╛αÑñ\n14:29\n14 minutes, 29 seconds\nαññαÑï αñ╡αñ╣αÑÇαñé αñ«αñºαÑìαñ» αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñùαÑìαñ╡αñ╛αñ▓αñ┐αñ»αñ░ αñ«αÑçαñé 4 αñ£αÑéαñ¿ αñòαÑï αñÅαñò αñ╣αÑÇ αñÿαñ░ αñ«αÑçαñé αñ╣αÑüαñê αñÜαÑïαñ░αÑÇ αñ«αÑçαñé αñ╣αÑüαñå αñ╣αÑê αñÅαñò αñûαÑüαñ▓αñ╛αñ╕αñ╛αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ¬αñíαñ╝αÑïαñ╕αÑÇ αñ«αñ╣αñ┐αñ▓αñ╛ αñòαÑï αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñÜαÑïαñ░αÑÇ αñòαñ╛ αñ«αñ╛αñ« αñ«αñ╛αñ▓ αñ¡αÑÇ αñ«αñ╛αñ▓ αñ¡αÑÇ αñ£αñ¼αÑìαññ αñòαñ░ αñ▓αñ┐αñ»αñ╛ αñ╣αÑêαÑñ\n14:41\n14 minutes, 41 seconds\nαñëαññαÑìαññαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñòαÑîαñ╢αñ╛αñéαñ¼αÑÇ αñ«αÑçαñé αñ£αñéαñùαñ▓ αñ«αÑçαñé αñ«αñ┐αñ▓αÑÇ αñ¼αñ┐αñ£αñ▓αÑÇαÑñ αñòαñ░αÑìαñ«αñÜαñ╛αñ░αÑÇ αñòαñ╛ αñ╕αñ░ αñòαñƒαÑÇ αñ▓αñ╛αñ╢αÑñ αñÿαñ░ αñ╕αÑç αñíαÑìαñ»αÑéαñƒαÑÇ αñòαÑç αñ▓αñ┐αñÅ αñ»αÑüαñ╡αñò αñ¿αñ┐αñòαñ▓αñ╛ αñÑαñ╛αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ╢αñ╡ αñòαñ¼αÑìαñ£αÑç αñ«αÑçαñé αñ▓αÑçαñòαñ░ αñ¬αÑïαñ╕αÑìαñƒαñ«αñ╛αñ░αÑìαñƒαñ« αñòαÑç αñ▓αñ┐αñÅ αñ¡αÑçαñ£αñ╛αÑñ αñ«αñ╛αñ«αñ▓αñ╛ αñ╣αÑüαñå αñªαñ░αÑìαñ£αÑñ\n14:54\n14 minutes, 54 seconds\nαñ▓αñûαñ¿αñè αñòαÑç αñ«αñ╛αñ▓αñºαñ╛αñ¿αñ╛ αñòαÑìαñ╖αÑçαññαÑìαñ░ αñ«αÑçαñé αñ¬αññαñ┐ αñ¬αñ░ αñ¬αññαÑìαñ¿αÑÇ αñòαÑÇ αñ╣αññαÑìαñ»αñ╛ αñòαñ╛ αñåαñ░αÑïαñ¬ αñ╣αÑêαÑñ αñºαñ╛αñ░αñªαñ╛αñ░ αñ╣αñÑαñ┐αñ»αñ╛αñ░ αñ╕αÑç αñëαññαñ╛αñ░αñ╛ αñ«αÑîαññ αñòαÑÇ αñÿαñ╛αñƒαÑñ αñåαñ░αÑïαñ¬αÑÇ αñ¿αÑç αñûαÑüαñª αñ¡αÑÇ αñûαñ╛αñ»αñ╛ αñ£αñ╣αñ░αÑÇαñ▓αñ╛ αñ¬αñªαñ╛αñ░αÑìαñÑ αñàαñ╕αÑìαñ¬αññαñ╛αñ▓ αñ«αÑçαñé αñ¡αñ░αÑìαññαÑÇαÑñ\n15:04\n15 minutes, 4 seconds\nαñ»αÑéαñ¬αÑÇ αñòαÑç αñ╕αÑÇαññαñ╛αñ¬αÑüαñ░ αñ«αÑçαñé αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñºαñ░αÑìαñ«αñ╛αñéαññαñ░αñú αñòαñ╛ αñûαÑüαñ▓αñ╛αñ╕αñ╛ αñòαñ┐αñ»αñ╛αÑñ αñåαñ░αÑìαñÑαñ┐αñò αñ░αÑéαñ¬ αñ╕αÑç αñòαñ«αñ£αÑïαñ░ αñ▓αÑïαñùαÑïαñé αñòαÑï αñ¿αñ┐αñ╢αñ╛αñ¿αñ╛ αñ¼αñ¿αñ╛αñòαñ░ αñòαñ░αñ╡αñ╛αññαÑç αñºαñ░αÑìαñ«αñ╛αñéαññαñ░αñúαÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñÜαñ╛αñ░ αñåαñ░αÑïαñ¬αñ┐αñ»αÑïαñé αñòαÑï αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛αÑñ\n15:13\n15 minutes, 13 seconds\nαñÜαñéαñªαÑîαñ▓αÑÇ αñ«αÑçαñé αñ«αñ¿αÑïαñ£ αñ¿αñ╛αñ« αñòαÑç αñ╢αñûαÑìαñ╕ αñòαÑÇ αñ╣αññαÑìαñ»αñ╛ αñ«αÑçαñé αñûαÑüαñ▓αñ╛αñ╕αñ╛ αñ╣αÑüαñå αñ╣αÑêαÑñ αñ¬αÑêαñ╕αÑïαñé αñòαÑç αñ▓αÑçαñ¿αñªαÑçαñ¿ αñòαÑç αñ╡αñ┐αñ╡αñ╛αñª αñ«αÑçαñé αñ╡αñ╛αñ░αñªαñ╛αññ αñ╣αÑüαñê αñÑαÑÇαÑñ αñ▓αÑïαñòαÑï αñ¬αñ╛αñ»αñ▓αñƒ αñ¿αÑç Γé╣1.5\n15:20\n15 minutes, 20 seconds\nαñ▓αñ╛αñû αñ╕αÑüαñ¬αñ╛αñ░αÑÇ αñªαÑçαñòαñ░ αñòαñ░αñ╡αñ╛αñê αñÑαÑÇ αñ╣αññαÑìαñ»αñ╛αÑñ αñ▓αÑïαñòαÑï αñ¬αñ╛αñ»αñ▓αñƒ αñ╕αñ«αÑçαññ αñ╕αñ¡αÑÇ αñåαñ░αÑïαñ¬αÑÇ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░αÑñ\n15:27\n15 minutes, 27 seconds\nαñ¼αñ┐αñ╣αñ╛αñ░ αñòαÑç αñ¿αñ╡αñ╛αñªαñ╛ αñ«αÑçαñé αñÜαÑçαñòαñ┐αñéαñù αñòαÑç αñªαÑîαñ░αñ╛αñ¿ αñ¼αñ░αñ╛αñ«αñª αñ╣αÑüαñê 57 αñ▓αÑÇαñƒαñ░ αñàαñ╡αÑêαñº αñ╡αñ┐αñªαÑçαñ╢αÑÇ αñ╢αñ░αñ╛αñ¼αÑñ αñ╡αñ╛αñ╣αñ¿ αñòαÑç αñàαñéαñªαñ░ αññαñ╣αñûαñ╛αñ¿αñ╛ αñ¼αñ¿αñ╛αñòαñ░ αñ¢αñ┐αñ¬αñ╛αñê αñùαñê αñÑαÑÇ αñ╢αñ░αñ╛αñ¼αÑñ\n15:35\n15 minutes, 35 seconds\nαñ¿αñ╡αñ╛αñªαñ╛ αñÜαÑçαñò αñ¬αÑïαñ╕αÑìαñƒ αñ¬αñ░ αñÜαÑçαñòαñ┐αñéαñù αñòαÑç αñªαÑîαñ░αñ╛αñ¿ αñ╣αÑüαñå αñûαÑüαñ▓αñ╛αñ╕αñ╛αÑñ\n15:39\n15 minutes, 39 seconds\nαñ«αÑüαñ░αñ╛αñªαñ╛αñ¼αñ╛αñª αñ«αÑçαñé αñ▓αñ┐αñ╡ αñçαñ¿ αñ░αñ┐αñ▓αÑçαñ╢αñ¿αñ╢αñ┐αñ¬ αñ╕αÑç αñ£αÑüαñíαñ╝αñ╛ αñ╣αÑüαñå αñ«αñ╛αñ«αñ▓αñ╛αÑñ αñ»αÑüαñ╡αññαÑÇ αñ¿αÑç αñ£αñ╣αñ░αÑÇαñ▓αñ╛ αñ¬αñªαñ╛αñ░αÑìαñÑ αñûαñ╛αñòαñ░ αñåαññαÑìαñ«αñ╣αññαÑìαñ»αñ╛ αñòαÑÇαÑñ αñ¬αñ╣αñ▓αÑç αñ╕αÑç αñ╢αñ╛αñªαÑÇαñ╢αÑüαñªαñ╛ αñ╢αñûαÑìαñ╕ αñ¬αñ░ αñ»αÑüαñ╡αññαÑÇ αñòαñ╛ αñ╢αÑïαñ╖αñú αñòαñ░αñ¿αÑç αñòαñ╛ αñåαñ░αÑïαñ¬ αñ╣αÑêαÑñ αñ«αñ╛αñ«αñ▓αñ╛ αñ╣αÑüαñå αñªαñ░αÑìαñ£αÑñ\n15:50\n15 minutes, 50 seconds\nαñ¢αññαÑìαññαÑÇαñ╕αñùαñóαñ╝ αñòαÑç αñ¼αñ▓αÑîαñªαñ╛ αñ¼αñ╛αñ£αñ╛αñ░ αñ«αÑçαñé αñ£αÑçαñ▓ αñ╕αÑç αñ¢αÑéαñƒαññαÑç αñ╣αÑÇ αñåαñ░αÑïαñ¬αñ┐αñ»αÑïαñé αñ¿αÑç αñ░αÑÇαñ▓ αñ¼αñ¿αñ╛αñòαñ░ αñ╕αÑïαñ╢αñ▓ αñ«αÑÇαñíαñ┐αñ»αñ╛ αñ¬αñ░ αñ╡αñ╛αñ»αñ░αñ▓ αñòαÑÇαÑñ αñòαñ╛αñ░ αñöαñ░ αñ¼αñ╛αñçαñò αñ░αÑêαñ▓αÑÇ αñ¿αñ┐αñòαñ╛αñ▓αñòαñ░ αñ╣αñíαñ╝αñòαñéαñ¬ αñ«αñÜαñ╛αñ»αñ╛αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç 10 αñåαñ░αÑïαñ¬αñ┐αñ»αÑïαñé αñòαÑï αñÅαñò αñ¼αñ╛αñ░ αñ½αñ┐αñ░ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛αÑñ\n16:03\n16 minutes, 3 seconds\nαñ«αÑüαñ░αñ╛αñªαñ╛αñ¼αñ╛αñª αñ«αÑçαñé αñæαñòαÑìαñ╕αÑÇαñ£αñ¿ αñ╕αñ┐αñ▓αÑçαñéαñíαñ░ αñûαÑïαñ▓αñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ αñ╣αñÑαÑîαñíαñ╝αÑç αñòαñ╛ αñçαñ╕αÑìαññαÑçαñ«αñ╛αñ▓ αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛αÑñ\n16:06\n16 minutes, 6 seconds\nαñÅαñéαñ¼αÑüαñ▓αÑçαñéαñ╕ αñ«αÑçαñé αñ«αñ░αÑÇαñ£ αñòαÑï αñæαñòαÑìαñ╕αÑÇαñ£αñ¿ αñ▓αñùαñ╛αñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ αñ╣αñÑαÑîαñíαñ╝αÑç αñ╕αÑç αñ╕αñ┐αñ▓αÑçαñéαñíαñ░ αñûαÑïαñ▓αñ╛ αñùαñ»αñ╛αÑñ αñëαñ£αñ╛αñùαñ░ αñ╣αÑüαñê αñ╕αÑìαñ╡αñ╛αñ╕αÑìαñÑαÑìαñ» αñ╡αñ┐αñ¡αñ╛αñù αñòαÑÇ αñ▓αñ╛αñ¬αñ░αñ╡αñ╛αñ╣αÑÇαÑñ\n16:15\n16 minutes, 15 seconds\nαñ¼αñ░αÑçαñ▓αÑÇ αñ«αÑçαñé αñ«αñ╣αñ┐αñ▓αñ╛ αñòαñ╛ αñ╢αÑïαñ╖αñú αñöαñ░ αñºαñ░αÑìαñ« αñ¬αñ░αñ┐αñ╡αñ░αÑìαññαñ¿ αñòαñ╛ αñªαñ¼αñ╛αñ╡ αñ¼αñ¿αñ╛αñ¿αÑç αñòαñ╛ αñ«αñ╛αñ«αñ▓αñ╛αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñåαñ░αÑïαñ¬αÑÇ αñ»αÑüαñ╡αñò αñàαñ░αñ¼αñ╛αñ£ αñòαÑï αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛αÑñ αñºαñ░αÑìαñ« αñ¢αñ┐αñ¬αñ╛αñòαñ░ αñëαññαÑìαñ¬αÑÇαñíαñ╝αñ¿ αñòαñ╛ αñåαñ░αÑïαñ¬ αñ╣αÑêαÑñ\n16:27\n16 minutes, 27 seconds\nαñ╣αñ╛αñ¬αÑüαñíαñ╝ αñ«αÑçαñé αñ¬αÑüαñ▓αñ┐αñ╕ αñ¡αñ░αÑìαññαÑÇ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛ αñòαÑçαñéαñªαÑìαñ░ αñòαÑç αñàαñéαñªαñ░ αñ«αÑïαñ¼αñ╛αñçαñ▓ αñ▓αÑçαñòαñ░ αñ¬αñ╣αÑüαñéαñÜαñ╛ αñ»αÑüαñ╡αñòαÑñ αñ╡αñ╛αñ╢αñ░αÑéαñ« αñòαÑç αñàαñéαñªαñ░ αñ«αÑïαñ¼αñ╛αñçαñ▓ αñòαÑç αñ╕αñ╛αñÑ αñ¬αñòαñíαñ╝αñ╛ αñùαñ»αñ╛ αñ»αÑüαñ╡αñòαÑñ\n16:33\n16 minutes, 33 seconds\nαñ▓αñ╛αñ¬αñ░αñ╡αñ╛αñ╣αÑÇ αñ¬αñ░ αñªαÑï αñªαñ╛αñ░αÑïαñùαñ╛ αñ╕αñ«αÑçαññ αñ¢αñ╣ αñ¿αñ┐αñ▓αñéαñ¼αñ┐αññ αñòαñ┐αñÅ αñùαñÅαÑñ\n16:38\n16 minutes, 38 seconds\nαñ╕αÑïαñ¿αñ¡αñªαÑìαñ░ αñ«αÑçαñé αñ¼αñ╛αñçαñò αñ«αÑçαñé αñ▓αñùαÑÇ αñåαñùαÑñ αñªαÑçαñûαññαÑç αñ╣αÑÇ αñªαÑçαñûαññαÑç αñºαÑéαñº-αñºαÑé αñòαñ░ αñ£αñ▓αÑÇ αñ¼αñ╛αñçαñòαÑñ αñ╢αÑëαñ░αÑìαñƒ αñ╕αñ░αÑìαñòαñ┐αñƒ αñòαÑÇ αñ╡αñ£αñ╣ αñ╕αÑç αñåαñù αñ▓αñùαñ¿αÑç αñòαÑÇ αñåαñ╢αñéαñòαñ╛ αñùαñ¿αÑÇαñ«αññ αñ░αñ╣αÑÇαÑñ\n16:45\n16 minutes, 45 seconds\nαñ╣αñ╛αñªαñ╕αÑç αñ«αÑçαñé αñòαÑïαñê αñ£αñ¿αñ╣αñ╛αñ¿αñ┐ αñ¿αñ╣αÑÇαñé αñ╣αÑüαñê αñ╣αÑêαÑñ\n16:49\n16 minutes, 49 seconds\nαñòαÑüαñ░αÑüαñòαÑìαñ╖αÑçαññαÑìαñ░ αñ«αÑçαñé αñ¬αñƒαñ░αÑÇ αñ╕αÑç αñëαññαñ░αÑç αñ«αñ╛αñ▓αñùαñ╛αñíαñ╝αÑÇ αñòαÑç αññαÑÇαñ¿ αñíαñ┐αñ¼αÑìαñ¼αÑçαÑñ αñòαÑüαñ░αÑüαñòαÑìαñ╖αÑçαññαÑìαñ░ αñ╕αÑç αñ¬αñ┐αñ╣αÑïαñ╡αñ╛ αñ░αÑïαñí αñ╕αÑìαñƒαÑçαñ╢αñ¿ αñòαÑç αñ¼αÑÇαñÜ αñ╣αÑüαñå αñ╣αñ╛αñªαñ╕αñ╛αÑñ αñòαñ╛αñ½αÑÇ αñªαÑçαñ░ αññαñò αñ¼αñ╛αñºαñ┐αññ αñ░αñ╣αñ╛ αñ░αÑçαñ▓ αñ»αñ╛αññαñ╛αñ»αñ╛αññαÑñ\n17:00\n17 minutes\nαñªαñ┐αñ▓αÑìαñ▓αÑÇ αñòαÑç αñ╡αñ┐αñòαñ╛αñ╕αñ¬αÑüαñ░αÑÇ αñ«αÑçαñé αñàαññαñ┐αñòαÑìαñ░αñ«αñú αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñ╣αÑüαñê αñòαñ╛αñ░αñ╡αñ╛αñêαÑñ αñ¬αÑÇαñíαñ¼αÑìαñ▓αÑìαñ»αÑéαñíαÑÇ αñ¿αÑç αñªαÑüαñòαñ╛αñ¿αÑïαñé αñòαÑç αñ¼αñ╛αñ╣αñ░ αñ¼αñ¿αÑç αñ░αÑêαñéαñ¬ αñöαñ░ αñ╕αÑÇαñóαñ╝αñ┐αñ»αÑïαñé αñ¬αñ░ αñÜαñ▓αñ╛αñ»αñ╛ αñ¼αÑüαñ▓αñíαÑïαñ£αñ░αÑñ αñ╕αñ░αñòαñ╛αñ░αÑÇ αñ£αñ«αÑÇαñ¿ αñ╕αÑç αñ╣αñƒαñ╛αñ»αñ╛ αñùαñ»αñ╛ αñàαñ╡αÑêαñº αñòαñ¼αÑìαñ£αñ╛αÑñ\n17:12\n17 minutes, 12 seconds\nαñÅαñ«αñ¬αÑÇ αñòαÑç αñ¿αñ░αñ╕αñ┐αñéαñ╣αñ¬αÑüαñ░ αñ«αÑçαñé αñ╕αñ░αñòαñ╛αñ░αÑÇ αñ£αñ«αÑÇαñ¿ αñ╕αÑç αñòαñ¼αÑìαñ£αñ╛ αñ╣αñƒαñ╛αñ¿αÑç αñòαñ╛ αñ╡αñ┐αñ░αÑïαñºαÑñ αñùαÑìαñ░αñ╛αñ«αÑÇαñúαÑïαñé αñ¿αÑç αñòαñ┐αñ»αñ╛ αñ¼αÑüαñ▓αñíαÑïαñ£αñ░ αñòαñ╛αñ░αñ╡αñ╛αñê αñòαñ╛ αñ╡αñ┐αñ░αÑïαñºαÑñ αñ£αÑçαñ╕αÑÇαñ¼αÑÇ αñòαÑç αñ╕αñ╛αñ«αñ¿αÑç αñûαñíαñ╝αÑç αñ╣αÑïαñòαñ░ αñ▓αÑïαñùαÑïαñé αñ¿αÑç αñ╣αñéαñùαñ╛αñ«αñ╛ αñòαñ┐αñ»αñ╛αÑñ αñ╣αñéαñùαñ╛αñ«αÑç αñòαÑç αñÜαñ▓αññαÑç αñ¬αÑìαñ░αñ╢αñ╛αñ╕αñ¿ αñòαÑï αñòαñ╛αñ░αñ╡αñ╛αñê αñ░αÑïαñòαñ¿αÑÇ αñ¬αñíαñ╝αÑÇαÑñ\n17:24\n17 minutes, 24 seconds\nαñ»αÑéαñ¬αÑÇ αñòαÑç αñ╕αñéαñ¡αñ▓ αñ«αÑçαñé αñºαÑìαñ╡αñ╕αÑìαññαñòαñ░αñú αñòαñ╛αñ░αñ╡αñ╛αñ╣αÑÇ αñòαÑç αñ¼αñ╛αñª αñ«αñ▓αñ¼αñ╛ αñ╣αñƒαñ╛αñ¿αÑç αñòαñ╛ αñòαñ╛αñ░αÑìαñ» αñ£αñ╛αñ░αÑÇαÑñ αñ¼αÑüαñ▓αñíαÑïαñ£αñ░ αñòαÑÇ αñ«αñªαñª αñ╕αÑç αñ╕αñíαñ╝αñò αñòαÑç αñåαñ╕αñ¬αñ╛αñ╕ αñòαÑç αñçαñ▓αñ╛αñòαÑïαñé αñ╕αÑç αñ«αñ▓αñ¼αñ╛ αñ╣αñƒαñ╛αñ»αñ╛ αñ£αñ╛ αñ░αñ╣αñ╛αÑñ αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñòαÑç αñ«αñªαÑìαñªαÑçαñ¿αñ£αñ░ αñ¬αÑÇαñÅαñ╕αñ╕αÑÇ αñòαÑç αñ£αñ╡αñ╛αñ¿ αññαÑêαñ¿αñ╛αññαÑñ\n17:35\n17 minutes, 35 seconds\nαñ¡αñ╛αñ░αññαÑÇαñ» αñ¿αÑîαñ╕αÑçαñ¿αñ╛ αñ¿αÑç αñ░αñ╛αñ«αÑçαñ╢αÑìαñ╡αñ░αñ« αñ«αÑçαñé αñòαñ┐αñ»αñ╛ αññαñƒαÑÇαñ» αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñòαÑï αñ▓αÑçαñòαñ░ αñ╕αÑêαñ¿αÑìαñ»αñ╛ αñàαñ¡αÑìαñ»αñ╛αñ╕αÑñ αñ¿αÑîαñ╕αÑçαñ¿αñ╛ αñòαÑç αñ╣αÑçαñ▓αÑÇαñòαÑëαñ¬αÑìαñƒαñ░αÑìαñ╕ αñ¿αÑç αññαñƒαÑÇαñ» αñçαñ▓αñ╛αñòαÑïαñé αñ«αÑçαñé αñòαñ« αñèαñéαñÜαñ╛αñê αñ¬αñ░ αñëαñíαñ╝αñ╛αñ¿αÑç αñ¡αñ░αÑÇαÑñ\n17:44\n17 minutes, 44 seconds\nαñ╣αÑêαñªαñ░αñ╛αñ¼αñ╛αñª αñ╕αñÜαñ┐αñ╡αñ╛αñ▓αñ» αñòαÑç αñ¬αñ╛αñ╕ αñ«αÑêαñ¿ αñ╣αÑïαñ▓ αñ«αÑçαñé αñ½αñéαñ╕αñ╛ αñ¼αñÜαÑìαñÜαÑç αñòαñ╛ αñ¬αÑêαñ░αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñöαñ░ αñ½αñ╛αñ»αñ░ αñ╕αñ░αÑìαñ╡αñ┐αñ╕ αñ¿αÑç αñòαñ╛αñ½αÑÇ αñ«αñ╢αñòαÑìαñòαññ αñòαÑç αñ¼αñ╛αñª αñ¼αñÜαÑìαñÜαÑç αñòαÑï αñ╕αÑüαñ░αñòαÑìαñ╖αñ┐αññ αñ¼αñ╛αñ╣αñ░ αñ¿αñ┐αñòαñ╛αñ▓αñ╛αÑñ\n17:53\n17 minutes, 53 seconds\nαñùαÑìαñ░αÑçαñƒαñ░ αñ¿αÑïαñÅαñíαñ╛ αñòαÑç αñòαñê αñçαñ▓αñ╛αñòαÑïαñé αñ«αÑçαñé αñåαñ╡αñ╛αñ░αñ╛ αñòαÑüαññαÑìαññαÑïαñé αñòαñ╛ αñåαññαñéαñò αñ╣αÑêαÑñ αñòαÑüαññαÑìαññαÑïαñé αñòαÑç αñ¥αÑüαñéαñí αñ¿αÑç αñ¼αñÜαÑìαñÜαÑÇ αñ¬αñ░ αñàαñƒαÑêαñò αñòαñ░ αñªαñ┐αñ»αñ╛αÑñ αñ¼αñÜαÑìαñÜαÑÇ αñòαÑï αñòαñ╛αñƒαñòαñ░ αñÿαñ╛αñ»αñ▓ αñòαñ┐αñ»αñ╛αÑñ αñÿαñƒαñ¿αñ╛ αñ╣αÑüαñê αñ╕αÑÇαñ╕αÑÇαñƒαÑÇαñ╡αÑÇ αñòαÑêαñ«αñ░αÑç αñ«αÑçαñé αñ░αñ┐αñòαÑëαñ░αÑìαñíαÑñ\n18:03\n18 minutes, 3 seconds\nαñ╣αñ░αñ┐αñªαÑìαñ╡αñ╛αñ░ αñ«αÑçαñé αñ╕αñ░αñ╛αñ» αñçαñ▓αñ╛αñòαÑç αñ«αÑçαñé αñÅαñò αñÿαñ░ αñòαÑç αñàαñéαñªαñ░ αñ░αÑçαñéαñùαññαÑç αñ«αñ┐αñ▓αÑç 27 αñ╕αñ¬αÑïαñ▓αÑçαÑñ αñƒαñéαñòαÑÇ αñòαÑç αñàαñéαñªαñ░ 27 αñ╕αñ╛αñéαñ¬ αñòαÑç αñ╕αñ¬αÑïαñ▓αÑç αñªαÑçαñûαñòαñ░ αñ╣αÑêαñ░αñ╛αñ¿ αñ░αñ╣ αñùαñÅ αñ▓αÑïαñùαÑñ\n18:11\n18 minutes, 11 seconds\nαñ╡αñ¿ αñ╡αñ┐αñ¡αñ╛αñù αñ¿αÑç αñ╕αñ¡αÑÇ αñòαÑï αñòαñ¼αÑìαñ£αÑç αñ«αÑçαñé αñ▓αÑçαñòαñ░ αñ£αñéαñùαñ▓ αñ«αÑçαñé αñ¢αÑïαñíαñ╝αñ╛αÑñ\n18:15\n18 minutes, 15 seconds\nαñªαñ┐αñ▓αÑìαñ▓αÑÇ αñÅαñ¿αñ╕αÑÇαñåαñ░ αñ«αÑçαñé αñàαñùαñ▓αÑç αññαÑÇαñ¿ αñªαñ┐αñ¿αÑïαñé αññαñò αñ£αñ╛αñ░αÑÇ αñ░αñ╣ αñ╕αñòαññαÑÇ αñ╣αÑê αñ¡αÑÇαñ╖αñú αñùαñ░αÑìαñ«αÑÇαÑñ αññαñ╛αñ¬αñ«αñ╛αñ¿ 42 αñ╕αÑç 44┬░ αñòαÑç αñ¼αÑÇαñÜ αñ░αñ╣αñ¿αÑç αñòαñ╛ αñàαñ¿αÑüαñ«αñ╛αñ¿ αñ╣αÑêαÑñ 11 αñ£αÑéαñ¿ αñòαÑç αñ¼αñ╛αñª αñÑαÑïαñíαñ╝αÑÇ αñ░αñ╛αñ╣αññ αñ«αñ┐αñ▓ αñ╕αñòαññαÑÇ αñ╣αÑêαÑñ\n18:26\n18 minutes, 26 seconds\nαñàαñùαñ▓αÑç αñ╕αñ╛αññ αñªαñ┐αñ¿αÑïαñé αñòαÑç αñªαÑîαñ░αñ╛αñ¿ αñòαÑçαñ░αñ▓, αñòαñ░αÑìαñ¿αñ╛αñƒαñò, αññαñ«αñ┐αñ▓αñ¿αñ╛αñíαÑü αñöαñ░ αñëαññαÑìαññαñ░αñ¬αÑéαñ░αÑìαñ╡αÑÇ αñ¡αñ╛αñ░αññ αñ«αÑçαñé αñòαÑüαñ¢ αñ╕αÑìαñÑαñ╛αñ¿αÑïαñé αñ¬αñ░ αñ¼αñ╣αÑüαññ αñ¡αñ╛αñ░αÑÇ αñ¼αñ╛αñ░αñ┐αñ╢ αñòαñ╛ αñàαñ▓αñ░αÑìαñƒαÑñ αñåαñ£\n18:32\n18 minutes, 32 seconds\nαñòαñ░αÑìαñ¿αñ╛αñƒαñòαñ╛ αñöαñ░ αñòαÑçαñ░αñ▓ αñ«αÑçαñé αñ¡αñ╛αñ░αÑÇ αñ¼αñ╛αñ░αñ┐αñ╢ αñòαÑÇ αñåαñ╢αñéαñòαñ╛	f	2026-06-09 13:23:26.086536
33	UCKwucPzHZ7zCUIf7If-Wo1g	National	General	Transcript\nSearch transcript\n0:13\n13 seconds\nαñ¿αñ«αñ╕αÑìαñòαñ╛αñ░ αñ╕αÑìαñ╡αñ╛αñùαññ αñ╣αÑê αñåαñ¬ αñ╕αñ¡αÑÇ αñòαñ╛ αñíαÑÇαñíαÑÇ αñ¿αÑìαñ»αÑéαñ£αñ╝ αñòαÑç αñûαñ╛αñ╕ αñ¼αÑüαñ▓αÑçαñƒαñ┐αñ¿ αñÅαñòαÑìαñ╕αñ¬αÑìαñ░αÑçαñ╕ 100 αñ«αÑçαñé αñ£αñ╣αñ╛αñé αñ╣αñ« αñåαñ¬αñòαÑç αñ▓αñ┐αñÅ αñ▓αÑçαñòαñ░ αñåαññαÑç αñ╣αÑêαñé αñ░αñ╛αñ£αñ¿αÑÇαññαñ┐ αñªαÑçαñ╢ αñªαÑüαñ¿αñ┐αñ»αñ╛\n0:20\n20 seconds\nαñûαÑçαñ▓ αñöαñ░ αñ╡αÑìαñ»αñ╛αñ¬αñ╛αñ░ αñ£αñùαññ αñòαÑÇ αñ╕αñ¡αÑÇ αñ¼αñíαñ╝αÑÇ αñûαñ¼αñ░αÑïαñé αñòαÑï αñÅαñòαÑìαñ╕αñ¬αÑìαñ░αÑçαñ╕ αñ»αñ╛αñ¿αÑÇ αñ½αñƒαñ╛αñ½αñƒ αñàαñéαñªαñ╛αñ£ αñ«αÑçαñéαÑñ αñ«αÑêαñé αñ╣αÑéαñé αñòαÑâαññαñ┐αñòαñ╛αÑñ αññαÑï αñÜαñ▓αñ┐αñÅ αñ╢αÑüαñ░αÑüαñåαññ αñòαñ░αññαÑç αñ╣αÑêαñé αñÅαñòαÑìαñ╕αñ¬αÑìαñ░αÑçαñ╕ 100 αñòαÑÇ αñöαñ░ αñªαÑçαñûαññαÑç αñ╣αÑêαñé αñûαñ¼αñ░αÑçαñé αññαÑçαñ£ αñ░αñ½αÑìαññαñ╛αñ░ αñ╕αÑçαÑñ\n0:33\n33 seconds\nαñåαñ£ αñ╣αÑÇ αñòαÑç αñªαñ┐αñ¿ αñ╕αñ╛αñ▓ 204 αñ«αÑçαñé αññαÑÇαñ╕αñ░αÑÇ αñ¼αñ╛αñ░ αñ¬αÑìαñ░αñºαñ╛αñ¿αñ«αñéαññαÑìαñ░αÑÇ αñ¬αñª αñòαÑÇ αñ╢αñ¬αñÑ αñ▓αÑçαñòαñ░ αñ¿αñ░αÑçαñéαñªαÑìαñ░ αñ«αÑïαñªαÑÇ αñ¿αÑç αñ¡αñ╛αñ░αññαÑÇαñ» αñ░αñ╛αñ£αñ¿αÑÇαññαñ┐ αñ«αÑçαñé αñ¿αñ»αñ╛ αñçαññαñ┐αñ╣αñ╛αñ╕ αñ░αñÜαñ╛ αñÑαñ╛αÑñ\n0:39\n39 seconds\nαñ▓αñùαñ╛αññαñ╛αñ░ αññαÑÇαñ╕αñ░αÑÇ αñ¼αñ╛αñ░ αñ£αñ¿αññαñ╛ αñòαÑç αñ¡αñ░αÑïαñ╕αÑç αñ¿αÑç αñÅαñ¿αñíαÑÇαñÅ αñòαÑï αñ╕αññαÑìαññαñ╛ αñ╕αÑîαñéαñ¬αÑÇαÑñ\n0:46\n46 seconds\nαñ¬αÑÇαñÅαñ« αñ«αÑïαñªαÑÇ αñòαÑÇ αñàαñùαÑüαñ╡αñ╛αñê αñ«αÑçαñé αñ╡αñ┐αñòαñ╕αñ┐αññ αñ¡αñ╛αñ░αññ αñòαÑç αñ╕αñéαñòαñ▓αÑìαñ¬ αñòαÑï αñ¿αñê αñ░αñ½αÑìαññαñ╛αñ░ αñ«αñ┐αñ▓αÑÇ αñ╣αÑêαÑñ αñ«αÑïαñªαÑÇ αñ╕αñ░αñòαñ╛αñ░ αñòαÑç 12 αñ╕αñ╛αñ▓ αñ¬αÑéαñ░αÑç αñ╣αÑïαñ¿αÑç αñ¬αñ░ αñªαÑçαñ╢ αñ¿αÑç αñòαñê αñëαñ¬αñ▓αñ¼αÑìαñºαñ┐αñ»αñ╛αñé αñ╣αñ╛αñ╕αñ┐αñ▓ αñòαÑÇ αñ£αñ┐αñ¿αÑìαñ╣αÑïαñéαñ¿αÑç αñªαÑçαñ╢ αñòαÑÇ αñ╡αñ┐αñòαñ╛αñ╕ αñ»αñ╛αññαÑìαñ░αñ╛ αñòαÑï αñ¿αñê αñªαñ┐αñ╢αñ╛ αñªαÑÇαÑñ\n0:58\n58 seconds\nαñòαÑçαñéαñªαÑìαñ░αÑÇαñ» αñ«αñéαññαÑìαñ░αÑÇ αñàαñ╢αÑìαñ╡αñ┐αñ¿αÑÇ αñ╡αÑêαñ╖αÑìαñúαñ╡ αñ¿αÑç αñ¬αÑìαñ░αñºαñ╛αñ¿αñ«αñéαññαÑìαñ░αÑÇ αñ«αÑïαñªαÑÇ αñòαÑç αñ¿αÑçαññαÑâαññαÑìαñ╡ αñòαÑÇ αñ╕αñ░αñ╛αñ╣αñ¿αñ╛ αñòαñ░αññαÑç αñ╣αÑüαñÅ αñòαñ╣αñ╛ αñòαñ┐ αñ¬αñ┐αñ¢αñ▓αÑç 12 αñ╡αñ░αÑìαñ╖αÑïαñé αñ«αÑçαñé αñ¬αÑÇαñÅαñ« αñ«αÑïαñªαÑÇ αñ¿αÑç αñªαÑçαñ╢ αñòαÑÇ αñàαñ░αÑìαñÑαñ╡αÑìαñ»αñ╡αñ╕αÑìαñÑαñ╛ αñòαÑï αñ«αñ£αñ¼αÑéαññαÑÇ\n1:06\n1 minute, 6 seconds\nαñ¬αÑìαñ░αñªαñ╛αñ¿ αñòαÑÇ αñ╣αÑêαÑñ αñ¬αÑÇαñÅαñ« αñ«αÑïαñªαÑÇ αñ¿αÑç αñªαÑéαñ░αñªαñ░αÑìαñ╢αÑÇ αñ½αÑêαñ╕αñ▓αÑïαñé, αñ╡αÑìαñ»αñ╛αñ¬αñò αñ╕αÑüαñºαñ╛αñ░αÑïαñé αñöαñ░ αñ╡αñ┐αñòαñ╛αñ╕ αñòαÑÇ αñ¿αÑÇαññαñ┐αñ»αÑïαñé αñòαÑç αñ¼αñ▓ αñ¬αñ░ αñ¡αñ╛αñ░αññ αñåαñ£ αñªαÑüαñ¿αñ┐αñ»αñ╛ αñòαÑç αñ¬αÑìαñ░αñ«αÑüαñû αñàαñ░αÑìαñÑαñ╡αÑìαñ»αñ╡αñ╕αÑìαñÑαñ╛αñôαñé αñ«αÑçαñé αñàαñ¬αñ¿αÑÇ αñ«αñ£αñ¼αÑéαññ αñ¬αñ╣αñÜαñ╛αñ¿ αñ¼αñ¿αñ╛ αñ░αñ╣αñ╛ αñ╣αÑêαÑñ\n1:18\n1 minute, 18 seconds\nαñòαÑçαñéαñªαÑìαñ░αÑÇαñ» αñ«αñéαññαÑìαñ░αÑÇ αñàαñ╢αÑìαñ╡αñ┐αñ¿αÑÇ αñ╡αÑêαñ╖αÑìαñúαñ╡ αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñ╕αñ░αñòαñ╛αñ░ αñ¿αÑç αñ╕αÑçαñ«αÑÇαñòαñéαñíαñòαÑìαñƒαñ░ αñ£αÑêαñ╕αÑç αñàαññαÑìαñ»αñ╛αñºαÑüαñ¿αñ┐αñò αñëαñªαÑìαñ»αÑïαñù αñòαÑç αñ╡αñ┐αñòαñ╛αñ╕ αñòαÑç αñ▓αñ┐αñÅ αñÉαñ╕αñ╛ αñàαñ¿αÑüαñòαÑéαñ▓ αñçαñòαÑïαñ╕αñ┐αñ╕αÑìαñƒαñ« αññαÑêαñ»αñ╛αñ░ αñòαñ┐αñ»αñ╛ αñ£αñ┐αñ╕αñ¿αÑç αñ¡αñ╛αñ░αññ αñòαÑï\n1:27\n1 minute, 27 seconds\nαñ╡αÑêαñ╢αÑìαñ╡αñ┐αñò αñ╕αÑçαñ«αÑÇαñòαñéαñíαñòαÑìαñƒαñ░ αñ«αñ╛αñ¿αñÜαñ┐αññαÑìαñ░ αñ¬αñ░ αñ«αñ£αñ¼αÑéαññ αñ¬αñ╣αñÜαñ╛αñ¿ αñªαñ┐αñ▓αñ╛αñêαÑñ\n1:32\n1 minute, 32 seconds\nαñòαÑçαñéαñªαÑìαñ░αÑÇαñ» αñùαÑâαñ╣ αñÅαñ╡αñé αñ╕αñ╣αñòαñ╛αñ░αñ┐αññαñ╛ αñ«αñéαññαÑìαñ░αÑÇ αñàαñ«αñ┐αññ αñ╢αñ╛αñ╣ αñåαñ£ αñ¿αñê αñªαñ┐αñ▓αÑìαñ▓αÑÇ αñ«αÑçαñé αñ▓αÑêαñéαñí αñ¬αÑïαñ░αÑìαñƒ αñ«αÑêαñ¿αÑçαñ£αñ«αÑçαñéαñƒ αñ╕αñ┐αñ╕αÑìαñƒαñ« αñÅαñ▓αñ¬αÑÇαñÅαñ«αñÅαñ╕ αñòαñ╛ αñ╢αÑüαñ¡αñ╛αñ░αñéαñ¡ αñòαñ░αÑçαñéαñùαÑçαÑñ αñçαñ╕αñòαñ╛ αñëαñªαÑìαñªαÑçαñ╢αÑìαñ» αñàαññαÑìαñ»αñ╛αñºαÑüαñ¿αñ┐αñò αññαñòαñ¿αÑÇαñòαÑÇ\n1:41\n1 minute, 41 seconds\nαñ╕αñ«αñ╛αñºαñ╛αñ¿αÑïαñé αñòαÑç αñ«αñ╛αñºαÑìαñ»αñ« αñ╕αÑç αñ╕αÑÇαñ«αñ╛ αñ¬αñ╛αñ░ αñ╡αÑìαñ»αñ╛αñ¬αñ╛αñ░ αñöαñ░ αñ»αñ╛αññαÑìαñ░αñ┐αñ»αÑïαñé αñòαÑÇ αñåαñ╡αñ╛αñ£αñ╛αñ╣αÑÇ αñòαÑï αñàαñºαñ┐αñò αñòαÑüαñ╢αñ▓ αñ¬αñ╛αñ░αñªαñ░αÑìαñ╢αÑÇ αñöαñ░ αñ╕αÑüαñ░αñòαÑìαñ╖αñ┐αññ αñ¼αñ¿αñ╛αñ¿αñ╛ αñ╣αÑêαÑñ αñ▓αÑêαñéαñíαñ¬αÑïαñƒ\n1:49\n1 minute, 49 seconds\nαñ«αÑêαñ¿αÑçαñ£αñ«αÑçαñéαñƒ αñ╕αñ┐αñ╕αÑìαñƒαñ« αñÅαñò αñàαññαÑìαñ»αñ╛αñºαÑüαñ¿αñ┐αñò αñíαñ┐αñ£αñ┐αñƒαñ▓ αñ¬αÑìαñ▓αÑçαñƒαñ½αñ╛αñ░αÑìαñ« αñ╣αÑê αñ£αñ┐αñ╕αÑç αñ╕αñ¡αÑÇ αñ▓αÑêαñéαñíαñ¬αÑïαñƒ αñòαÑç αñòαñ╛αñ«αñòαñ╛αñ£ αñòαÑï αñçαñéαñƒαÑÇαñùαÑìαñ░αÑçαñƒαÑçαñí αñ╕αñ┐αñ╕αÑìαñƒαñ« αñ╕αÑç αñ£αÑïαñíαñ╝αñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ αñ¼αñ¿αñ╛αñ»αñ╛ αñùαñ»αñ╛ αñ╣αÑêαÑñ αñçαñ╕αñ«αÑçαñé αñòαñ╛αñ░αñùαÑï αñöαñ░ αñ»αñ╛αññαÑìαñ░αñ┐αñ»αÑïαñé\n1:58\n1 minute, 58 seconds\nαñòαÑÇ αñ¬αÑìαñ░αÑïαñ╕αÑçαñ╕αñ┐αñéαñù αñòαÑç αñ▓αñ┐αñÅ αñ╕αÑìαñ▓αÑëαñƒ αñ¼αÑüαñòαñ┐αñéαñù, αñ¡αÑüαñùαññαñ╛αñ¿, αñƒαÑìαñ░αÑêαñòαñ┐αñéαñù αñöαñ░ αñ╕αñ┐αñéαñùαñ▓ αñ╡αñ┐αñéαñíαÑï αñòαÑìαñ▓αÑÇαñ»αñ░αÑçαñéαñ╕ αñ£αÑêαñ╕αÑÇ αñ╕αÑüαñ╡αñ┐αñºαñ╛ αñ╢αñ╛αñ«αñ┐αñ▓ αñ╣αÑêαÑñ\n2:05\n2 minutes, 5 seconds\nαñùαÑâαñ╣ αñ«αñéαññαÑìαñ░αÑÇ αñàαñ«αñ┐αññ αñ╢αñ╛αñ╣ αñåαñ£ αñíαÑëαñòαÑÇ αñöαñ░ αñ╢αÑìαñ░αÑÇαñ«αñéαññαñ¬αÑüαñ░ αñ¡αÑéαñ«αñ┐ αñ¼αñéαñªαñ░αñùαñ╛αñ╣αÑïαñé αñ¬αñ░ αñ¿αñ╡αñ¿αñ┐αñ░αÑìαñ«αñ┐αññ αñåαñ╡αñ╛αñ╕ αñ╕αÑüαñ╡αñ┐αñºαñ╛αñôαñé αñòαñ╛ αñ¡αÑÇ αñëαñªαÑìαñÿαñ╛αñƒαñ¿ αñòαñ░αÑçαñéαñùαÑçαÑñ αñçαñ╕αñ╕αÑç αñ╕αÑÇαñ«αñ╛ αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñòαñ░αÑìαñ«αñ┐αñ»αÑïαñé αñöαñ░ αñàαñ¿αÑìαñ» αñ«αñ╣αññαÑìαñ╡αñ¬αÑéαñ░αÑìαñú\n2:14\n2 minutes, 14 seconds\nαñºαñ╛αñ░αñòαÑïαñé αñòαÑç αñ▓αñ┐αñÅ αñ¼αÑüαñ¿αñ┐αñ»αñ╛αñªαÑÇ αñóαñ╛αñéαñÜαñ╛ αñòαñ╛ αñ╕αñ╣αñ»αÑïαñù αñöαñ░ αñàαñºαñ┐αñò αñ╕αÑüαñªαÑâαñóαñ╝ αñ╣αÑïαñùαñ╛αÑñ\n2:20\n2 minutes, 20 seconds\nαñòαñ▓ αñòαÑçαñéαñªαÑìαñ░αÑÇαñ» αñòαÑçαñéαñªαÑìαñ░αÑÇαñ» αñùαÑâαñ╣ αñÅαñ╡αñé αñ╕αñ╣αñòαñ╛αñ░αñ┐αññαñ╛ αñ«αñéαññαÑìαñ░αÑÇ αñàαñ«αñ┐αññ αñ╢αñ╛αñ╣ αñ¿αÑç αñªαñ┐αñ▓αÑìαñ▓αÑÇ αñ«αÑçαñé αñ»αñ«αÑüαñ¿αñ╛ αñ¬αÑüαñ¿αñ░αÑìαñ£αÑÇαñ╡αÑÇαñòαñ░αñú αñòαÑç αñ«αÑüαñªαÑìαñªαÑç αñòαÑÇ αñ╕αñ«αÑÇαñòαÑìαñ╖αñ╛ αñ¼αÑêαñáαñò αñòαÑÇαÑñ αñ¼αÑêαñáαñò αñ«αÑçαñé αñ»αñ«αÑüαñ¿αñ╛ αñ«αÑçαñé αñçαñòαÑï αñ½αÑìαñ▓αÑï\n2:28\n2 minutes, 28 seconds\nαñ╕αÑüαñ¿αñ┐αñ╢αÑìαñÜαñ┐αññ αñòαñ░αñ¿αÑç, αñ¿αñ╛αñ▓αÑïαñé αñòαÑÇ αñíαÑÇαñ╕αñ┐αñ▓αÑìαñƒαñ┐αñéαñù, αñ╕αÑÇαñ╡αÑçαñ£ αñƒαÑìαñ░αÑÇαñƒαñ«αÑçαñéαñƒ, αñíαÑçαñ»αñ░αÑÇ αñ╡αÑçαñ╕αÑìαñƒ αñ¬αÑìαñ░αñ¼αñéαñºαñ¿ αñöαñ░ αñ¬αÑìαñ░αñªαÑéαñ╖αñú αñòαÑÇ αñ¿αñ┐αñùαñ░αñ╛αñ¿αÑÇ αñ£αÑêαñ╕αÑç αñ«αÑüαñªαÑìαñªαÑïαñé αñ¬αñ░ αñ╡αñ┐αñ╕αÑìαññαñ╛αñ░ αñ╕αÑç αñÜαñ░αÑìαñÜαñ╛ αñ╣αÑüαñêαÑñ\n2:40\n2 minutes, 40 seconds\nαñàαñ«αñ┐αññ αñ╢αñ╛αñ╣ αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñªαñ┐αñ▓αÑìαñ▓αÑÇ αñòαÑç αñíαÑçαñ░αñ┐αñ»αÑïαñé αñ╕αÑç αñ¿αñ┐αñòαñ▓αñ¿αÑç αñ╡αñ╛αñ▓αÑç αñàαñ¬αñ╢αñ┐αñ╖αÑìαñƒ αñòαÑï αñ»αñ«αÑüαñ¿αñ╛ αñ«αÑçαñé αñ£αñ╛αñ¿αÑç αñ╕αÑç αñ░αÑïαñòαñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ αñÅαñ«αñ╕αÑÇαñíαÑÇ αñöαñ░ αñ¿αÑçαñ╢αñ¿αñ▓ αñíαÑçαñ»αñ░αÑÇ αñíαÑçαñ╡αñ▓αñ¬αñ«αÑçαñéαñƒ αñ¼αÑïαñ░αÑìαñí αñòαÑç αñ¼αÑÇαñÜ αñ╕αñ«αñ¥αÑîαññαñ╛ αñ╣αÑïαñùαñ╛αÑñ\n2:48\n2 minutes, 48 seconds\nαñëαñ¿αÑìαñ╣αÑïαñéαñ¿αÑç αñªαñ┐αñ▓αÑìαñ▓αÑÇ, αñ╣αñ░αñ┐αñ»αñ╛αñúαñ╛ αñöαñ░ αñëαññαÑìαññαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢ αñ╕αñ░αñòαñ╛αñ░αÑïαñé αñòαÑç αñ╕αñ╛αñÑ αñ╕αñ¡αÑÇ αñ╕αñéαñ¼αñéαñºαñ┐αññ αñ«αñéαññαÑìαñ░αñ╛αñ▓αñ»αÑïαñé αñòαÑï αñÅαñòαÑÇαñòαÑâαññ αñòαñ╛αñ░αÑìαñ» αñ»αÑïαñ£αñ¿αñ╛ αñòαÑç αññαñ╣αññ αñƒαÑÇαñ« αñ¡αñ╛αñ╡αñ¿αñ╛ αñ╕αÑç αñòαñ╛αñ« αñòαñ░αñ¿αÑç αñòαÑç αñ¡αÑÇ αñ¿αñ┐αñ░αÑìαñªαÑçαñ╢ αñªαñ┐αñÅαÑñ\n3:05\n3 minutes, 5 seconds\nαñ╕αñéαñ»αÑüαñòαÑìαññ αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░ αñ«αÑçαñé αñ¡αñ╛αñ░αññ αñòαÑç αñ╕αÑìαñÑαñ╛αñê αñ¬αÑìαñ░αññαñ┐αñ¿αñ┐αñºαñ┐ αñ░αñ╛αñ£αñªαÑéαññ αñ¬αÑÇ αñ╣αñ░αÑÇαñ╢ αñ¿αÑç αñàαñ½αñùαñ╛αñ¿αñ┐αñ╕αÑìαññαñ╛αñ¿ αñòαÑÇ αñ╕αÑìαñÑαñ┐αññαñ┐ αñ¬αñ░ αñ╣αÑüαñê αñ¼αÑêαñáαñò αñòαÑç αñªαÑîαñ░αñ╛αñ¿ αñ¬αñ╛αñòαñ┐αñ╕αÑìαññαñ╛αñ¿ αñ¬αñ░ αñ£αñ«αñòαñ░ αñ╣αñ«αñ▓αñ╛ αñ¼αÑïαñ▓αñ╛αÑñ αñ¬αÑÇ αñ╣αñ░αÑÇαñ╢ αñ¿αÑç αñ¬αñ╛αñòαñ┐αñ╕αÑìαññαñ╛αñ¿\n3:13\n3 minutes, 13 seconds\nαñòαÑç αñëαñ╕ αñ½αÑêαñ╕αñ▓αÑç αñòαÑÇ αñòαñíαñ╝αÑÇ αñ¿αñ┐αñéαñªαñ╛ αñòαÑÇ αñ£αñ┐αñ╕αñ«αÑçαñé αñëαñ╕αñ¿αÑç αñàαñ¬αñ¿αÑÇ αñ╕αÑÇαñ«αñ╛ αñòαÑç αñàαñéαñªαñ░ αñ«αÑîαñ£αÑéαñª αñ╕αñ«αÑéαñ╣αÑïαñé αñòαÑï αñ½αñ┐αññαñ¿αñ╛ αñàαñ▓ αñ╣αñ┐αñéαñªαÑüαñ╕αÑìαññαñ╛αñ¿ αñòαñ╣αñ╛ αñÑαñ╛αÑñ αñ¡αñ╛αñ░αññ αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñ»αñ╣\n3:22\n3 minutes, 22 seconds\nαñ¥αÑéαñá αñöαñ░ αñªαÑüαñ╖αÑìαñ¬αÑìαñ░αñÜαñ╛αñ░ αñ╣αÑêαÑñ αñ¬αñ╛αñòαñ┐αñ╕αÑìαññαñ╛αñ¿ αñ╕αñ░αñòαñ╛αñ░ αñªαÑìαñ╡αñ╛αñ░αñ╛ αñ½αÑçαñò αñ¿αÑêαñ░αÑçαñƒαñ┐αñ╡ αñ½αÑêαñ▓αñ╛αñ»αñ╛ αñ£αñ╛ αñ░αñ╣αñ╛ αñ╣αÑêαÑñ\n3:31\n3 minutes, 31 seconds\nαñ»αÑéαñÅαñ╕αñÅ αñ«αÑçαñé αñ¡αñ╛αñ░αññ αñ¿αÑç αñàαñ½αñùαñ╛αñ¿αñ┐αñ╕αÑìαññαñ╛αñ¿ αñ«αÑçαñé αñ¬αñ╛αñòαñ┐αñ╕αÑìαññαñ╛αñ¿ αñªαÑìαñ╡αñ╛αñ░αñ╛ αñòαñ┐αñÅ αñùαñÅ αñ╕αÑêαñ¿αÑìαñ» αñ╣αñ╡αñ╛αñê αñ╣αñ«αñ▓αÑïαñé αñòαÑÇ αñ¡αÑÇ αñåαñ▓αÑïαñÜαñ¿αñ╛ αñòαÑÇαÑñ αñëαñ¿αÑìαñ╣αÑïαñéαñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñàαñ¬αñ¿αÑÇ αñ¿αñ╛αñòαñ╛αñ«αñ┐αñ»αÑïαñé αñòαÑç αñ▓αñ┐αñÅ αñ¬αñíαñ╝αÑïαñ╕αñ┐αñ»αÑïαñé αñòαÑï αñªαÑïαñ╖ αñªαÑçαñ¿αñ╛\n3:39\n3 minutes, 39 seconds\nαñ¬αñ╛αñòαñ┐αñ╕αÑìαññαñ╛αñ¿ αñòαÑÇ αñ¬αÑüαñ░αñ╛αñ¿αÑÇ αñåαñªαññ αñ╣αÑêαÑñ αñªαÑüαñ¿αñ┐αñ»αñ╛ αñòαÑï αñùαÑüαñ«αñ░αñ╛αñ╣ αñòαñ░αñ¿αÑç αñòαÑÇ αñ»αñ╣ αñòαÑïαñ╢αñ┐αñ╢ αñ¿αñ╛αñòαñ╛αñ« αñ╣αÑïαñùαÑÇαÑñ\n3:52\n3 minutes, 52 seconds\nαñ¡αñ╛αñ░αññ αñòαÑÇ αñàαñºαÑìαñ»αñòαÑìαñ╖αññαñ╛ αñ«αÑçαñé αñ«αñºαÑìαñ» αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñçαñéαñªαÑîαñ░ αñ╢αñ╣αñ░ αñ«αÑçαñé αñ¼αÑìαñ░αñ┐αñòαÑìαñ╕ αñöαñ░ αñòαÑâαñ╖αñ┐ αñ«αñéαññαÑìαñ░αñ┐αñ»αÑïαñé αñòαÑÇ αñ«αñ╣αññαÑìαñ╡αñ¬αÑéαñ░αÑìαñú αñ¼αÑêαñáαñò αñåαñ£ αñ╕αÑç αñ╢αÑüαñ░αÑé αñ╣αÑïαñùαÑÇαÑñ\n3:57\n3 minutes, 57 seconds\nαñòαÑçαñéαñªαÑìαñ░αÑÇαñ» αñòαÑâαñ╖αñ┐ αñ«αñéαññαÑìαñ░αÑÇ αñ╢αñ┐αñ╡αñ░αñ╛αñ£ αñ╕αñ┐αñéαñ╣ αñÜαÑîαñ╣αñ╛αñ¿ αñ¿αÑç αñòαñ▓ αñ¬αÑìαñ░αÑçαñ╕ αñòαÑëαñ¿αÑìαñ½αÑìαñ░αÑçαñéαñ╕ αñòαñ░ αñçαñ╕αñòαÑç αñ¼αñ╛αñ░αÑç αñ«αÑçαñé αñ£αñ╛αñ¿αñòαñ╛αñ░αÑÇ αñªαÑÇαÑñ\n4:19\n4 minutes, 19 seconds\nαñöαñ░ αñçαñ╕αÑÇ αñ¼αÑÇαñÜ αñ╕αÑÇαñºαñ╛ αñ░αÑüαñû αñòαñ░αññαÑç αñ╣αÑêαñé αñçαñ╕ αñ╡αñòαÑìαññ αñòαÑÇ αñ╕αñ¼αñ╕αÑç αñ¼αñíαñ╝αÑÇ αñûαñ¼αñ░ αñòαñ╛ αñ¬αñ╢αÑìαñÜαñ┐αñ« αñ¼αñéαñùαñ╛αñ▓ αñ╕αÑç αñ£αñ╣αñ╛αñé αññαÑâαñúαñ«αÑéαñ▓ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñòαÑï αñÅαñò αñöαñ░ αñ¼αñíαñ╝αñ╛ αñ¥αñƒαñòαñ╛ αñ▓αñù αñùαñ»αñ╛ αñ╣αÑêαÑñ αñ£αÑÇ αñ╣αñ╛αñé, αññαÑâαñúαñ«αÑéαñ▓ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñòαÑç αñ¿αÑçαññαñ╛\n4:27\n4 minutes, 27 seconds\nαñ╕αñ╡αÑìαñ» αñ╕αñ╛αñéαñÜαÑÇ αñªαññαÑìαññαñ╛ αñòαÑï αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ░ αñ▓αñ┐αñ»αñ╛ αñùαñ»αñ╛ αñ╣αÑê αñöαñ░ αñ£αñ¼αñ░αñ¿ αñ╡αñ╕αÑéαñ▓αÑÇ αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñ╕αñ╡αÑìαñ» αñ╕αñ╛αñéαñÜαÑÇ αñªαññαÑìαññαñ╛ αñòαÑï αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛ αñ╣αÑê αñöαñ░ αñçαñ╕ αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñàαñùαñ░ αñ╣αñ« αñªαÑçαñûαÑçαñé αññαÑï αñòαñ░αÑïαñíαñ╝αÑïαñé αñòαÑÇ\n4:36\n4 minutes, 36 seconds\nαñ░αñéαñùαñªαñ╛αñ░αÑÇ αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñ»αñ╣ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░αÑÇ αñ╣αÑüαñê αñ╣αÑê αñöαñ░ αñçαñ╕ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░αÑÇ αñ╕αÑç αñòαñ╣αÑÇαñé αñ¿αñ╛ αñòαñ╣αÑÇαñé αññαÑâαñúαñ«αÑéαñ▓ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñ»αñ╛ αñ»αÑéαñé αñòαñ╣αÑçαñé αñòαñ┐ αñ«αñ«αññαñ╛ αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñòαÑï αñÅαñò αñöαñ░ αñ¼αñíαñ╝αñ╛ αñ¥αñƒαñòαñ╛ αñ▓αñùαñ╛ αñ£αñ╣αñ╛αñé αñ╡αñ┐αñºαñ╛αñ¿ αñ¿αñùαñ░ αñ¿αñùαñ░\n4:45\n4 minutes, 45 seconds\nαñ¿αñ┐αñùαñ« αñòαÑç αñÜαÑçαñ»αñ░αñ«αÑêαñ¿ αñ░αñ╣αÑç αñ╣αÑêαñé αñ╕αñ¡αÑìαñ» αñ╕αñ╛αñéαñÜαÑÇ αñªαññαÑìαññαñ╛ αñöαñ░ αñàαñ¼ αñëαñ¿αÑìαñ╣αÑçαñé αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛ αñ£αñ╛ αñÜαÑüαñòαñ╛ αñ╣αÑêαÑñ αññαÑï αñ»αñ╣ αñ╕αñ¼αñ╕αÑç αñ¼αñíαñ╝αÑÇ αñûαñ¼αñ░ αñåαñ¬αñòαÑï αñ¼αññαñ╛ αñ░αñ╣αÑç αñ╣αÑêαñéαÑñ\n4:53\n4 minutes, 53 seconds\nαñ£αñ╣αñ╛αñé αñªαñ┐αñùαÑìαñùαñ£ αñ¿αÑçαññαñ╛ αñòαÑç αññαÑîαñ░ αñ¬αñ░ αñ╕αñ¡αÑìαñ» αñ╕αñ╛αñéαñÜαÑÇ αñªαññαÑìαññαñ╛ αñòαÑï αñ£αñ╛αñ¿αñ╛ αñ£αñ╛αññαñ╛ αñ╣αÑêαÑñ αñ¬αñ╢αÑìαñÜαñ┐αñ« αñ¼αñéαñùαñ╛αñ▓ αñ«αÑçαñé αññαÑâαñúαñ«αÑéαñ▓ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñòαÑï αñÅαñò αñöαñ░ αñ¼αñíαñ╝αñ╛ αñ¥αñƒαñòαñ╛ αñçαñ╕ αñ╕αñ«αñ» αñ▓αñù αñÜαÑüαñòαñ╛ αñ╣αÑêαÑñ\n5:02\n5 minutes, 2 seconds\nαññαÑï αñ╡αñ┐αñºαñ╛αñ¿ αñ¿αñùαñ░ αñ¿αñùαñ░ αñ¿αñ┐αñùαñ« αñòαÑç αñÜαÑçαñ»αñ░αñ«αÑêαñ¿ αñ¡αÑÇ αñ╕αñ¡αÑìαñ» αñ╕αñ╛αñòαÑìαñ╖αÑÇ αñªαññαÑìαññαñ╛ αñ░αñ╣αÑç αñ╣αÑêαñé αñ£αÑï αñ£αñ┐αñ¿αÑìαñ╣αÑçαñé αñçαñ╕ αñ╕αñ«αñ» αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛ αñ£αñ╛ αñÜαÑüαñòαñ╛ αñ╣αÑêαÑñ αññαÑï αñ¼αñéαñùαñ╛αñ▓ αñ«αÑçαñé αññαÑâαñúαñ«αÑéαñ▓ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñòαÑï αñÅαñò αñöαñ░ αñ¼αñíαñ╝αñ╛ αñ¥αñƒαñòαñ╛ αñöαñ░\n5:11\n5 minutes, 11 seconds\nαñ£αñ¼αñ░αñ¿ αñ╡αñ╕αÑéαñ▓αÑÇ αñòαÑç αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñ╕αñ¡αÑìαñ» αñ╕αñ╛αñòαÑìαñ╖αÑÇ αñªαññαÑìαññαñ╛ αñòαÑï αñçαñ╕ αñ╕αñ«αñ» αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛ αñ╣αÑêαÑñ\n5:16\n5 minutes, 16 seconds\nαñ╣αñ╛αñ▓αñ╛αñéαñòαñ┐ αñçαñ╕αñ╕αÑç αñ¬αñ╣αñ▓αÑç αñàαñùαñ░ αñ╣αñ« αñªαÑçαñûαÑçαñé αññαÑï αñöαñ░ αñ¡αÑÇ αñòαñê αñ╕αñ╛αñ░αÑç αñ¿αÑçαññαñ╛αñôαñé αñòαÑï αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛ αñ£αñ╛ αñÜαÑüαñòαñ╛ αñ╣αÑê αññαÑâαñúαñ«αÑéαñ▓ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñòαÑç αñ£αñ┐αñ╕αñ«αÑçαñé αñÅαñò αñ¬αÑìαñ░αñ«αÑüαñû αñ¿αñ╛αñ« αñòαÑç αññαÑîαñ░ αñ¬αñ░ αñàαñùαñ░ αñ╣αñ« αñªαÑçαñûαÑçαñé αññαÑï αñ╡αñ╣ αñ╣αÑê\n5:23\n5 minutes, 23 seconds\nαñ£αñ╣αñ╛αñéαñùαÑÇαñ░ αñòαñ╛ αñ¿αñ╛αñ«αÑñ αññαÑï αñÉαñ╕αÑç αñ«αÑçαñé αñÅαñò-αñÅαñò αñòαñ░αñòαÑç αñ£αÑï αñ¬αñ┐αñ¢αñ▓αÑç 15 αñ╕αñ╛αñ▓αÑïαñé αñ╕αÑç αñ£αñ┐αñ¿ αñ▓αÑïαñùαÑïαñé αñòαÑï αñ╕αñéαñ░αñòαÑìαñ╖αñú αñ«αñ┐αñ▓αñ╛ αñ╣αÑüαñå αñÑαñ╛ αñàαñ¼ αñ╡αÑï αñ╕αñéαñ░αñòαÑìαñ╖αñú αñ╣αñƒαññαÑç αñ╣αÑÇ αñ╕αññαÑìαññαñ╛\n5:31\n5 minutes, 31 seconds\nαñ¬αñ░αñ┐αñ╡αñ░αÑìαññαñ¿ αñ£αÑêαñ╕αÑç αñ╣αÑÇ αñ╣αÑüαñå αñàαñ¼ αñ£αÑï αñòαñ╛αñ░αñ╡αñ╛αñê αñ╣αÑê αñ╡αÑï αñçαñ╕ αñ╕αñ«αñ» αññαÑçαñ£ αñ╣αÑï αñÜαÑüαñòαÑÇ αñ╣αÑê αñöαñ░ αñ¬αñ╢αÑìαñÜαñ┐αñ« αñ¼αñéαñùαñ╛αñ▓ αñ«αÑçαñé αññαÑâαñúαñ«αÑéαñ▓ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñòαÑï αñÅαñò αñöαñ░ αñ¼αñíαñ╝αñ╛ αñ¥αñƒαñòαñ╛\n5:38\n5 minutes, 38 seconds\nαñçαñ╕ αñ╕αñ«αñ» αñ▓αñù αñÜαÑüαñòαñ╛ αñ╣αÑêαÑñ αññαÑï αñÅαñò αññαñ░αñ½ αñàαñùαñ░ αñ╣αñ« αñªαÑçαñûαÑçαñé αññαÑï αññαÑâαñúαñ«αÑéαñ▓ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñ£αñ╣αñ╛αñé αñàαñéαñªαñ░ αñ¡αÑÇαññαñ░αñÿαñ╛αññ αñöαñ░ αñçαñ╕αñòαÑç αñ╕αñ╛αñÑ αñ╣αÑÇ αñ£αÑï αñƒαÑéαñƒ αñ╣αÑê αñëαñ╕αñòαÑï\n5:45\n5 minutes, 45 seconds\nαñ╕αñéαñ¡αñ╛αñ▓αñ¿αÑç αñ«αÑçαñé αñ£αÑüαñƒαÑÇ αñ╣αÑê αñ╡αñ╣αÑÇαñé αñªαÑéαñ╕αñ░αÑÇ αññαñ░αñ½ αñ£αÑï αñòαñ╛αñ¿αÑéαñ¿αÑÇ αñ╕αñéαñ░αñòαÑìαñ╖αñú αñ«αñ┐αñ▓αñ╛ αñ╣αÑüαñå αñÑαñ╛ αñ╡αÑï αñ¡αÑÇ αñ╣αñƒαññαÑç αñ╣αÑÇ αñàαñ¼ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░αñ┐αñ»αñ╛αñé αñ¡αÑÇ αñ▓αñùαñ╛αññαñ╛αñ░ αñ╣αÑï αñ░αñ╣αÑÇ αñ╣αÑêαÑñ\n5:52\n5 minutes, 52 seconds\nαñ£αñ¼αñ░αñ¿ αñ╡αñ╕αÑéαñ▓αÑÇ αñòαÑç αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñàαñ¼ αñ╕αñ¡αÑìαñ» αñ╕αñ╛αñéαñÜαÑÇ αñªαññαÑìαññαñ╛ αñòαÑï αñ¡αÑÇ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛ αñ£αñ╛ αñÜαÑüαñòαñ╛ αñ╣αÑêαÑñ\n5:57\n5 minutes, 57 seconds\nαñ£αñ¼αñ░αñ¿ αñ╡αñ╕αÑéαñ▓αÑÇ αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñ╕αñ¡αÑìαñ» αñ╕αñ╛αñéαñÜαÑÇ αñªαññαÑìαññαñ╛ αñòαÑï αñçαñ╕ αñ╕αñ«αñ» αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛ αñ╣αÑêαÑñ αñòαñ░αÑïαñíαñ╝αÑïαñé αñòαÑÇ αñ░αñéαñùαñªαñ╛αñ░αÑÇ αñòαñ╛ αñ»αñ╣ αñ¬αÑéαñ░αñ╛ αñ«αñ╛αñ«αñ▓αñ╛ αñ£αñ┐αñ╕αñ«αÑçαñé αñ£αñ╛αñéαñÜ αñ╣αÑüαñê αñöαñ░ αñëαñ╕αñòαÑç αñ¼αñ╛αñª αñ«αÑçαñé αñàαñ¼ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░αÑÇ αñ╣αÑï αñÜαÑüαñòαÑÇ αñ╣αÑêαÑñ\n6:07\n6 minutes, 7 seconds\nαñòαñ░αÑïαñíαñ╝αÑïαñé αñòαÑÇ αñ░αñéαñùαñªαñ╛αñ░αÑÇ αñ▓αÑçαñ¿αÑç αñòαñ╛ αñ╕αñ¡αÑìαñ» αñ╕αñ╛αñéαñÜαÑÇ αñªαññαÑìαññαñ╛ αñ¬αñ░ αñåαñ░αÑïαñ¬ αñ╣αÑêαÑñ αñ╡αñ┐αñºαñ╛αñ¿ αñ¿αñùαñ░ αñ¿αñùαñ░ αñ¿αñ┐αñùαñ« αñòαÑç αñÜαÑçαñ»αñ░αñ«αÑêαñ¿ αñ¡αÑÇ αñ░αñ╣αÑç αñ╣αÑêαñé αñ╕αñ¡αÑìαñ» αñ╕αñ╛αñéαñÜαÑÇ αñªαññαÑìαññαñ╛ αñöαñ░\n6:16\n6 minutes, 16 seconds\nαñëαñ¿αñòαÑÇ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░αÑÇ αñòαÑç αñ╕αñ╛αñÑ αñ╣αÑÇ αñ¬αñ╢αÑìαñÜαñ┐αñ« αñ¼αñéαñùαñ╛αñ▓ αñ«αÑçαñé αññαÑâαñúαñ«αÑéαñ▓ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñòαÑï αñ▓αñù αñÜαÑüαñòαñ╛ αñ╣αÑê αñÅαñò αñöαñ░ αñ¼αñíαñ╝αñ╛ αñ¥αñƒαñòαñ╛αÑñ αññαÑï αñÅαñò αñòαÑç αñ¼αñ╛αñª αñÅαñò αñòαñ╛αñ░αñ╡αñ╛αñê αñçαñ╕ αñ╕αñ«αñ»\n6:23\n6 minutes, 23 seconds\nαñ╣αÑï αñ░αñ╣αÑÇ αñ╣αÑêαÑñ αñ»αñ╣ αñ╕αñ¡αÑÇ αñòαñ╛αñ░αñ╡αñ╛αñê αñàαñùαñ░ αñ╣αñ« αñªαÑçαñûαÑçαñé αññαÑï αñ»αñ╣ αñëαñ¿ αñ▓αÑïαñùαÑïαñé αñ¬αñ░ αñ╣αÑï αñ░αñ╣αÑÇ αñ╣αÑê αñ£αÑï αñ¬αñ┐αñ¢αñ▓αÑç 15 αñ╕αñ╛αñ▓ αñ«αÑçαñé αñ¡αÑìαñ░αñ╖αÑìαñƒαñ╛αñÜαñ╛αñ░ αñ▓αñùαñ╛αññαñ╛αñ░ αñòαñ░αññαÑç αñ¿αñ£αñ░ αñåαñÅ αñÑαÑçαÑñ\n6:30\n6 minutes, 30 seconds\nαñ▓αÑçαñòαñ┐αñ¿ αññαñ¼ αññαñò αñàαñùαñ░ αñ╣αñ« αñªαÑçαñûαÑçαñé αññαÑï αñ╕αññαÑìαññαñ╛ αñòαñ╛ αñ╕αñéαñ░αñòαÑìαñ╖αñú αñëαñ¿αÑìαñ╣αÑçαñé αñ«αñ┐αñ▓αñ╛ αñ╣αÑüαñå αñÑαñ╛αÑñ αñ£αÑï αñ¬αñ┐αñ¢αñ▓αÑÇ αñ╕αñ░αñòαñ╛αñ░αÑçαñé αñÑαÑÇ αñëαñ¿αñòαñ╛ αñ╕αñéαñ░αñòαÑìαñ╖αñú αñÑαñ╛αÑñ αñ▓αÑçαñòαñ┐αñ¿ αñàαñ¼ αñ£αÑêαñ╕αÑç αñ╣αÑÇ αñ¬αñ╢αÑìαñÜαñ┐αñ« αñ¼αñéαñùαñ╛αñ▓ αñòαÑç αñàαñéαñªαñ░ αñ╕αññαÑìαññαñ╛\n6:38\n6 minutes, 38 seconds\nαñ¬αñ░αñ┐αñ╡αñ░αÑìαññαñ¿ αñ╣αÑüαñå αññαÑï αñàαñ¼ αñòαñ╛αñ░αñ╡αñ╛αñê αñ¡αÑÇ αñçαñ╕ αñ╕αñ«αñ» αññαÑçαñ£ αñ╣αÑï αñÜαÑüαñòαÑÇ αñ╣αÑê αñöαñ░ αñ£αñ┐αñ¿-αñ£αñ┐αñ¿ αñ▓αÑïαñùαÑïαñé αñ¿αÑç αñ¡αÑìαñ░αñ╖αÑìαñƒαñ╛αñÜαñ╛αñ░ αñòαñ┐αñ»αñ╛ αñ╣αÑê αñëαñ¿ αñ╕αñ¡αÑÇ αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñçαñ╕\n6:46\n6 minutes, 46 seconds\nαñ╕αñ«αñ» αñàαñ¼ αñÅαñò-αñÅαñò αñòαñ░αñòαÑç αñòαñ╛αñ░αñ╡αñ╛αñêαñ»αñ╛αñé αñòαÑÇ αñ£αñ╛ αñ░αñ╣αÑÇ αñ╣αÑêαñé αñöαñ░ αñçαñ╕αÑÇ αñòαñíαñ╝αÑÇ αñ«αÑçαñé αñàαñ¼ αñ╡αñ┐αñºαñ╛αñ¿ αñ¿αñùαñ░ αñ¿αñùαñ░ αñ¿αñ┐αñùαñ« αñòαÑç αñÜαÑçαñ»αñ░αñ«αÑêαñ¿ αñ░αñ╣αÑç αñ╣αÑêαñé αñöαñ░ αñàαñ¼ αñëαñ¿αñòαÑÇ\n6:53\n6 minutes, 53 seconds\nαñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░αÑÇ αñ¡αÑÇ αñ╣αÑï αñÜαÑüαñòαÑÇ αñ╣αÑêαÑñ αñ▓αÑçαñòαñ┐αñ¿ αñ£αñ╣αñ╛αñé αñÅαñò αññαñ░αñ½ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░αÑÇ αñ╕αñ¡αÑìαñ» αñ╕αñ╛αñéαñÜαÑÇ αñªαññαÑìαññαñ╛ αñòαÑÇ αñçαñ╕αñòαÑç αñ╕αñ╛αñÑ αñ╣αÑÇ αññαÑâαñúαñ«αÑéαñ▓ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñòαÑï αñÅαñò αñ¼αñíαñ╝αñ╛ αñ¥αñƒαñòαñ╛\n7:00\n7 minutes\nαñ¡αÑÇ αñ▓αñù αñÜαÑüαñòαñ╛ αñ╣αÑêαÑñ αññαÑï αñçαñ╕ αñ╕αñ«αñ» αñàαñùαñ░ αñ╣αñ« αñªαÑçαñûαÑçαñé αññαÑï αññαÑâαñúαñ«αÑéαñ▓ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñ¬αÑéαñ░αÑç αñ¡αñ╡αñ░ αñ«αÑçαñé αñ½αñéαñ╕αÑÇ αñ╣αÑüαñê αñ╣αÑêαÑñ αñÅαñò αññαñ░αñ½ αñàαñ¬αñ¿αÑç αñ╕αñ╛αñéαñ╕αñª αñöαñ░ αñàαñ¬αñ¿αÑç αñ╡αñ┐αñºαñ╛αñ»αñòαÑïαñé\n7:07\n7 minutes, 7 seconds\nαñòαÑï αñ£αÑïαñíαñ╝αÑç αñ░αñûαñ¿αÑç αñòαÑÇ αñÅαñò αñÜαÑüαñ¿αÑîαññαÑÇ αñçαñ╕ αñ╕αñ«αñ» αññαÑâαñúαñ«αÑéαñ▓ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñòαÑç αñ╕αñ╛αñ«αñ¿αÑç αñ╣αÑê αñöαñ░ αñ╡αñ╣αÑÇαñé αñªαÑéαñ╕αñ░αÑÇ αññαñ░αñ½ αñ£αÑï αñëαñ¿αñòαÑç αñ¿αÑçαññαñ╛ αñ£αÑï αñ¡αÑìαñ░αñ╖αÑìαñƒαñ╛αñÜαñ╛αñ░ αñ«αÑçαñé αñ¬αÑéαñ░αÑÇ αññαñ░αñ╣\n7:14\n7 minutes, 14 seconds\nαñ╕αÑç αñ▓αñ┐αñ¬αÑìαññ αñÑαÑç αñëαñ¿αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñ¡αÑÇ αñòαñ╛αñ░αñ╡αñ╛αñ»αñ╛ αñçαñ╕ αñ╕αñ«αñ» αññαÑçαñ£ αñ╣αÑï αñÜαÑüαñòαÑÇ αñ╣αÑêαÑñ αññαÑï αñÉαñ╕αÑç αñ«αÑçαñé αññαÑâαñúαñ«αÑéαñ▓ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñåαñûαñ┐αñ░ αñòαÑìαñ»αñ╛ αñòαñ░αÑçαñé αñöαñ░ αñòαÑêαñ╕αÑç αññαÑâαñúαñ«αÑéαñ▓ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñòαÑÇ αñ¿αÑêαñ»αñ╛ αñ¬αñ╛αñ░ αñ╣αÑïαñùαÑÇ αñ»αñ╣ αñªαÑçαñûαñ¿αÑç αñ╡αñ╛αñ▓αÑÇ\n7:22\n7 minutes, 22 seconds\nαñ¼αñ╛αññ αñ╣αÑïαñùαÑÇαÑñ αñ▓αÑçαñòαñ┐αñ¿ αñ½αñ┐αñ▓αñ╣αñ╛αñ▓ αñ»αñ╣ αñ╕αñ¼αñ╕αÑç αñ¼αñíαñ╝αÑÇ αñûαñ¼αñ░ αñåαñ¬ αññαñò αñ¬αñ╣αÑüαñéαñÜαñ╛ αñ░αñ╣αÑç αñ╣αÑêαñéαÑñ αñ╡αñ┐αñºαñ╛αñ¿ αñ¿αñùαñ░ αñ¿αñùαñ░ αñ¿αñ┐αñùαñ« αñòαÑç αñÜαÑçαñ»αñ░αñ«αÑêαñ¿ αñ░αñ╣αÑç αñ╣αÑêαñé αñ╕αñ¡αÑìαñ» αñ╕αñ╛αñéαñÜαÑÇ αñªαññαÑìαññαñ╛ αñ£αñ┐αñ¿αÑìαñ╣αÑçαñé αñçαñ╕ αñ╕αñ«αñ» αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛ αñ£αñ╛ αñÜαÑüαñòαñ╛ αñ╣αÑêαÑñ\n7:31\n7 minutes, 31 seconds\nαñ░αñéαñùαñªαñ╛αñ░αÑÇ αñòαÑç αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñëαñ¿αÑìαñ╣αÑçαñé αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛ αñ╣αÑêαÑñ αñ░αñéαñùαñªαñ╛αñ░αÑÇ αñ▓αÑçαñ¿αÑç αñòαñ╛ αñåαñ░αÑïαñ¬ αñ╣αÑê αñòαñ░αÑïαñíαñ╝αÑïαñé αñòαÑÇ αñ░αñéαñùαñªαñ╛αñ░αÑÇ αñöαñ░ αñçαñ╕αñòαÑç αñ╕αñ╛αñÑ αñ╣αÑÇ αñåαñ░αÑïαñ¬ αñòαÑç αñ╕αñ╛αñÑ αñ╣αÑÇ αñëαñ¿αñòαÑÇ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░αÑÇ αñçαñ╕ αñ╕αñ«αñ» αñ╣αÑï αñÜαÑüαñòαÑÇ αñ╣αÑêαÑñ\n7:47\n7 minutes, 47 seconds\nαññαÑï αñ£αñ¼αñ░αñ¿ αñ╡αñ╕αÑéαñ▓αÑÇ αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñ╕αñ¼ αñ╕αñ╛αñòαÑìαñ╖αÑÇ αñªαññαÑìαññαñ╛ αñòαÑï αñçαñ╕ αñ╕αñ«αñ» αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛ αñ╣αÑê αñöαñ░ αñ¼αñéαñùαñ╛αñ▓ αñ«αÑçαñé αññαÑâαñúαñ«αÑéαñ▓ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñòαÑï αñÅαñò αñöαñ░ αñ»αñ╣ αñ¼αñíαñ╝αñ╛ αñ¥αñƒαñòαñ╛ αñçαñ╕ αñ╕αñ«αñ» αñ▓αñù αñÜαÑüαñòαñ╛ αñ╣αÑêαÑñ αñ╣αñ╛αñ▓αñ╛αñéαñòαñ┐ αñçαñ╕αñ╕αÑç\n7:55\n7 minutes, 55 seconds\nαñ¬αñ╣αñ▓αÑç αñ¡αÑÇ αñàαñùαñ░ αñ╣αñ« αñªαÑçαñûαÑçαñé αññαÑï αñòαñê αñ╕αñ╛αñ░αÑÇ αñöαñ░ αñ¡αÑÇ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░αñ┐αñ»αñ╛αñé αñ╣αÑï αñÜαÑüαñòαÑÇ αñ╣αÑêαÑñ αññαÑâαñúαñ«αÑéαñ▓ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñòαÑç αñ£αÑï αñ¿αÑçαññαñ╛ αñ¡αÑìαñ░αñ╖αÑìαñƒαñ╛αñÜαñ╛αñ░ αñ«αÑçαñé αñ▓αñ┐αñ¬αÑìαññ αñÑαÑç αñöαñ░ αñàαñ¼ αññαñò αñ¬αñ┐αñ¢αñ▓αÑç 15 αñ╕αñ╛αñ▓αÑïαñé αñ╕αÑç αñòαñ╛αñ¿αÑéαñ¿αÑÇ αñ╕αñéαñ░αñòαÑìαñ╖αñú\n8:04\n8 minutes, 4 seconds\nαñëαñ¿αÑìαñ╣αÑçαñé αñ«αñ┐αñ▓αñ╛ αñ╣αÑüαñå αñÑαñ╛αÑñ αñ╕αññαÑìαññαñ╛ αñòαñ╛ αñ╕αñéαñ░αñòαÑìαñ╖αñú αñëαñ¿αÑìαñ╣αÑçαñé αñ«αñ┐αñ▓αñ╛ αñÑαñ╛αÑñ αñ▓αÑçαñòαñ┐αñ¿ αñàαñ¼ αñ¼αñªαñ▓αñ╛αñ╡ αñ╣αÑï αñÜαÑüαñòαñ╛ αñ╣αÑêαÑñ\n8:13\n8 minutes, 13 seconds\nαñÅαñò αñ¢αÑïαñƒαÑç αñ╕αÑç αñ¼αÑìαñ░αÑçαñò αñòαÑç αñ▓αñ┐αñÅ αñåαñ¬ αñ¼αñ¿αÑç αñ░αñ╣αñ┐αñÅ αñ╣αñ«αñ╛αñ░αÑç αñ╕αñ╛αñÑαÑñ\n8:22\n8 minutes, 22 seconds\nαñ«αÑçαñ░αÑÇ αñ¬αñ╕αñéαñª αñ«αÑçαñ░αÑÇ αñ¬αñ╕αñéαñª αñ«αÑçαñ░αÑÇ αñ¬αñ╕αñéαñª αñ«αÑçαñ░αÑÇ αñ¬αñ╕αñéαñªαÑñ\n8:32\n8 minutes, 32 seconds\nαñ╣αñ«αñ╛αñ░αÑÇ αñ¬αñ╕αñéαñª αñ╣αñ« αñ╕αñ¼αñòαÑÇ αñ¬αñ╕αñéαñªαÑñ αñ«αñ£αñ¼αÑéαññ αñªαÑçαñ╢ αñòαñ╛ αñ«αñ£αñ¼αÑéαññ αñ╕αñ░αñ┐αñ»αñ╛ αñ╣αÑï αñùαñ»αñ╛ αñ╕αÑìαñƒαÑÇαñ▓αÑñ\n8:39\n8 minutes, 39 seconds\nαñ╣αñ░ αñ£αÑÇαññ αñòαÑÇ αñ╢αÑüαñ░αÑüαñåαññ αñ╣αÑïαññαÑÇ αñ╣αÑê αñ¢αÑïαñƒαÑç-αñ¢αÑïαñƒαÑç αñòαñªαñ«αÑïαñé αñ╕αÑç αñöαñ░ αñ╣αñ░ αñ¢αÑïαñƒαÑÇ αññαÑêαñ»αñ╛αñ░αÑÇ αñ¼αñªαñ▓ αñ╕αñòαññαÑÇ αñ╣αÑê αñ¬αÑéαñ░αñ╛ αñ¿αññαÑÇαñ£αñ╛ αñòαÑìαñ»αÑïαñéαñòαñ┐ αñ«αÑêαñªαñ╛αñ¿ αñ╣αÑï αñ»αñ╛ αñ£αñ┐αñéαñªαñùαÑÇ αñ¢αÑïαñƒαÑÇ αñ╕αÑç\n8:48\n8 minutes, 48 seconds\nαñ¢αÑïαñƒαÑÇ αññαÑêαñ»αñ╛αñ░αÑÇ αñ╣αÑÇ αñªαÑçαññαÑÇ αñ╣αÑê αñ¬αÑìαñ░αÑïαñƒαÑçαñòαÑìαñ╢αñ¿ αñöαñ░ αñ¬αÑìαñ░αÑïαñƒαÑçαñòαÑìαñ╢αñ¿ αñ╣αÑÇ αñªαÑçαññαñ╛ αñ╣αÑê αñ¡αñ░αÑïαñ╕αñ╛ αñ£αÑêαñ╕αÑç LIC αñòαÑÇ αñ¼αÑÇαñ«αñ╛ αñ▓αñòαÑìαñ╖αÑìαñ«αÑÇ αñÅαñò αñûαñ╛αñ╕ αñ¬αÑìαñ▓αñ╛αñ¿ αñ╕αñ┐αñ░αÑìαñ½ αñ«αñ╣αñ┐αñ▓αñ╛αñôαñé\n8:58\n8 minutes, 58 seconds\nαñòαÑç αñ▓αñ┐αñÅ αñ£αñ╣αñ╛αñé αñ¢αÑïαñƒαÑÇ αñ¼αñÜαññ αñªαÑç αñ¼αñíαñ╝αÑÇ αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αññαñ╛αñòαñ┐ αñ£αñ┐αñéαñªαñùαÑÇ αñòαÑç αñ╣αñ░ αñ«αÑêαñªαñ╛αñ¿ αñ«αÑçαñé αñåαñ¬ αñ░αñ╣ αñ░αñ╣αÑç αñ╣αñ░ αñ¬αñ▓ αñòαÑç αñ▓αñ┐αñÅ αñ░αÑçαñíαÑÇ LIC αñ¼αÑÇαñ«αñ╛ αñ▓αñòαÑìαñ╖αÑìαñ«αÑÇ αñ░αñûαÑçαñé αñ╣αñ░\n9:07\n9 minutes, 7 seconds\nαñ¬αñ▓ αñòαÑç αñ▓αñ┐αñÅ αñ░αÑçαñíαÑÇ αñöαñ░ αñ¼αÑìαñ░αÑçαñò αñòαÑç αñ¼αñ╛αñª αñÅαñò αñ¼αñ╛αñ░ αñ½αñ┐αñ░ αñ╕αÑç αñ╕αÑìαñ╡αñ╛αñùαññ αñåαñ¬ αñ╕αñ¡αÑÇ αñòαñ╛ αñ╡αñ╛αñ¬αñ╕ αñ░αÑüαñò αñÅαñòαÑìαñ╕αñ¬αÑìαñ░αÑçαñ╕ 100 αñòαñ╛αÑñ\n9:19\n9 minutes, 19 seconds\nαñ¼αñ┐αñòαÑìαñ╕ αñòαÑâαñ╖αñ┐ αñ«αñéαññαÑìαñ░αñ┐αñ»αÑïαñé αñ¼αÑêαñáαñò αñ«αÑçαñé αñªαÑüαñ¿αñ┐αñ»αñ╛ αñòαÑç αñ¬αÑìαñ░αñ«αÑüαñû αñ¡αñ░αÑìαññαÑÇ αñàαñ░αÑìαñÑαñ╡αÑìαñ»αñ╡αñ╕αÑìαñÑαñ╛αñôαñé αñòαÑç αñòαÑâαñ╖αñ┐ αñ«αñéαññαÑìαñ░αÑÇ αñöαñ░ αñ¬αÑìαñ░αññαñ┐αñ¿αñ┐αñºαñ┐ αñ¡αñ╛αñù αñ▓αÑçαñéαñùαÑç αñöαñ░ αñ╡αÑêαñ╢αÑìαñ╡αñ┐αñò αñûαñ╛αñªαÑìαñ» αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛, αñ£αñ▓αñ╡αñ╛αñ»αÑü αñ¬αñ░αñ┐αñ╡αñ░αÑìαññαñ¿ αñöαñ░\n9:28\n9 minutes, 28 seconds\nαñòαñ┐αñ╕αñ╛αñ¿αÑïαñé αñòαÑç αñ¡αñ╡αñ┐αñ╖αÑìαñ» αñ£αÑêαñ╕αÑç αñàαñ╣αñ« αñ«αÑüαñªαÑìαñªαÑïαñé αñ¬αñ░ αñ«αñéαñÑαñ¿ αñ╣αÑïαñùαñ╛αÑñ\n9:33\n9 minutes, 33 seconds\n9 αñ╕αÑç 11 αñ£αÑéαñ¿ αññαñò αñ£αñ╣αñ╛αñé αñ¼αÑìαñ░αñ┐αñòαÑìαñ╕ αñ╕αñ«αÑéαñ╣ αñòαÑç αñ╕αñªαñ╕αÑìαñ» αñªαÑçαñ╢αÑïαñé αñòαÑç αñàαñºαñ┐αñòαñ╛αñ░αÑÇ αñ«αñéαñÑαñ¿ αñòαñ░αÑçαñéαñùαÑç αññαÑï αñ╡αñ╣αÑÇαñé αñ╡αñ┐αñ╢αÑìαñ╡ αñòαÑâαñ╖αñ┐ αñ«αñéαññαÑìαñ░αñ┐αñ»αÑïαñé αñòαÑÇ αñ¼αÑêαñáαñò αñçαñéαñªαÑîαñ░ αñ«αÑçαñé αñ╣αÑÇ 12 αñöαñ░ 13 αñ£αÑéαñ¿ αñòαÑï αñ╣αÑïαñùαÑÇαÑñ\n9:44\n9 minutes, 44 seconds\nαñ¼αÑêαñáαñò αñ«αÑçαñé αñûαñ╛αñªαÑìαñ» αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñöαñ░ αñ¬αÑïαñ╖αñú αñòαÑç αñ╕αñ╛αñÑ-αñ╕αñ╛αñÑ αñòαñ┐αñ╕αñ╛αñ¿αÑïαñé αñòαÑÇ αñåαñ», αñ░αÑïαñ£αñùαñ╛αñ░, αñåαñ£αÑÇαñ╡αñ┐αñòαñ╛ αññαñÑαñ╛ αñ╕αññαññ αñòαÑâαñ╖αñ┐ αñ╡αñ┐αñòαñ╛αñ╕ αñ£αÑêαñ╕αÑç αñàαñ¿αÑçαñò αñ«αñ╣αññαÑìαñ╡αñ¬αÑéαñ░αÑìαñú αñ«αÑüαñªαÑìαñªαÑïαñé αñ¬αñ░ αñ¡αÑÇ αñ╡αÑìαñ»αñ╛αñ¬αñò αñÜαñ░αÑìαñÜαñ╛ αñòαÑÇ αñ£αñ╛αñÅαñùαÑÇαÑñ\n9:56\n9 minutes, 56 seconds\nαñòαÑçαñéαñªαÑìαñ░αÑÇαñ» αñ╕αÑìαñ╡αñ╛αñ╕αÑìαñÑαÑìαñ» αñ¬αñ░αñ┐αñ╡αñ╛αñ░ αñòαñ▓αÑìαñ»αñ╛αñú αñ«αñéαññαÑìαñ░αÑÇ αñ£αÑçαñ¬αÑÇ αñ¿αñíαÑìαñíαñ╛ αñåαñ£ αñ¿αñê αñªαñ┐αñ▓αÑìαñ▓αÑÇ αñ«αÑçαñé αñ¬αÑìαñ░αñºαñ╛αñ¿αñ«αñéαññαÑìαñ░αÑÇ αñ╕αÑüαñ░αñòαÑìαñ╖αñ┐αññ αñ«αñ╛αññαÑâαññαÑìαñ╡ αñàαñ¡αñ┐αñ»αñ╛αñ¿ αñòαÑç 10 αñ╡αñ░αÑìαñ╖ αñ¬αÑéαñ░αÑç αñ╣αÑïαñ¿αÑç αñòαÑç αñàαñ╡αñ╕αñ░ αñ¬αñ░ αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ╡αÑìαñ»αñ╛αñ¬αÑÇ αñ╕αñ«αñ╛αñ░αÑïαñ╣ αñòαñ╛\n10:05\n10 minutes, 5 seconds\nαñ╢αÑüαñ¡αñ╛αñ░αñéαñ¡ αñòαñ░αÑçαñéαñùαÑçαÑñ αñçαñ╕ αñàαñ¡αñ┐αñ»αñ╛αñ¿ αñòαñ╛ αñëαñªαÑìαñªαÑçαñ╢αÑìαñ» αñ╕αÑüαñ░αñòαÑìαñ╖αñ┐αññ αñùαñ░αÑìαñ¡αñ╛αñ╡αñ╕αÑìαñÑαñ╛ αñöαñ░ αñ«αñ╛αññαÑâαññαÑìαñ╡ αñòαÑï αñ╕αÑüαñ¿αñ┐αñ╢αÑìαñÜαñ┐αññ αñòαñ░αñ¿αñ╛αÑñ\n10:12\n10 minutes, 12 seconds\nαñ╕αñ«αñ╛αñ░αÑïαñ╣ αñòαÑç αñªαÑîαñ░αñ╛αñ¿ αñòαÑçαñéαñªαÑìαñ░αÑÇαñ» αñ«αñéαññαÑìαñ░αÑÇ αñ£αÑçαñ¬αÑÇ αñ¿αñíαÑìαñíαñ╛ Γé╣75 αñòαñ╛ αñ╕αÑìαñ«αñ╛αñ░αñò αñ╕αñ┐αñòαÑìαñòαñ╛ αñöαñ░ Γé╣5 αñòαñ╛ αñíαñ╛αñò αñƒαñ┐αñòαñƒ αñ¡αÑÇ αñ£αñ╛αñ░αÑÇ αñòαñ░αÑçαñéαñùαÑçαÑñ αñ¬αÑìαñ░αñºαñ╛αñ¿αñ«αñéαññαÑìαñ░αÑÇ\n10:20\n10 minutes, 20 seconds\nαñ╕αÑüαñ░αñòαÑìαñ╖αñ┐αññ αñ«αñ╛αññαÑâαññαÑìαñ╡ αñ»αÑïαñ£αñ¿αñ╛ αñòαÑç αññαñ╣αññ αñùαñúαñ¬αññαñ┐ αñ«αñ╣αñ┐αñ▓αñ╛αñôαñé αñòαÑï αñ«αÑüαñ½αÑìαññ αñöαñ░ αñùαÑüαñúαñ╡αññαÑìαññαñ╛αñ¬αÑéαñ░αÑìαñú αñ¬αÑìαñ░αñ╕αñ╡ αñ¬αÑéαñ░αÑìαñ╡ αñ╕αÑìαñ╡αñ╛αñ╕αÑìαñÑαÑìαñ» αñ╕αÑçαñ╡αñ╛αñÅαñé αñªαÑÇ αñ£αñ╛αññαÑÇ αñ╣αÑêαñéαÑñ\n10:29\n10 minutes, 29 seconds\nαñ╕αÑìαñ╡αñ╛αñ╕αÑìαñÑαÑìαñ» αñÅαñ╡αñé αñ¬αñ░αñ┐αñ╡αñ╛αñ░ αñòαñ▓αÑìαñ»αñ╛αñú αñ«αñéαññαÑìαñ░αñ╛αñ▓αñ» αñòαÑÇ αñôαñ░ αñ╕αÑç αñòαñ▓ αñàαñéαññαñ░αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αÑÇαñ» αñ╕αñ«αñ╛αñÜαñ╛αñ░ αñÅαñ£αÑçαñéαñ╕αñ┐αñ»αÑïαñé αñöαñ░ αñ╡αñ┐αñªαÑçαñ╢ αñ╡αñ┐αñªαÑçαñ╢αÑÇ αñ«αÑÇαñíαñ┐αñ»αñ╛ αñ╕αñéαñùαñáαñ¿αÑïαñé αñòαÑç αñ¬αññαÑìαñ░αñòαñ╛αñ░αÑïαñé αñòαÑç αñ╕αñ╛αñÑ αñ╡αñ┐αñ╢αÑçαñ╖ αñ¼αÑêαñáαñò αñòαÑÇ αñùαñêαÑñ αñçαñ╕\n10:38\n10 minutes, 38 seconds\nαñªαÑîαñ░αñ╛αñ¿ αñÅαñ¿αñÅαñ½αñÅαñÜαñÅαñ╕ αñ»αñ╛αñ¿αÑÇ αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αÑÇαñ» αñ¬αñ░αñ┐αñ╡αñ╛αñ░ αñ╕αÑìαñ╡αñ╛αñ╕αÑìαñÑαÑìαñ» αñ╕αñ░αÑìαñ╡αÑçαñòαÑìαñ╖αñú αñ¢αñ╣ αñòαÑç αñ¿αñ┐αñ╖αÑìαñòαñ░αÑìαñ╖αÑïαñé αñ¬αñ░ αñ¡αÑÇ αñÜαñ░αÑìαñÜαñ╛ αñòαÑÇ αñùαñêαÑñ\n10:49\n10 minutes, 49 seconds\nαñÜαñ░αÑìαñÜαñ╛ αñ«αÑçαñé αñ«αñ╛αññαÑâ αñÅαñ╡αñé αñ╢αñ┐αñ╢αÑü αñ╕αÑìαñ╡αñ╛αñ╕αÑìαñÑαÑìαñ» αñ¬αÑïαñ╖αñú αñ╕αÑìαñ╡αñ╛αñ╕αÑìαñÑαÑìαñ» αñ╕αÑçαñ╡αñ╛ αñ«αÑçαñé αñÅαñåαñê αñ£αÑêαñ╕αÑç αñòαñê αñ«αÑüαñªαÑìαñªαÑç αñ╢αñ╛αñ«αñ┐αñ▓ αñÑαÑçαÑñ αñ╕αñ░αÑìαñ╡αÑçαñòαÑìαñ╖αñú αñòαÑç αñ¿αññαÑÇαñ£αÑïαñé αñòαÑç αñàαñ¿αÑüαñ╕αñ╛αñ░ αñ¡αñ╛αñ░αññ αñòαÑÇ αñòαÑüαñ▓ αñ¬αÑìαñ░αñ£αñ¿αñ¿ αñªαñ░ 2.0 αñ¬αñ░ αñ╕αÑìαñÑαñ┐αñ░ αñ╣αÑêαÑñ\n10:59\n10 minutes, 59 seconds\nαñ£αñ¼αñòαñ┐ αñ╕αñéαñ╕αÑìαñÑαñ╛αñùαññ αñ╕αñéαñ¬αñ░αÑìαñò αñòαñ░ 90.6% αñ╣αÑï αñùαñêαÑñ\n11:06\n11 minutes, 6 seconds\nαñ¬αñéαñÜαñ╛αñ»αññαÑÇ αñ░αñ╛αñ£ αñ«αñéαññαÑìαñ░αñ╛αñ▓αñ» αñåαñ£ αñùαÑüαñ£αñ░αñ╛αññ αñòαÑç αñùαñ╛αñéαñºαÑÇαñ¿αñùαñ░ αñ«αÑçαñé αñÅαñò αñ£αñ¿αñ╕αñéαñ¬αñ░αÑìαñò αñòαñ╛αñ░αÑìαñ»αñ╢αñ╛αñ▓αñ╛ αñÅαñ╡αñé αñåαññαÑìαñ«αñ¿αñ┐αñ░αÑìαñ¡αñ░ αñ¬αñéαñÜαñ╛αñ»αññ αñòαñ╛αñ░αÑìαñ»αñòαÑìαñ░αñ« αñòαñ╛ αñåαñ»αÑïαñ£αñ¿ αñòαñ░αÑçαñùαñ╛αÑñ αñ╣αñ╛αñçαñ¼αÑìαñ░αñ┐αñí αñ«αÑïαñí αñ«αÑçαñé αñåαñ»αÑïαñ£αñ┐αññ αñçαñ╕\n11:14\n11 minutes, 14 seconds\nαñ╡αñ░αÑìαñòαñ╢αÑëαñ¬ αñ«αÑçαñé αñ╡αÑÇαñíαñ┐αñ»αÑï αñòαÑëαñ¿αÑìαñ½αÑìαñ░αÑçαñéαñ╕αñ┐αñéαñù αñòαÑç αñ£αñ░αñ┐αñÅ αñ¬αÑéαñ░αÑç αñùαÑüαñ£αñ░αñ╛αññ αñòαÑç αñ¬αñ╛αññαÑìαñ░ αñùαÑìαñ░αñ╛αñ« αñ¬αñéαñÜαñ╛αñ»αññ αñöαñ░ αñ¼αÑìαñ▓αÑëαñò αñ¬αñéαñÜαñ╛αñ»αññ αñ╢αñ╛αñ«αñ┐αñ▓ αñ╣αÑïαñéαñùαÑçαÑñ\n11:25\n11 minutes, 25 seconds\nαñ¬αÑçαñƒαÑìαñ░αÑïαñ▓αñ┐αñ»αñ« αñ«αñéαññαÑìαñ░αÑÇ αñ╣αñ░αñªαÑÇαñ¬ αñ╕αñ┐αñéαñ╣ αñ¬αÑüαñ░αÑÇ αñ¿αÑç αñíαÑÇαñíαÑÇ αñ¿αÑìαñ»αÑéαñ£αñ╝ αñòαÑç αñ╕αñ╛αñÑ αñûαñ╛αñ╕ αñ¬αñíαñòαñ╛αñ╕αÑìαñƒ αñ«αÑçαñé αñ¼αññαñ╛αñ»αñ╛ αñòαñ┐ αñ£αñ╛αñ¬αñ╛αñ¿ αñòαÑç αñ¼αñ╛αñª αñ¡αñ╛αñ░αññ αñ«αÑçαñé αññαÑçαñ▓ αñòαÑÇαñ«αññαÑïαñé αñ«αÑçαñé αñ╕αñ¼αñ╕αÑç αñòαñ« αñ¼αñóαñ╝αÑïαññαñ░αÑÇ αñ╣αÑüαñê αñ╣αÑêαÑñ αñåαñ« αñ▓αÑïαñùαÑïαñé αñ¬αñ░ αñ¼αÑïαñ¥\n11:33\n11 minutes, 33 seconds\nαñ¿αñ╛ αñ¬αñíαñ╝αÑç αñçαñ╕αñòαÑç αñ▓αñ┐αñÅ αñòαÑçαñéαñªαÑìαñ░ αñ╕αñ░αñòαñ╛αñ░ αñ¿αÑç αñ╕αÑçαñéαñƒαÑìαñ░αñ▓ αñÅαñòαÑìαñ╕αñ╛αñçαñ£ αñíαÑìαñ»αÑéαñƒαÑÇ αñòαÑï αññαÑÇαñ¿ αñ¼αñ╛αñ░ αñÿαñƒαñ╛αñ»αñ╛ αñ╣αÑêαÑñ\n11:39\n11 minutes, 39 seconds\nαñòαñ▓ αñªαñ┐αñ▓αÑìαñ▓αÑÇ αñ«αÑçαñé αñ╣αÑüαñê αñÅαñ¿αñíαÑÇ αñùαñáαñ¼αñéαñºαñ¿ αñòαÑÇ αñ¼αÑêαñáαñò αñ¬αñ░ αñòαÑçαñéαñªαÑìαñ░αÑÇαñ» αñ«αñéαññαÑìαñ░αÑÇ αñ╣αñ░αñªαÑÇαñ¬ αñ╕αñ┐αñéαñ╣ αñ¬αÑüαñ░αÑÇ αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñ╡αñ┐αñ¬αñòαÑìαñ╖ αñàαñ¬αñ¿αÑç αñ╣αÑÇ αñ╡αñ┐αñ░αÑïαñºαñ╛αñ¡αñ╛αñ╕αÑïαñé αñòαÑç αñ¼αÑïαñ¥ αññαñ▓αÑç αñíαñ╣ αñ░αñ╣αñ╛ αñ╣αÑêαÑñ αñëαñ«αÑìαñ«αÑÇαñª αñ£αññαñ╛αñê αñòαñ┐ αñàαñùαñ▓αÑç αñ╕αñ╛αñ▓ αñ½αñ┐αñ░\n11:48\n11 minutes, 48 seconds\nαñëαññαÑìαññαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢ αñ«αÑçαñé αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñòαÑÇ αñ£αñ¼αñ░αñªαñ╕αÑìαññ αñ£αÑÇαññ αñ╣αÑïαñùαÑÇαÑñ\n11:54\n11 minutes, 54 seconds\nαñ¬αñ╢αÑìαñÜαñ┐αñ« αñ¼αñéαñùαñ╛αñ▓ αñ«αÑçαñé αñ¿αÑçαññαñ╛ αñ¬αÑìαñ░αññαñ┐αñ¬αñòαÑìαñ╖ αñòαÑç αñ¬αñª αñòαÑï αñ▓αÑçαñòαñ░ αñ╡αñ┐αñ╡αñ╛αñª αñòαÑç αñ¼αÑÇαñÜ αñ«αñ«αññαñ╛ αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñòαÑÇ αñ¬αñ╛αñ░αÑìαñƒαÑÇ αñòαÑç αñ╕αñéαñ╕αñª αñ«αÑçαñé αñàαñ╕αÑìαññαñ┐αññαÑìαñ╡ αñòαñ╛ αñ¼αñíαñ╝αñ╛ αñ╕αñéαñòαñƒ αñûαñíαñ╝αñ╛ αñ╣αÑï αñùαñ»αñ╛ αñ╣αÑêαÑñ αñåαñéαññαñ░αñ┐αñò αñòαñ▓αñ╣ αñòαÑç αñ¼αñ╛αñª αñ╕αñéαñ╕αñª αñ«αÑçαñé αñ¬αñ╛αñ░αÑìαñƒαÑÇ αñòαÑÇ αñ╕αÑìαñÑαñ┐αññαñ┐ αñ«αÑüαñ╢αÑìαñòαñ┐αñ▓ αñ╣αÑï αñ╕αñòαññαÑÇ αñ╣αÑêαÑñ\n12:08\n12 minutes, 8 seconds\nαñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ¿αÑç αñòαñ▓ αñ¬αñ╢αÑìαñÜαñ┐αñ« αñ¼αñéαñùαñ╛αñ▓ αñ╡αñ┐αñºαñ╛αñ¿αñ╕αñ¡αñ╛ αñàαñºαÑìαñ»αñòαÑìαñ╖αÑïαñé αñòαÑç αñëαñ╕ αñ½αÑêαñ╕αñ▓αÑç αñòαÑïαñ▓αñòαñ╛αññαñ╛ αñëαñÜαÑìαñÜ αñ¿αÑìαñ»αñ╛αñ»αñ╛αñ▓αñ» αñ«αÑçαñé αñÜαÑüαñ¿αÑîαññαÑÇ αñªαÑÇ αñ£αñ┐αñ╕αñ«αÑçαñé αñ¬αñ╛αñ░αÑìαñƒαÑÇ αñòαÑç αñÅαñò αñàαñ▓αñù αñùαÑüαñƒ αñòαÑç αñ¿αÑçαññαñ╛ αñ╡αñ┐αñªαÑìαñ╡αññ αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñòαÑï αñ¿αÑçαññαñ╛ αñ¬αÑìαñ░αññαñ┐αñ¬αñòαÑìαñ╖ αñòαÑç αñ░αÑéαñ¬ αñ«αÑçαñé αñ«αñ╛αñ¿αÑìαñ»αññαñ╛ αñªαÑÇ αñùαñêαÑñ\n12:19\n12 minutes, 19 seconds\nαññαÑâαñúαñ«αÑéαñ▓ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñòαÑç αñ╡αñ░αñ┐αñ╖αÑìαñá αñ╡αñ┐αñºαñ╛αñ»αñò αñ╢αÑüαñ¡αñªαÑçαñ╡ αñÜαñƒαÑìαñƒαÑïαñ¬αñ╛αñºαÑìαñ»αñ╛αñ» αñ¿αÑç αñòαÑïαñ▓αñòαñ╛αññαñ╛ αñëαñÜαÑìαñÜ αñ¿αÑìαñ»αñ╛αñ»αñ╛αñ▓αñ» αñòαñ╛ αñªαñ░αñ╡αñ╛αñ£αñ╛ αñûαñƒαñûαñƒαñ╛αñ»αñ╛αÑñ αñ╡αñ╣αÑÇαñé αñ»αñ╛αñÜαñ┐αñòαñ╛ αñ«αÑçαñé αñåαñ░αÑïαñ¬ αñòαñ┐αñ»αñ╛ αñ╣αÑê αñòαñ┐ αñ╡αñ┐αñºαñ╛αñ¿αñ╕αñ¡αñ╛ αñàαñºαÑìαñ»αñòαÑìαñ╖ αñ¿αÑç αñ░αñ╛αñ£αñ¿αÑÇαññαñ┐αñò\n12:27\n12 minutes, 27 seconds\nαñªαñ▓ αñòαÑç αñ╕αñ«αñ░αÑìαñÑαñ¿ αñòαÑç αñ¼αñ┐αñ¿αñ╛ αñ╣αÑÇ αñ¿αÑçαññαñ╛ αñ¬αÑìαñ░αññαñ┐αñ¬αñòαÑìαñ╖ αñòαÑÇ αñ¿αñ┐αñ»αÑüαñòαÑìαññαñ┐ αñòαñ░ αñªαÑÇαÑñ αññαÑâαñúαñ«αÑéαñ▓ αñòαÑç 80 αñ╡αñ┐αñºαñ╛αñ»αñòαÑïαñé αñ«αÑçαñé αñ╕αÑç 58 αñ¿αÑçαññαñ╛ αñ¬αÑìαñ░αññαñ┐αñ¬αñòαÑìαñ╖ αñ¬αñª αñòαÑç αñ▓αñ┐αñÅ\n12:34\n12 minutes, 34 seconds\nαñ╡αñ┐αñ╡αÑìαñ░αññ αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñòαñ╛ αñ╕αñ«αñ░αÑìαñÑαñ¿ αñòαñ┐αñ»αñ╛ αñÑαñ╛ αñöαñ░ αñ¬αñ╛αñ░αÑìαñƒαÑÇ αñòαñ╛ αñàαñºαñ┐αñòαñ╛αñ░αñ┐αñò αñëαñ«αÑìαñ«αÑÇαñªαñ╡αñ╛αñ░ αñ╢αÑïαñ¡αñ¿ αñªαÑçαñ╡ αñÜαñƒαÑìαñƒαÑïαñ¬αñ╛αñºαÑìαñ»αñ╛αñ» αñòαÑï αñûαñ╛αñ░αñ┐αñ£ αñòαñ░ αñªαñ┐αñ»αñ╛αÑñ\n12:43\n12 minutes, 43 seconds\nαñ«αñ╛αñ«αñ▓αÑç αñ¬αñ░ αñ╕αÑüαñ¿αñ╡αñ╛αñê αñòαñ░αññαÑç αñ╣αÑüαñÅ αñ¿αÑìαñ»αñ╛αñ»αñ«αÑéαñ░αÑìαññαñ┐ αñòαÑâαñ╖αÑìαñú αñ░αñ╛αñ╡ αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñçαñ╕ αñ»αñ╛αñÜαñ┐αñòαñ╛ αñ¬αñ░ 11 αñ£αÑéαñ¿ αñòαÑï αñ╕αÑüαñ¿αñ╡αñ╛αñê αñ╣αÑïαñùαÑÇαÑñ αñ╕αñ╛αñÑ αñ╣αÑÇ αñ»αñ╛αñÜαñ┐αñòαñ╛αñòαñ░αÑìαññαñ╛ αñòαÑï αñ¿αñ┐αñ░αÑìαñªαÑçαñ╢ αñªαñ┐αñ»αñ╛ αñùαñ»αñ╛ αñòαñ┐ αñ╡αñ╣ αñ«αñ╛αñ«αñ▓αÑç αñ╕αÑç αñ£αÑüαñíαñ╝αÑç αñ╕αñ¡αÑÇ αñ¬αñòαÑìαñ╖αÑïαñé αñòαÑï αñ¿αÑïαñƒαñ┐αñ╕ αñ£αñ╛αñ░αÑÇ αñòαñ░αÑçαñéαÑñ\n12:55\n12 minutes, 55 seconds\nαñƒαÑÇαñÅαñ«αñ╕αÑÇ αñòαÑç αñ╡αñ░αñ┐αñ╖αÑìαñá αñ¿αÑçαññαñ╛ αñöαñ░ αñ▓αÑïαñòαñ╕αñ¡αñ╛ αñ╕αñ╛αñéαñ╕αñª αñòαñ╛αñòαÑüαñ▓αÑÇ αñÿαÑïαñ╖ αñªαñ╕αÑìαññαÑçαñªαñ╛αñ░ αñ¿αÑç αñ«αÑüαñûαÑìαñ»αñ«αñéαññαÑìαñ░αÑÇ αñ«αñ«αññαñ╛ αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñ¬αñ░ αñùαñéαñ¡αÑÇαñ░ αñåαñ░αÑïαñ¬ αñ▓αñùαñ╛αññαÑç αñ╣αÑüαñÅ αñàαñ¬αñ¿αÑÇ αñ╣αÑÇ αñ¬αñ╛αñ░αÑìαñƒαÑÇ αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñ«αÑïαñ░αÑìαñÜαñ╛ αñûαÑïαñ▓ αñªαñ┐αñ»αñ╛αÑñ\n13:02\n13 minutes, 2 seconds\nαñëαñ¿αÑìαñ╣αÑïαñéαñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ 40 αñ╕αñ╛αñ▓ αññαñò αñ«αñ«αññαñ╛ αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñòαñ╛ αñ╕αñ╛αñÑ αñªαÑçαñ¿αÑç αñòαÑç αñ¼αñ╛αñ╡αñ£αÑéαñª αñ¬αñ╛αñ░αÑìαñƒαÑÇ αñ«αÑçαñé αñëαñ¿αÑìαñ╣αÑçαñé αñ¬αÑéαñ░αÑÇ αññαñ░αñ╣ αñ╕αÑç αñòαñ┐αñ¿αñ╛αñ░αÑç αñòαñ░ αñªαñ┐αñ»αñ╛ αñùαñ»αñ╛αÑñ\n13:12\n13 minutes, 12 seconds\nαñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ╕αñ╛αñéαñ╕αñª αñòαñ╛αñòαÑïαñ░αÑÇ αñÿαÑïαñ╖ αñ¿αÑç 20 αñ¼αñ╛αñùαÑÇ αñ╕αñ╛αñéαñ╕αñªαÑïαñé αñòαÑç αñ╕αñ╛αñÑ αñ▓αÑïαñòαñ╕αñ¡αñ╛ αñàαñºαÑìαñ»αñòαÑìαñ╖ αñ╕αÑç αñàαñ▓αñù αñ¼αÑêαñáαñ¿αÑç αñòαÑÇ αñ╡αÑìαñ»αñ╡αñ╕αÑìαñÑαñ╛ αñòαÑÇ αñ«αñ╛αñéαñù αñòαÑÇαÑñ αññαÑï αñ╡αñ╣αÑÇαñé αñëαñ¿αÑìαñ╣αÑïαñéαñ¿αÑç αñªαÑçαñ╢ αñöαñ░ αñ¼αñéαñùαñ╛αñ▓ αñòαÑÇ αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñòαÑï αñàαñ¬αñ¿αñ╛\n13:19\n13 minutes, 19 seconds\nαñ╕αñ¼αñ╕αÑç αñàαñ╣αñ« αñ«αÑüαñªαÑìαñªαñ╛ αñ¼αññαñ╛αññαÑç αñ╣αÑüαñÅ αñ¡αñ╡αñ┐αñ╖αÑìαñ» αñòαÑÇ αñ░αñ╛αñ£αñ¿αÑÇαññαñ┐αñò αñ░αñúαñ¿αÑÇαññαñ┐ αñ¬αñ░ αñ╕αñ╕αÑìαñ¬αÑçαñéαñ╕ αñ¼αñ░αñòαñ░αñ╛αñ░ αñ░αñûαñ╛ αñ╣αÑêαÑñ αñçαñ╕αñ╕αÑç αñ¬αñ╣αñ▓αÑç 58 αñ╡αñ┐αñºαñ╛αñ»αñòαÑïαñé αñ¿αÑç αñ¡αÑÇ αñ╡αñ┐αñºαñ╛αñ¿αñ╕αñ¡αñ╛ αñ«αÑçαñé αñàαñ▓αñù αñ╡αñ┐αñ¬αñòαÑìαñ╖αÑÇ αñ╕αñ«αÑéαñ╣ αñòαÑç αñ░αÑéαñ¬ αñ«αÑçαñé αñ«αñ╛αñ¿αÑìαñ»αññαñ╛ αñ¬αÑìαñ░αñ╛αñ¬αÑìαññ αñòαÑÇ αñ╣αÑêαÑñ\n13:32\n13 minutes, 32 seconds\nαñ¬αñ╢αÑìαñÜαñ┐αñ« αñ¼αñéαñùαñ╛αñ▓ αñ«αÑçαñé αññαÑâαñúαñ«αÑéαñ▓ αñ╡αñ┐αñºαñ╛αñ»αñòαÑïαñé αñòαÑç αñ½αñ░αÑìαñ£αÑÇ αñ╣αñ╕αÑìαññαñ╛αñòαÑìαñ╖αñ░ αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñàαñ¡αñ┐αñ╖αÑçαñò αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñòαÑï αñ╕αÑÇαñåαñêαñíαÑÇ αñ¿αÑç αññαÑÇαñ╕αñ░αÑÇ αñ¼αñ╛αñ░ αñ¿αÑïαñƒαñ┐αñ╕ αñªαñ┐αñ»αñ╛αÑñ\n13:38\n13 minutes, 38 seconds\nαñ¬αñ╢αÑìαñÜαñ┐αñ« αñ¼αñéαñùαñ╛αñ▓ αñ╕αÑÇαñåαñêαñíαÑÇ αñòαÑÇ αñƒαÑÇαñ« αñòαñ▓ αñÅαñò αñ¼αñ╛αñ░ αñ½αñ┐αñ░ αñàαñ¡αñ┐αñ╖αÑçαñò αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñòαÑç αñåαñ╡αñ╛αñ╕ αñ¬αñ░ αñ¬αñ╣αÑüαñéαñÜαÑÇαÑñ\n13:42\n13 minutes, 42 seconds\nαñàαñºαñ┐αñòαñ╛αñ░αñ┐αñ»αÑïαñé αñ¿αÑç αñëαñ¿αÑìαñ╣αÑçαñé αñ¿αñ»αñ╛ αñ¿αÑïαñƒαñ┐αñ╕ αñ╕αÑîαñéαñ¬αñ¿αÑç αñòαÑÇ αñòαÑïαñ╢αñ┐αñ╢ αñòαÑÇαÑñ\n13:48\n13 minutes, 48 seconds\nαñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ╡αñ┐αñºαñ╛αñ»αñòαÑïαñé αñòαÑç αñ╕αñ«αñ░αÑìαñÑαñ¿ αñ╡αñ╛αñ▓αÑç αñ¬αññαÑìαñ░ αñ¬αñ░ αñ½αñ░αÑìαñ£αÑÇ αñ╣αñ╕αÑìαññαñ╛αñòαÑìαñ╖αñ░ αñ«αñ╛αñ«αñ▓αÑç αñòαÑÇ αñ£αñ╛αñéαñÜ αñòαÑç αñªαÑîαñ░αñ╛αñ¿ αñ¬αÑéαñ¢αññαñ╛αñ¢ αñòαÑç αñ▓αñ┐αñÅ αñ╕αÑÇαñåαñêαñƒαÑÇ αñªαñ½αÑìαññαñ░ αñ¿αñ╣αÑÇαñé αñ¬αñ╣αÑüαñéαñÜαñ¿αÑç αñ¬αñ░ αñàαñ¡αñ┐αñ╖αÑçαñò αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñòαÑï αññαÑÇαñ╕αñ░αñ╛ αñ╕αñ«αñ¿ αñ£αñ╛αñ░αÑÇ αñòαñ┐αñ»αñ╛\n13:56\n13 minutes, 56 seconds\nαñùαñ»αñ╛αÑñ αñëαñ¿αÑìαñ╣αÑçαñé αñåαñ£ αñ╢αñ╛αñ« 5:00 αñ¼αñ£αÑç αññαñò αñ£αñ╛αñéαñÜαñòαñ░αÑìαññαñ╛αñôαñé αñòαÑç αñ╕αñ╛αñ«αñ¿αÑç αñ¬αÑçαñ╢ αñ╣αÑïαñ¿αÑç αñòαñ╛ αñ¿αñ┐αñ░αÑìαñªαÑçαñ╢ αñ╣αÑêαÑñ\n14:02\n14 minutes, 2 seconds\nαñ¬αñ╢αÑìαñÜαñ┐αñ« αñ¼αñéαñùαñ╛αñ▓ αñ«αÑçαñé αñåαñ»αÑüαñ╖αÑìαñ«αñ╛αñ¿ αñ¡αñ╛αñ░αññ αñ¬αÑìαñ░αñºαñ╛αñ¿αñ«αñéαññαÑìαñ░αÑÇ αñ£αñ¿ αñåαñ░αÑïαñùαÑìαñ» αñ»αÑïαñ£αñ¿αñ╛ αñòαÑÇ αñ╢αÑüαñ░αÑüαñåαññ αñ╣αÑï αñÜαÑüαñòαÑÇ αñ╣αÑêαÑñ αñòαñ▓ αñ░αñ╛αñ£αÑìαñ» αñ╕αñ░αñòαñ╛αñ░ αñöαñ░ αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αÑÇαñ» αñ╕αÑìαñ╡αñ╛αñ╕αÑìαñÑαÑìαñ» αñ¬αÑìαñ░αñ╛αñºαñ┐αñòαñ░αñú αñòαÑç αñ¼αÑÇαñÜ αñÅαñ«αñôαñ»αÑé αñ¬αñ░ αñ╣αñ╕αÑìαññαñ╛αñòαÑìαñ╖αñ░ αñ╣αÑüαñÅαÑñ\n14:13\n14 minutes, 13 seconds\nαñÅαñ«αñôαñ»αÑé αñòαÑç αñ¼αñ╛αñª αñ¬αñ╢αÑìαñÜαñ┐αñ« αñ¼αñéαñùαñ╛αñ▓ αñªαÑçαñ╢ αñòαñ╛ 36αñ╡αñ╛αñé αñ¬αÑìαñ░αñªαÑçαñ╢ αñ¼αñ¿ αñùαñ»αñ╛ αñ╣αÑêαÑñ αñ£αñ╣αñ╛αñé αñåαñ»αÑüαñ╖αÑìαñ«αñ╛αñ¿ αñ¡αñ╛αñ░αññ αñ»αÑïαñ£αñ¿αñ╛ αñ▓αñ╛αñùαÑé αñ╣αÑïαñùαÑÇαÑñ αñçαñ╕ αñ»αÑïαñ£αñ¿αñ╛ αñ╕αÑç αñ░αñ╛αñ£αÑìαñ» αñòαÑç\n14:20\n14 minutes, 20 seconds\nαñòαñ░αÑÇαñ¼ 1 αñòαñ░αÑïαñíαñ╝ 1 αñòαñ░αÑïαñíαñ╝ αñ╕αÑç αñ£αÑìαñ»αñ╛αñªαñ╛ αñ¬αñ░αñ┐αñ╡αñ╛αñ░αÑïαñé αñòαÑï αñ▓αñ╛αñ¡ αñ«αñ┐αñ▓αñ¿αÑç αñòαÑÇ αñëαñ«αÑìαñ«αÑÇαñª αñ╣αÑêαÑñ\n14:28\n14 minutes, 28 seconds\nαñ¿αñê αñªαñ┐αñ▓αÑìαñ▓αÑÇ αñ«αÑçαñé αñåαñ»αÑïαñ£αñ┐αññ αñòαñ╛αñ░αÑìαñ»αñòαÑìαñ░αñ« αñ«αÑçαñé αñòαÑçαñéαñªαÑìαñ░αÑÇαñ» αñ╕αÑìαñ╡αñ╛αñ╕αÑìαñÑαÑìαñ» αñ«αñéαññαÑìαñ░αÑÇ αñ£αÑçαñ¬αÑÇ αñ¿αñíαÑìαñíαñ╛, αñ╕αÑìαñ╡αñ╛αñ╕αÑìαñÑαÑìαñ» αñ░αñ╛αñ£αÑìαñ» αñ«αñéαññαÑìαñ░αÑÇ αñàαñ¿αÑüαñ¬αÑìαñ░αñ┐αñ»αñ╛ αñ¬αñƒαÑçαñ▓ αñöαñ░ αñ«αÑüαñûαÑìαñ»αñ«αñéαññαÑìαñ░αÑÇ αñ╢αÑüαñ¡αÑçαñéαñªαÑü αñàαñºαñ┐αñòαñ╛αñ░αÑÇ αñ«αÑîαñ£αÑéαñª αñ░αñ╣αÑçαÑñ\n14:34\n14 minutes, 34 seconds\nαñòαÑçαñéαñªαÑìαñ░αÑÇαñ» αñ«αñéαññαÑìαñ░αÑÇ αñ£αÑçαñ¬αÑÇ αñ¿αñíαÑìαñíαñ╛ αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αÑÇαñ» αñ╕αÑìαñ╡αñ╛αñ╕αÑìαñÑαÑìαñ» αñ«αñ┐αñ╢αñ¿ αñòαÑç αññαñ╣αññ αñ░αñ╛αñ£αÑìαñ» αñòαÑï Γé╣527 αñòαñ░αÑïαñíαñ╝ αñ╕αÑç αñàαñºαñ┐αñò αñòαÑÇ αñ╕αñ╣αñ╛αñ»αññαñ╛ αñªαÑÇ αñùαñêαÑñ\n14:44\n14 minutes, 44 seconds\nαñ«αÑüαñûαÑìαñ»αñ«αñéαññαÑìαñ░αÑÇ αñ╢αÑüαñ¡αÑçαñéαñªαÑü αñàαñºαñ┐αñòαñ╛αñ░αÑÇ αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñåαñ»αÑüαñ╖αÑìαñ«αñ╛αñ¿ αñ¡αñ╛αñ░αññ αñ╕αÑç αñ£αÑüαñíαñ╝αñ¿αÑç αñòαÑç αñ¼αñ╛αñª αñ░αñ╛αñ£αÑìαñ» αñòαÑç αñùαñ░αÑÇαñ¼ αñöαñ░ αñ£αñ░αÑéαñ░αññαñ«αñéαñª αñ¬αñ░αñ┐αñ╡αñ╛αñ░αÑïαñé αñòαÑï αñ¼αÑçαñ╣αññαñ░ αñ╕αÑìαñ╡αñ╛αñ╕αÑìαñÑαÑìαñ» αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñ«αñ┐αñ▓αÑçαñùαÑÇ αñöαñ░ αñëαñ¿αÑìαñ╣αÑçαñé αñªαÑçαñ╢\n14:51\n14 minutes, 51 seconds\nαñ¡αñ░ αñòαÑç αñ╕αÑéαñÜαÑÇαñ¼αñªαÑìαñº αñàαñ╕αÑìαñ¬αññαñ╛αñ▓αÑïαñé αñ«αÑçαñé αñçαñ▓αñ╛αñ£ αñòαÑÇ αñ╕αÑüαñ╡αñ┐αñºαñ╛ αñ¡αÑÇ αñ¬αÑìαñ░αñ╛αñ¬αÑìαññ αñ╣αÑïαñùαÑÇαÑñ\n14:56\n14 minutes, 56 seconds\nαñ¬αñ╢αÑìαñÜαñ┐αñ« αñ¼αñéαñùαñ╛αñ▓ αñ«αÑçαñé αñòαÑïαñ▓αñòαñ╛αññαñ╛ αñ¿αñùαñ░ αñ¿αñ┐αñùαñ« αñòαÑï αññαññαÑìαñòαñ╛αñ▓ αñ¬αÑìαñ░αñ¡αñ╛αñ╡ αñ╕αÑç αñ¡αñéαñù αñòαñ░ αñªαñ┐αñ»αñ╛ αñùαñ»αñ╛ αñ╣αÑêαÑñ\n14:59\n14 minutes, 59 seconds\nαñ░αñ╛αñ£αÑìαñ» αñ╕αñ░αñòαñ╛αñ░ αñòαÑç αñ¿αñùαñ░ αñ╡αñ┐αñòαñ╛αñ╕ αñÅαñ╡αñé αñ¿αñùαñ░ αñ¬αñ╛αñ▓αñ┐αñòαñ╛ αñ«αñ╛αñ«αñ▓αÑïαñé αñòαÑç αñ╡αñ┐αñ¡αñ╛αñù αñªαÑìαñ╡αñ╛αñ░αñ╛ αñ£αñ╛αñ░αÑÇ αñåαñªαÑçαñ╢ αñòαÑç αñàαñ¿αÑüαñ╕αñ╛αñ░ αñ¿αñ┐αñùαñ« αñòαÑç αñ¡αñéαñù αñ╣αÑïαñ¿αÑç αñòαÑç αñ╕αñ╛αñÑ αñ╣αÑÇ αñ╕αñ¡αÑÇ\n15:07\n15 minutes, 7 seconds\nαñ¬αñ╛αñ░αÑìαñ╖αñªαÑïαñé, αñ«αÑçαñ»αñ░ αñçαñ¿ αñòαñ╛αñëαñéαñ╕αñ┐αñ▓ αñòαÑç αñ╕αñªαñ╕αÑìαñ»αÑïαñé, αñ╡αñ┐αñ¡αñ┐αñ¿αÑìαñ¿ αñ╕αñ«αñ┐αññαñ┐αñ»αÑïαñé, αñ«αÑçαñ»αñ░ αñöαñ░ αñÜαÑçαñ»αñ░αñ«αÑêαñ¿ αñòαñ╛ αñòαñ╛αñ░αÑìαñ»αñòαñ╛αñ▓ αñ╕αñ«αñ╛αñ¬αÑìαññ αñ╣αÑï αñùαñ»αñ╛αÑñ\n15:15\n15 minutes, 15 seconds\nαñ»αñ╣ αñ½αÑêαñ╕αñ▓αñ╛ αñ½αñ┐αñ░αñª αñ╣αñòαÑÇαñ« αñòαÑç αñ«αÑçαñ»αñ░ αñ¬αñª αñ╕αÑç αñçαñ╕αÑìαññαÑÇαñ½αÑç αñòαÑç αñ¼αñ╛αñª αñ▓αñ┐αñ»αñ╛ αñùαñ»αñ╛αÑñ αñåαñªαÑçαñ╢ αñòαÑç αññαñ╣αññ αñàαñ¼ αñ¿αñ┐αñùαñ« αñòαÑç αñ╕αñ¡αÑÇ αñ¬αÑìαñ░αñ╢αñ╛αñ╕αñ¿αñ┐αñò αñöαñ░ αñ╡αÑêαñºαñ╛αñ¿αñ┐αñò αñàαñºαñ┐αñòαñ╛αñ░ αñÅαñò αñ¬αÑìαñ░αñ╢αñ╛αñ╕αñò αñòαÑç αñ«αñ╛αñºαÑìαñ»αñ« αñ╕αÑç αñ╕αñéαñÜαñ╛αñ▓αñ┐αññ αñòαñ┐αñÅ αñ£αñ╛αñÅαñéαñùαÑçαÑñ\n15:26\n15 minutes, 26 seconds\nαñ░αñ╛αñ£αÑìαñ»αñ¬αñ╛αñ▓ αñ¿αÑç αñ¿αñùαñ░ αñ¿αñ┐αñùαñ« αñåαñ»αÑüαñòαÑìαññ αñ╕αÑìαñ«αñ┐αññαñ╛ αñ¬αñ╛αñéαñíαÑç αñòαÑï αñ¬αÑìαñ░αñ╢αñ╛αñ╕αñò αñ¿αñ┐αñ»αÑüαñòαÑìαññ αñòαñ┐αñ»αñ╛ αñ╣αÑêαÑñ αñ╡αñ╣ αñàαñºαñ┐αñòαññαñ« 6 αñ«αñ╣αÑÇαñ¿αÑç αññαñò αñ»αñ╛ αñ½αñ┐αñ░ αñ¿αñ╡αñ┐αñ╡αñ╛αñÜαñ┐αññ αñ¬αñ╛αñ░αÑìαñ╖αñªαÑïαñé αñòαÑç αñòαñ╛αñ░αÑìαñ»αñ¡αñ╛αñ░ αñ╕αñéαñ¡αñ╛αñ▓αñ¿αÑç αññαñò αñ¿αñ┐αñùαñ« αñòαñ╛ αñ╕αñéαñÜαñ╛αñ▓αñ¿ αñòαñ░αÑçαñéαñùαÑÇαÑñ\n15:37\n15 minutes, 37 seconds\nαñ¬αñ╢αÑìαñÜαñ┐αñ« αñ¼αñéαñùαñ╛αñ▓ αñòαÑç αñ«αÑüαñûαÑìαñ»αñ«αñéαññαÑìαñ░αÑÇ αñ╕αÑüαñ¡αÑçαñéαñªαÑü αñàαñºαñ┐αñòαñ╛αñ░αÑÇ αñ¿αÑç αñ¿αñê αñªαñ┐αñ▓αÑìαñ▓αÑÇ αñ«αÑçαñé αñòαÑçαñéαñªαÑìαñ░αÑÇαñ» αñ╡αñ┐αññαÑìαññ αñ«αñéαññαÑìαñ░αÑÇ αñ¿αñ┐αñ░αÑìαñ«αñ▓αñ╛ αñ╕αÑÇαññαñ╛αñ░αñ«αñú αñ╕αÑç αñ«αÑüαñ▓αñ╛αñòαñ╛αññ αñòαÑÇαÑñ αñçαñ╕ αñªαÑîαñ░αñ╛αñ¿ αñ░αñ╛αñ£αÑìαñ» αñòαÑç αñ╡αñ┐αñòαñ╛αñ╕, αñ¿αñ┐αñ╡αÑçαñ╢ αñöαñ░ αñ╡αñ┐αññαÑìαññαÑÇαñ»\n15:44\n15 minutes, 44 seconds\nαñ╕αñ«αñ╛αñ╡αÑçαñ╢αñ¿ αñ╕αÑç αñ£αÑüαñíαñ╝αÑç αñàαñ╣αñ« αñ«αÑüαñªαÑìαñªαÑïαñé αñ¬αñ░ αñÜαñ░αÑìαñÜαñ╛ αñ╣αÑüαñêαÑñ\n15:48\n15 minutes, 48 seconds\nαñôαñ«αñ╛αñ¿ αñòαÑç αñ╕αñ«αÑüαñªαÑìαñ░αÑÇ αñòαÑìαñ╖αÑçαññαÑìαñ░ αñ«αÑçαñé αñÅαñ«αñƒαÑÇ αñ«αÑêαñ░αÑÇαñ¼αÑçαñòαÑìαñ╕ αñ¿αñ╛αñ«αñò αññαÑçαñ▓ αñƒαÑêαñéαñòαñ░ αñ¬αñ░ αñ╣αÑüαñÅ αñ«αñ┐αñ╕αñ╛αñçαñ▓ αñ╣αñ«αñ▓αÑç αñòαÑç αñ¼αñ╛αñª αñëαñ╕αñ«αÑçαñé αñ╕αñ╡αñ╛αñ░ 24 αñ¡αñ╛αñ░αññαÑÇαñ» αñòαÑìαñ░αÑé αñ╕αñªαñ╕αÑìαñ»αÑïαñé αñòαÑï αñ╕αÑüαñ░αñòαÑìαñ╖αñ┐αññ αñ¼αñÜαñ╛ αñ▓αñ┐αñ»αñ╛ αñùαñ»αñ╛αÑñ\n15:56\n15 minutes, 56 seconds\nαñ«αÑçαñ░αñ┐αñƒαñ╛αñçαñ« αñ░αÑçαñ╕αÑìαñòαÑìαñ»αÑé αñòαÑïαñæαñ░αÑìαñíαñ┐αñ¿αÑçαñ╢αñ¿ αñ╕αÑçαñéαñƒαñ░ αñ«αÑüαñéαñ¼αñê αñòαÑç αñôαñ«αñ╛αñ¿ αñòαÑç αñàαñºαñ┐αñòαñ╛αñ░αñ┐αñ»αÑïαñé αñòαÑç αñ╕αñ╛αñÑ αñ«αñ┐αñ▓αñòαñ░ αñòαñ╛αñ« αñòαñ┐αñ»αñ╛αÑñ\n16:03\n16 minutes, 3 seconds\nαñ¡αñ╛αñ░αññαÑÇαñ» αññαñƒαñ░αñòαÑìαñ╖αñò αñ¼αñ▓ αñ¿αÑç αñ¼αññαñ╛αñ»αñ╛ αñòαñ┐ αñ░αÑçαñ╕αÑìαñòαÑìαñ»αÑé αñæαñ¬αñ░αÑçαñ╢αñ¿ αñôαñ«αñ╛αñ¿ αñ¿αÑîαñ╕αÑçαñ¿αñ╛ αñòαÑç αñ╕αñ╣αñ»αÑïαñù αñ╕αÑç αñ¬αÑéαñ░αñ╛ αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛αÑñ αñôαñ«αñ╛αñ¿ αñ╕αñ░αÑìαñÜ αñÅαñéαñí αñ░αÑçαñ╕αÑìαñòαÑìαñ»αÑé αñ░αÑÇαñ£αñ¿ αñ«αÑçαñé αñÅαñ«αñƒαÑÇ αñ«αÑçαñ¼αÑçαñòαÑìαñ╕ αñ¬αñ░ αñ«αñ┐αñ╕αñ╛αñçαñ▓ αñ╣αñ«αñ▓αÑç αñòαÑÇ αñ╕αÑéαñÜαñ¿αñ╛\n16:12\n16 minutes, 12 seconds\nαñ«αñ┐αñ▓αññαÑç αñ╣αÑÇ αñ«αÑüαñéαñ¼αñê αñ╕αÑìαñÑαñ┐αññ αñ«αÑçαñ░αñ┐αñƒαñ╛αñçαñ« αñ░αÑçαñ╕αÑìαñòαÑìαñ»αÑé αñòαÑïαñæαñ░αÑìαñíαñ┐αñ¿αÑçαñ╢αñ¿ αñ╕αÑçαñéαñƒαñ░ αñ╕αñòαÑìαñ░αñ┐αñ» αñ╣αÑï αñùαñ»αñ╛αÑñ\n16:18\n16 minutes, 18 seconds\nαñÅαñ«αñåαñ░αñ╕αÑÇαñ╕αÑÇ αñ«αÑüαñéαñ¼αñê αñ¿αÑç αññαÑüαñ░αñéαññ αñôαñ«αñ╛αñ¿ αñòαÑÇ αñ╕αñ«αÑüαñªαÑìαñ░αÑÇ αñÅαñ£αÑçαñéαñ╕αÑÇ αñôαñÅαñ«αñÅαñ╕αñ╕αÑÇ αñòαÑç αñ╕αñ╛αñÑ αñ╕αñ«αñ¿αÑìαñ╡αñ» αñòαñ┐αñ»αñ╛αÑñ αñçαñ╕αñòαÑç αñ¼αñ╛αñª αñôαñ«αñ╛αñ¿ αñ¿αÑîαñ╕αÑçαñ¿αñ╛ αñòαÑç αñ╣αÑçαñ▓αÑÇαñòαÑëαñ¬αÑìαñƒαñ░αÑïαñé αñòαÑÇ αñ«αñªαñª\n16:26\n16 minutes, 26 seconds\nαñ╕αÑç αñ£αñ╣αñ╛αñ£ αñ¬αñ░ αñ½αñéαñ╕αÑç αñ╕αñ¡αÑÇ 24 αñ¡αñ╛αñ░αññαÑÇαñ» αñòαÑüαñªαñ╕αÑìαñ»αÑïαñé αñòαÑï αñ╕αÑüαñ░αñòαÑìαñ╖αñ┐αññ αñ¼αñ╛αñ╣αñ░ αñ¿αñ┐αñòαñ╛αñ▓αñ╛ αñùαñ»αñ╛αÑñ\n16:32\n16 minutes, 32 seconds\nαñ╕αÑÇαñ¼αÑÇαñÅαñ╕αñê αñòαÑÇ αñ¬αÑïαñ╕αÑìαñƒ αñ░αñ┐αñ£αñ▓αÑìαñƒ αñ╕αñ░αÑìαñ╡αñ┐αñ£ αñòαÑï αñ▓αÑçαñòαñ░ αñ¢αñ╛αññαÑìαñ░αÑïαñé αñöαñ░ αñàαñ¡αñ┐αñ¡αñ╛αñ╡αñòαÑïαñé αñòαÑç αñ¼αÑÇαñÜ αñ¼αñ¿αÑÇ αñëαñ▓αñ¥αñ¿ αñòαÑï αñ¼αÑïαñ░αÑìαñí αñ¿αÑç αñªαÑéαñ░ αñòαñ░ αñªαñ┐αñ»αñ╛ αñ╣αÑêαÑñ αñ╕αÑÇαñ¼αÑÇαñÅαñ╕αñê αñ¿αÑç αñ╕αñ╛αñ½ αñòαñ┐αñ»αñ╛ αñòαñ┐ αñ¬αÑïαñ░αÑìαñƒαñ▓ αñ¬αñ░ αñªαñ┐αñûαñ¿αÑç αñ╡αñ╛αñ▓αÑç αññαñòαñ¿αÑÇαñòαÑÇ\n16:40\n16 minutes, 40 seconds\nαñ╕αñéαñªαÑçαñ╢αÑïαñé αñòαñ╛ αñòαñ╛αñ░αñú αñòαÑìαñ»αñ╛ αñ╣αÑê αñöαñ░ αñ¬αÑéαñ░αÑÇ αñ¬αÑìαñ░αñòαÑìαñ░αñ┐αñ»αñ╛ αñòαÑêαñ╕αÑç αñ╕αñéαñÜαñ╛αñ▓αñ┐αññ αñòαÑÇ?\n16:46\n16 minutes, 46 seconds\nαñ¼αÑïαñ░αÑìαñí αñòαÑç αñåαñéαñòαñíαñ╝αÑïαñé αñòαÑç αñ«αÑüαññαñ╛αñ¼αñ┐αñò 2 αñ╕αÑç 7 αñ£αÑéαñ¿ αññαñò αñÜαñ▓αÑÇ αñÅαñ¬αÑìαñ▓αÑÇαñòαÑçαñ╢αñ¿ αñ╡αñ┐αñéαñíαÑï αñòαÑç αñªαÑîαñ░αñ╛αñ¿ 1.6 αñ▓αñ╛αñû αñ╕αÑç αñ£αÑìαñ»αñ╛αñªαñ╛ αñ¢αñ╛αññαÑìαñ░αÑïαñé αñ¿αÑç 3.8 αñ▓αñ╛αñû αñ╕αÑç αñ£αÑìαñ»αñ╛αñªαñ╛ αñëαññαÑìαññαñ░ αñ¬αÑüαñ╕αÑìαññαñ┐αñòαñ╛αñôαñé αñòαÑç αñ▓αñ┐αñÅ αñåαñ╡αÑçαñªαñ¿ αñòαñ┐αñ»αñ╛αÑñ\n16:57\n16 minutes, 57 seconds\nαñåαñêαñÅαñ«αñíαÑÇ αñ¿αÑç αñåαñ£ αñëαññαÑìαññαñ░ αñ¬αñ╢αÑìαñÜαñ┐αñ«αÑÇ αñöαñ░ αñëαññαÑìαññαñ░ αñëαññαÑìαññαñ░αÑÇ αñ░αñ╛αñ£αÑìαñ»αÑïαñé αñ¬αñ╢αÑìαñÜαñ┐αñ«αÑÇ αñ░αñ╛αñ£αñ╕αÑìαñÑαñ╛αñ¿ αñöαñ░ αñ╡αñ┐αñªαñ░αÑìαñ¡ αñ«αÑçαñé αñ▓αÑé αñÜαñ▓αñ¿αÑç αñòαÑÇ αñ╕αñéαñ¡αñ╛αñ╡αñ¿αñ╛ αñ£αññαñ╛αñê αñ╣αÑêαÑñ\n17:04\n17 minutes, 4 seconds\nαñòαÑïαñòαñú αñöαñ░ αñùαÑïαñ╡αñ╛, αñëαñíαñ╝αÑÇαñ╕αñ╛, αññαñ«αñ┐αñ▓αñ¿αñ╛αñíαÑü, αñ¬αÑüαñªαÑüαñÜαÑçαñ░αÑÇ αñöαñ░ αñòαñ░αñ╛αñêαñòαñ╛αñ▓ αñ«αÑçαñé αñªαñ┐αñ¿ αñ¡αñ░ αñùαñ░αÑìαñ« αñöαñ░ αñëαñ«αñ╕ αñ¡αñ░αñ╛ αñ«αÑîαñ╕αñ« αñ░αñ╣αñ¿αÑç αñòαñ╛ αñàαñ¿αÑüαñ«αñ╛αñ¿ αñ╣αÑêαÑñ αñàαñùαñ▓αÑç αñòαÑüαñ¢ αñªαñ┐αñ¿αÑïαñé\n17:13\n17 minutes, 13 seconds\nαñ«αÑçαñé αñòαÑçαñ░αñ▓ αñòαÑç αñòαÑüαñ¢ αñ╣αñ┐αñ╕αÑìαñ╕αÑïαñé αñ«αÑçαñé αñ¼αñ╣αÑüαññ αñ¡αñ╛αñ░αÑÇ αñ¼αñ╛αñ░αñ┐αñ╢ αñòαÑÇ αñÜαÑçαññαñ╛αñ╡αñ¿αÑÇαÑñ αñëαññαÑìαññαñ░αÑÇ αñòαÑçαñ░αñ▓ αñòαÑç αññαÑÇαñ¿ αñ£αñ┐αñ▓αÑïαñé αñ«αÑçαñé αñòαÑïαñ£αñòαÑïαñƒ, αñòαñ¿αÑìαñ¿αÑéαñ░ αñöαñ░ αñòαñ╛αñ╕αñ░αñòαÑïαñƒ αñ«αÑçαñé αñ░αÑçαñí αñàαñ▓αñ░αÑìαñƒ αñ£αñ╛αñ░αÑÇ αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛αÑñ 10 αñöαñ░ 11 αñ£αÑéαñ¿ αñòαÑï\n17:22\n17 minutes, 22 seconds\nαñ«αñ▓αñ¬αÑüαñ░αñ«, αñòαÑïαñ£αñòαÑïαñƒ, αñ╡αñ╛αñ»αñ¿αñ╛, αñòαñ¿αÑìαñ¿αÑéαñ░ αñöαñ░ αñòαñ╛αñ╕αñ░αñòαÑïαñƒ αñàαñ▓αñ░αÑìαñƒ αñ¬αñ░ αñ░αñ╣αÑçαñéαñùαÑçαÑñ\n17:27\n17 minutes, 27 seconds\nαñòαñ░αÑìαñ¿αñ╛αñƒαñò αñòαÑç αññαñƒαÑÇαñ» αñ£αñ┐αñ▓αÑïαñé αñ«αÑçαñé αñªαñòαÑìαñ╖αñ┐αñú αñ¬αñ╢αÑìαñÜαñ┐αñ« αñ«αñ╛αñ¿αñ╕αÑéαñ¿ αñòαÑç αñ╕αñòαÑìαñ░αñ┐αñ» αñ╣αÑïαñ¿αÑç αñòαÑç αñ¼αÑÇαñÜ αñåαñêαñÅαñ«αñíαÑÇ αñ¿αÑç αñàαñùαñ▓αÑç αñªαÑï αñªαñ┐αñ¿αÑïαñé αñ«αÑçαñé αñ¼αñ╣αÑüαññ αñ¡αñ╛αñ░αÑÇ αñ¼αñ╛αñ░αñ┐αñ╢ αñòαÑÇ αñ╕αñéαñ¡αñ╛αñ╡αñ¿αñ╛ αñ£αññαñ╛αñê αñ╣αÑê αñöαñ░ αñªαñòαÑìαñ╖αñ┐αñú αñòαñ¿αÑìαñ¿αñíαñ╝ αñöαñ░\n17:35\n17 minutes, 35 seconds\nαñëαñíαÑéαñ¬αÑÇ αñ£αñ┐αñ▓αÑç αñòαÑç αñ▓αñ┐αñÅ αñ░αÑçαñí αñàαñ▓αñ░αÑìαñƒ αñ£αñ╛αñ░αÑÇ αñòαñ┐αñ»αñ╛ αñ╣αÑêαÑñ αñàαñ░αÑüαñúαñ╛αñÜαñ▓ αñ¬αÑìαñ░αñªαÑçαñ╢, αñàαñéαñíαñ«αñ╛αñ¿ αñöαñ░ αñ¿αñ┐αñòαÑïαñ¼αñ╛αñ░ αñªαÑìαñ╡αÑÇαñ¬ αñ╕αñ«αÑéαñ╣, αñåαñéαñºαÑìαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢, αñ¼αñ┐αñ╣αñ╛αñ░,\n17:43\n17 minutes, 43 seconds\nαñ¢αññαÑìαññαÑÇαñ╕αñùαñóαñ╝, αñ░αñ╛αñ£αñ╕αÑìαñÑαñ╛αñ¿, αñëαññαÑìαññαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢, αñ¬αñ╢αÑìαñÜαñ┐αñ« αñ¼αñéαñùαñ╛αñ▓ αñöαñ░ αñëαññαÑìαññαñ░ αñ¬αÑéαñ░αÑìαñ╡αÑÇ αñ¡αñ╛αñ░αññ αñ«αÑçαñé αñåαñ£ αñùαñ░αñ£ αñòαÑç αñ╕αñ╛αñÑ αñ¼αñ┐αñ£αñ▓αÑÇ αñùαñ┐αñ░αñ¿αÑç αñòαÑÇ αñ╕αñéαñ¡αñ╛αñ╡αñ¿αñ╛αÑñ\n17:49\n17 minutes, 49 seconds\nαñòαÑçαñéαñªαÑìαñ░αÑÇαñ» αñ«αñéαññαÑìαñ░αÑÇ αñ¬αÑÇαñ»αÑéαñ╖ αñùαÑïαñ»αñ▓ αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñ¡αñ╛αñ░αññ αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñªαÑìαñ╡αñ┐αñ¬αñòαÑìαñ╖αÑÇαñ» αñ╡αÑìαñ»αñ╛αñ¬αñ╛αñ░ αñ╕αñ«αñ¥αÑîαññαÑç αñòαÑç αñ¬αñ╣αñ▓αÑç αñÜαñ░αñú αñ¬αñ░ αñ£αÑüαñ▓αñ╛αñê αññαñò αñ╣αñ╕αÑìαññαñ╛αñòαÑìαñ╖αñ░ αñ╣αÑï αñ╕αñòαññαÑç αñ╣αÑêαñéαÑñ\n17:58\n17 minutes, 58 seconds\nαñ¬αÑÇαñ»αÑéαñ╖ αñùαÑïαñ»αñ▓ αñ¿αÑç αñ¼αññαñ╛αñ»αñ╛ αñòαñ┐ αñªαÑïαñ¿αÑïαñé αñªαÑçαñ╢αÑïαñé αñòαÑç αñ¼αÑÇαñÜ αñ¼αñ╛αññαñÜαÑÇαññ αñ¿αñ┐αñ░αÑìαñúαñ╛αñ»αñò αñÜαñ░αñú αñ«αÑçαñé αñ¬αñ╣αÑüαñéαñÜ αñÜαÑüαñòαÑÇ αñ╣αÑê αñöαñ░ αñ¼αñÜαÑç αñ╣αÑüαñÅ αñ«αÑüαñªαÑìαñªαÑïαñé αñòαÑï αñ╕αÑüαñ▓αñ¥αñ╛αñ¿αÑç αñ¬αñ░ αñòαñ╛αñ« αñ£αñ╛αñ░αÑÇ αñ╣αÑêαÑñ αñçαñ╕ αñ╕αñ«αñ¥αÑîαññαÑç αñ╕αÑç αñ╡αÑìαñ»αñ╛αñ¬αñ╛αñ░ αñöαñ░ αñ¿αñ┐αñ╡αÑçαñ╢ αñòαÑï αñ¼αñóαñ╝αñ╛αñ╡αñ╛ αñ«αñ┐αñ▓αñ¿αÑç αñòαÑÇ αñëαñ«αÑìαñ«αÑÇαñª αñ╣αÑêαÑñ\n18:09\n18 minutes, 9 seconds\nαñòαÑçαñéαñªαÑìαñ░αÑÇαñ» αñ╡αñ╛αñúαñ┐αñ£αÑìαñ» αñÅαñ╡αñé αñëαñªαÑìαñ»αÑïαñù αñ«αñéαññαÑìαñ░αÑÇ αñ¬αÑÇαñ»αÑéαñ╖ αñùαÑïαñ»αñ▓ αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñ¡αñ╛αñ░αññ αñòαÑÇ 7.7% αñ£αÑÇαñíαÑÇαñ¬αÑÇ αñ╡αÑâαñªαÑìαñºαñ┐ αñªαñ░ αñ¬αñ┐αñ¢αñ▓αÑç αñÅαñò αñªαñ╢αñò αñ«αÑçαñé αñòαñ┐αñÅ αñùαñÅ αñ▓αñùαñ╛αññαñ╛αñ░\n18:16\n18 minutes, 16 seconds\nαñåαñ░αÑìαñÑαñ┐αñò αñ╕αÑüαñºαñ╛αñ░αÑïαñé αñöαñ░ αñ¿αÑÇαññαñ┐αñùαññ αñ╣αñ╕αÑìαññαñòαÑìαñ╖αÑçαñ¬αÑïαñé αñòαñ╛ αñ¬αñ░αñ┐αñúαñ╛αñ« αñ╣αÑêαÑñ αñ¬αÑÇαñ»αÑéαñ╖ αñùαÑïαñ▓ αñ¿αÑç αñ¼αññαñ╛αñ»αñ╛ αñòαñ┐ αñ╕αñ░αñòαñ╛αñ░ αñ¿αÑç αñöαñªαÑìαñ»αÑïαñùαñ┐αñò αñ╡αñ┐αñòαñ╛αñ╕ αñòαÑç αñ▓αñ┐αñÅ 100 αñ¿αñÅ αñöαñªαÑìαñ»αÑïαñùαñ┐αñò\n18:25\n18 minutes, 25 seconds\nαñ¬αñ╛αñ░αÑìαñòαÑïαñé αñòαÑÇ αñ»αÑïαñ£αñ¿αñ╛ αñ╢αÑüαñ░αÑé αñòαÑÇ αñöαñ░ αñ¿αñ┐αñ╡αÑçαñ╢ αñ¿αñ┐αñ░αÑìαñ»αñ╛αññ αñ╡ αñÅαñ½αñíαÑÇαñåαñê αñ«αÑçαñé αñ▓αñùαñ╛αññαñ╛αñ░ αñ╡αÑâαñªαÑìαñºαñ┐ αñ╣αÑï αñ░αñ╣αÑÇ αñ╣αÑêαÑñ αñ»αÑéαñ¬αÑÇ αñòαÑç αñ«αÑüαñûαÑìαñ»αñ«αñéαññαÑìαñ░αÑÇ αñ»αÑïαñùαÑÇ\n18:32\n18 minutes, 32 seconds\nαñåαñªαñ┐αññαÑìαñ»αñ¿αñ╛αñÑ αñ¿αÑç αñ╡αñ╕αÑìαññαÑìαñ░ αñÅαñ╡αñé αñ¬αñ░αñ┐αñºαñ╛αñ¿ αñòαÑìαñ╖αÑçαññαÑìαñ░ αñòαÑÇ αñ£αñ░αÑéαñ░αññαÑïαñé αñòαÑç αñàαñ¿αÑüαñ░αÑéαñ¬ αñ╡αÑìαñ»αñ╛αñ¬αñò αñòαÑîαñ╢αñ▓ αñ╡αñ┐αñòαñ╛αñ╕ αñòαñ╛αñ░αÑìαñ» αñ»αÑïαñ£αñ¿αñ╛ αññαÑêαñ»αñ╛αñ░ αñòαñ░αñ¿αÑç αñòαÑç αñ¿αñ┐αñ░αÑìαñªαÑçαñ╢ αñªαñ┐αñÅαÑñ\n18:39\n18 minutes, 39 seconds\nαñ»αÑïαñùαÑÇ αñåαñªαñ┐αññαÑìαñ»αñ¿αñ╛αñÑ αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñ░αñ╛αñ£αÑìαñ» αñ¿αñ┐αñ╡αÑçαñ╢ αñëαññαÑìαñ¬αñ╛αñªαñ¿ αñöαñ░ αñ░αÑïαñ£αñùαñ╛αñ░ αñòαÑç αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñçαñ╕ αñòαÑìαñ╖αÑçαññαÑìαñ░ αñ«αÑçαñé αñàαñùαÑìαñ░αñúαÑÇ αñ¼αñ¿ αñ░αñ╣αñ╛ αñ╣αÑêαÑñ αñçαñ╕αñ▓αñ┐αñÅ αñëαñªαÑìαñ»αÑïαñùαÑïαñé αñòαÑï αñ╕αñ«αñ» αñ¬αñ░ αñ¬αÑìαñ░αñ╢αñ┐αñòαÑìαñ╖αñ┐αññ αñöαñ░ αñªαñòαÑìαñ╖ αñ«αñ╛αñ¿αñ╡ αñ╕αñéαñ╕αñ╛αñºαñ¿ αñëαñ¬αñ▓αñ¼αÑìαñº αñòαñ░αñ╛αñ¿αñ╛ αñåαñ╡αñ╢αÑìαñ»αñò αñ╣αÑêαÑñ\n18:50\n18 minutes, 50 seconds\nαñòαÑçαñéαñªαÑìαñ░αÑÇαñ» αñ«αñéαññαÑìαñ░αÑÇ αñ£αÑÇ αñòαñ┐αñ╢αñ¿ αñ░αÑçαñíαÑìαñíαÑÇ αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñ¬αÑìαñ░αñºαñ╛αñ¿αñ«αñéαññαÑìαñ░αÑÇ αñ¿αñ░αÑçαñéαñªαÑìαñ░ αñ«αÑïαñªαÑÇ αñòαÑç 12 αñ╡αñ░αÑìαñ╖αÑïαñé αñòαÑç αñòαñ╛αñ░αÑìαñ»αñòαñ╛αñ▓ αñ«αÑçαñé αñòαÑïαñ»αñ▓αñ╛ αñöαñ░ αñûαñ¿αñ¿ αñòαÑìαñ╖αÑçαññαÑìαñ░ αñ«αÑçαñé αñ¼αñíαñ╝αÑç αñ╕αÑüαñºαñ╛αñ░ αñ╣αÑüαñÅ αñ╣αÑêαñéαÑñ αñ£αñ┐αñ¿αñòαÑç αñ╕αñòαñ╛αñ░αñ╛αññαÑìαñ«αñò\n18:57\n18 minutes, 57 seconds\nαñ¬αñ░αñ┐αñúαñ╛αñ« αñ╕αñ╛αñ«αñ¿αÑç αñåαñÅαÑñ αñ«αñéαññαÑìαñ░αÑÇ αñòαÑç αñàαñ¿αÑüαñ╕αñ╛αñ░ αñªαÑçαñ╢ αñ«αÑçαñé αñ░αñ┐αñòαÑëαñ░αÑìαñí αñòαÑïαñ»αñ▓αñ╛ αñëαññαÑìαñ¬αñ╛αñªαñ¿ αñ╣αÑï αñ░αñ╣αñ╛ αñ╣αÑê αñöαñ░ αñ¼αñ┐αñ£αñ▓αÑÇ αñåαñ¬αÑéαñ░αÑìαññαñ┐ αñ¡αÑÇ αñ¬αñ░αÑìαñ»αñ╛αñ¬αÑìαññ αñ¼αñ¿αÑÇ αñ╣αÑêαÑñ\n19:03\n19 minutes, 3 seconds\nαñëαñ¿αÑìαñ╣αÑïαñéαñ¿αÑç αñ¼αññαñ╛αñ»αñ╛ αñòαñ┐ αñ¬αñ╛αñ░αñªαñ░αÑìαñ╢αÑÇ αñ¿αÑÇαññαñ┐αñ»αÑïαñé αñòαÑç αñÜαñ▓αññαÑç αñëαññαÑìαñ¬αñ╛αñªαñ¿ αñöαñ░ αñåαñ¬αÑéαñ░αÑìαññαñ┐ αñ«αÑçαñé αñ╕αÑüαñºαñ╛αñ░ αñ╣αÑüαñåαÑñ\n19:07\n19 minutes, 7 seconds\nαñ╕αñ░αñòαñ╛αñ░ αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñ¬αñ┐αñ¢αñ▓αÑç 12 αñ╡αñ░αÑìαñ╖αÑïαñé αñ«αÑçαñé αñòαñ▓αÑìαñ»αñ╛αñúαñòαñ╛αñ░αÑÇ αñ»αÑïαñ£αñ¿αñ╛ αñöαñ░ αñ╕αñ╛αñ«αñ╛αñ£αñ┐αñò αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñòαñ╛αñ░αÑìαñ»αñòαÑìαñ░αñ«αÑïαñé αñòαÑç αñ╡αñ┐αñ╕αÑìαññαñ╛αñ░ αñòαÑç αñòαñ╛αñ░αñú αñ▓αñùαñ¡αñù 25 αñòαñ░αÑïαñíαñ╝ αñ▓αÑïαñù αñ¼αñ╣αÑüαñåαñ»αñ╛αñ«αÑÇ αñùαñ░αÑÇαñ¼αÑÇ αñ╕αÑç αñ¼αñ╛αñ╣αñ░ αñ¿αñ┐αñòαñ▓αÑçαÑñ\n19:18\n19 minutes, 18 seconds\nαñ╕αñ░αñòαñ╛αñ░ αñòαÑç αñàαñ¿αÑüαñ╕αñ╛αñ░ αñ£αñ▓αñ£αÑÇαñ╡αñ¿ αñ«αñ┐αñ╢αñ¿, αñ╕αÑìαñ╡αñÜαÑìαñ¢ αñ¡αñ╛αñ░αññ αñàαñ¡αñ┐αñ»αñ╛αñ¿, αñëαñ£αÑìαñ£αÑìαñ╡αñ▓αñ╛ αñ»αÑïαñ£αñ¿αñ╛ αñöαñ░ αñûαñ╛αñªαÑìαñ» αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñ£αÑêαñ╕αÑÇ αñ»αÑïαñ£αñ¿αñ╛αñôαñé αñ¿αÑç αñùαÑìαñ░αñ╛αñ«αÑÇαñú αñöαñ░ αñòαñ«αñ£αÑïαñ░ αñ╡αñ░αÑìαñùαÑïαñé αñòαÑç αñ£αÑÇαñ╡αñ¿ αñ╕αÑìαññαñ░ αñ«αÑçαñé αñ╕αÑüαñºαñ╛αñ░ αñòαñ┐αñ»αñ╛αÑñ αñ╕αñ░αñòαñ╛αñ░ αñ¿αÑç\n19:28\n19 minutes, 28 seconds\nαñòαñ╣αñ╛ αñòαñ┐ αñ£αñ¿αñºαñ¿ αñ»αÑïαñ£αñ¿αñ╛ αñòαÑç αññαñ╣αññ αñªαÑçαñ╢ αñ«αÑçαñé αñûαñ╛αññαÑïαñé αñòαÑÇ αñ╕αñéαñûαÑìαñ»αñ╛ αñ¼αñóαñ╝αñòαñ░ 58 αñòαñ░αÑïαñíαñ╝ αñòαÑç αñ¬αñ╛αñ░ αñ¬αñ╣αÑüαñéαñÜαÑÇαÑñ αñçαñ¿αñ«αÑçαñé αñ£αñ«αñ╛ αñ░αñ╛αñ╢αñ┐ Γé╣3 αñ▓αñ╛αñû αñòαñ░αÑïαñíαñ╝ αñ╕αÑç αñèαñ¬αñ░ αñ╣αÑêαÑñ\n19:36\n19 minutes, 36 seconds\nαñ╕αñ░αñòαñ╛αñ░ αñ¿αÑç αñ¼αññαñ╛αñ»αñ╛ αñòαñ┐ αñ£αñ¿αñºαñ¿ αñåαñºαñ╛αñ░ αñöαñ░ αñ«αÑïαñ¼αñ╛αñçαñ▓ αñòαÑÇ αñ£αÑçαñÅαñ« αñƒαÑìαñ░αñ┐αñ¿αñ┐αñƒαÑÇ αñ¿αÑç αñòαñ▓αÑìαñ»αñ╛αñúαñòαñ╛αñ░αÑÇ αñ»αÑïαñ£αñ¿αñ╛αñôαñé αñòαñ╛ αñ▓αñ╛αñ¡ αñ╕αÑÇαñºαÑç αñ▓αÑïαñùαÑïαñé αññαñò αñ¬αñ╣αÑüαñéαñÜαñ╛αñ¿αÑç αñ«αÑçαñé αñàαñ╣αñ«\n19:43\n19 minutes, 43 seconds\nαñ¡αÑéαñ«αñ┐αñòαñ╛ αñ¿αñ┐αñ¡αñ╛αñêαÑñ αñ╕αñ░αñòαñ╛αñ░ αñ¿αÑç αñ¬αÑìαñ░αñºαñ╛αñ¿αñ«αñéαññαÑìαñ░αÑÇ αñëαñ£αÑìαñ£αñ╡αñ▓αñ╛ αñ»αÑïαñ£αñ¿αñ╛ αñòαÑç αññαñ╣αññ αñ╕αñ¼αÑìαñ╕αñ┐αñíαÑÇ αñ╡αñ╛αñ▓αÑç αñÅαñ▓αñ¬αÑÇαñ£αÑÇ αñ╕αñ┐αñ▓αÑçαñéαñíαñ░αÑïαñé αñòαÑÇ αñ╕αñéαñûαÑìαñ»αñ╛ αñ╕αñ╛αñ▓αñ╛αñ¿αñ╛ αñÜαñ╛αñ░ αñòαñ░ αñªαÑÇαÑñ\n19:50\n19 minutes, 50 seconds\nαñ¬αÑçαñƒαÑìαñ░αÑïαñ▓αñ┐αñ»αñ« αñ«αñéαññαÑìαñ░αñ╛αñ▓αñ» αñòαÑç αñàαñ¿αÑüαñ╕αñ╛αñ░ αñ¬αñ╛αññαÑìαñ░ αñ▓αñ╛αñ¡αñ╛αñ░αÑìαñÑαñ┐αñ»αÑïαñé αñòαÑï 14.2 αñòαñ┐.αñùαÑìαñ░. αñ╕αñ┐αñ▓αÑçαñéαñíαñ░ αñ¬αñ░ Γé╣300 αñòαÑÇ αñ╕αñ¼αÑìαñ╕αñ┐αñíαÑÇ αñ«αñ┐αñ▓αññαÑÇ αñ░αñ╣αÑçαñùαÑÇαÑñ αñ▓αÑçαñòαñ┐αñ¿ αñ»αñ╣ αñ╕αÑüαñ╡αñ┐αñºαñ╛ αñ╡αñ░αÑìαñ╖ αñ«αÑçαñé αñòαÑçαñ╡αñ▓ αñ¬αñ╣αñ▓αÑç αñÜαñ╛αñ░ αñ░αñ┐αñ½αÑìαñ░αñ┐αñ▓ αññαñò αñ╢αÑüαñ░αÑé αñ╣αÑïαñùαÑÇαÑñ\n20:01\n20 minutes, 1 second\nαñ╕αñ░αñòαñ╛αñ░ αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñ¬αñ╢αÑìαñÜαñ┐αñ« αñÅαñ╢αñ┐αñ»αñ╛ αñ╕αñéαñÿαñ░αÑìαñ╖ αñ╕αÑç αñ╕αñ¬αÑìαñ▓αñ╛αñê αñÜαÑçαñ¿ αñ¬αÑìαñ░αñ¡αñ╛αñ╡αñ┐αññ αñ╣αÑïαñ¿αÑç αñòαÑç αñ¼αñ╛αñ╡αñ£αÑéαñª αñûαñ░αÑÇαñ½ αñ╕αÑÇαñ£αñ¿ 2026 αñòαÑç αñ▓αñ┐αñÅ αñªαÑçαñ╢ αñ«αÑçαñé αñëαñ░αÑìαñ╡αñ░αÑïαñé αñòαñ╛ αñ¬αñ░αÑìαñ»αñ╛αñ¬αÑìαññ αñ¡αñéαñíαñ╛αñ░αÑñ\n20:10\n20 minutes, 10 seconds\nαñëαñ░αÑìαñ╡αñ░αñò αñ«αñéαññαÑìαñ░αñ╛αñ▓αñ» αñòαÑç αñàαñ¿αÑüαñ╕αñ╛αñ░ αñòαÑüαñ▓ αñåαñ╡αñ╢αÑìαñ»αñòαññαñ╛ 383.9 αñ▓αñ╛αñû αñ«αÑÇαñƒαÑìαñ░αñ┐αñò αñƒαñ¿ αñòαÑç αñ«αÑüαñòαñ╛αñ¼αñ▓αÑç αñ▓αñùαñ¡αñù 197.56\n20:19\n20 minutes, 19 seconds\nαñ▓αñ╛αñû αñ«αÑÇαñƒαÑìαñ░αñ┐αñò αñƒαñ¿ αñ╕αÑìαñƒαÑëαñò αñ«αÑîαñ£αÑéαñª αñ╣αÑê αñ£αÑï αñ╕αñ╛αñ«αñ╛αñ¿αÑìαñ» αñ╕αÑìαññαñ░ αñ╕αÑç αñ£αÑìαñ»αñ╛αñªαñ╛ αñ╣αÑêαÑñ αñÅαñ╕αñ¼αÑÇαñåαñê αñ¿αÑç αñ╡αñ┐αññαÑìαññ αñ╡αñ░αÑìαñ╖ 2025-26 αñòαÑç αñ▓αñ┐αñÅ αñòαÑçαñéαñªαÑìαñ░ αñ╕αñ░αñòαñ╛αñ░ αñòαÑï Γé╣8,813 αñòαñ░αÑïαñíαñ╝ αñòαñ╛ αñíαñ┐αñ╡αñ┐αñíαÑçαñéαñí αñÜαÑçαñò αñ╕αÑîαñéαñ¬αñ╛αÑñ αñÜαÑçαñò αñÅαñ╕αñ¼αÑÇαñåαñê\n20:28\n20 minutes, 28 seconds\nαñòαÑç αñÜαÑçαñ»αñ░αñ«αÑêαñ¿ αñ╕αÑÇ αñÅαñ╕ αñ╢αÑçαñƒαÑìαñƒαÑÇ αñ¿αÑç αñ╡αñ┐αññαÑìαññ αñ«αñéαññαÑìαñ░αÑÇ αñ¿αñ┐αñ░αÑìαñ«αñ▓αñ╛ αñ╕αÑÇαññαñ╛αñ░αñ«αñú αñòαÑï αñªαñ┐αñ»αñ╛αÑñ αñòαÑçαñéαñªαÑìαñ░αÑÇαñ» αñûαñ╛αñªαÑìαñ» αñ¿αñ┐αñ»αñ╛αñ«αñò αñÅαñ½αñÅαñ╕αñÅαñ╕αñÅαñåαñê αñ¿αÑç αñ░αñ╛αñ£αÑìαñ» αñöαñ░ αñòαÑçαñéαñªαÑìαñ░\n20:36\n20 minutes, 36 seconds\nαñ╢αñ╛αñ╕αñ┐αññ αñ¬αÑìαñ░αñªαÑçαñ╢αÑïαñé αñ╕αÑç αñûαñ╛αñªαÑìαñ» αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñóαñ╛αñéαñÜαÑç αñòαÑï αñ«αñ£αñ¼αÑéαññ αñòαñ░αñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ αñ▓αñéαñ¼αñ┐αññ αñ░αñ┐αñòαÑìαññ αñ¬αñªαÑïαñé αñòαÑï αñ╢αÑÇαñÿαÑìαñ░ αñ¡αñ░αñ¿αÑç αñòαñ╛ αñåαñùαÑìαñ░αñ╣ αñòαñ┐αñ»αñ╛αÑñ\n20:43\n20 minutes, 43 seconds\nαñ¡αñ╛αñ░αññαÑÇαñ» αñòαñéαñ¬αñ¿αñ┐αñ»αÑïαñé αñ¿αÑç αñ╕αÑéαñÜαñò αñ¬αÑìαñ░αÑîαñªαÑìαñ»αÑïαñùαñ┐αñòαÑÇ αñ£αÑÇαñ╡αñ¿ αñ╡αñ┐αñ£αÑìαñ₧αñ╛αñ¿ αñöαñ░ αñ╡αñ┐αñ¿αñ┐αñ░αÑìαñ«αñ╛αñú αñ╕αñ╣αñ┐αññ αñ╡αñ┐αñ¡αñ┐αñ¿αÑìαñ¿ αñòαÑìαñ╖αÑçαññαÑìαñ░αÑïαñé αñ«αÑçαñé αñòαñ¿αñ╛αñíαñ╛ αñ«αÑçαñé αñ▓αñùαñ¡αñù 11 αñàαñ░αñ¼ αñòαñ¿αñ╛αñíαñ╛αñê αñíαÑëαñ▓αñ░ αñòαñ╛ αñ¿αñ┐αñ╡αÑçαñ╢ αñòαñ┐αñ»αñ╛αÑñ\n20:53\n20 minutes, 53 seconds\nαñ╕αÑÇαñåαñêαñåαñê αñöαñ░ αñòαñ¿αñ╛αñíαñ╛ αñ¡αñ╛αñ░αññ αñ╡αÑìαñ»αñ╛αñ¬αñ╛αñ░ αñ¬αñ░αñ┐αñ╖αñª αñòαÑÇ αñ░αñ┐αñ¬αÑïαñ░αÑìαñƒ αñòαÑç αñàαñ¿αÑüαñ╕αñ╛αñ░ αñòαñ¿αñ╛αñíαñ╛ αñòαÑç 10 αñ«αÑçαñé αñ╕αÑç αñåαñá αñ¬αÑìαñ░αñ╛αñéαññαÑïαñé αñ«αÑçαñé 50 αñ¡αñ╛αñ░αññαÑÇαñ» αñòαñéαñ¬αñ¿αñ┐αñ»αñ╛αñé αñ╕αñòαÑìαñ░αñ┐αñ»\n21:00\n21 minutes\nαñ╣αÑêαñé αñöαñ░ αñëαñ¿αÑìαñ╣αÑïαñéαñ¿αÑç 33,000 αñ╕αÑç αñàαñºαñ┐αñò αñ¿αÑîαñòαñ░αñ┐αñ»αñ╛αñé αñ¬αÑêαñªαñ╛ αñòαÑÇαÑñ BMW αñùαÑìαñ░αÑüαñ¬ αñçαñéαñíαñ┐αñ»αñ╛ αñ¿αÑç αñÿαÑïαñ╖αñúαñ╛ αñòαÑÇ αñòαñ┐ αñ╡αñ╣ 1 αñ£αÑüαñ▓αñ╛αñê 2026 αñ╕αÑç αñàαñ¬αñ¿αÑç BMW αñöαñ░ αñ«αñ┐αñ¿αÑÇ αñòαñ╛αñ░αÑïαñé αñòαÑÇ αñòαÑÇαñ«αññαÑïαñé αñ«αÑçαñé 2% αññαñò αñ¼αñóαñ╝αÑïαññαñ░αÑÇ αñòαñ░αÑçαñùαñ╛αÑñ\n21:12\n21 minutes, 12 seconds\nBMW αñòαñéαñ¬αñ¿αÑÇ αñ¿αÑç αñ¼αññαñ╛αñ»αñ╛ αñòαñ┐ αñ░αÑüαñ¬αñÅ αñ«αÑçαñé αñùαñ┐αñ░αñ╛αñ╡αñƒ αñöαñ░ αñ▓αÑëαñ£αñ┐αñ╕αÑìαñƒαñ┐αñòαÑìαñ╕ αñ▓αñ╛αñùαññ αñ¼αñóαñ╝αñ¿αÑç αñòαÑç αñòαñ╛αñ░αñú αñ»αñ╣ αñ½αÑêαñ╕αñ▓αñ╛ αñ▓αñ┐αñ»αñ╛ αñùαñ»αñ╛αÑñ αñ»αñ╣ αñ¼αñóαñ╝αÑïαññαñ░αÑÇ αñ¡αñ╛αñ░αññ αñ«αÑçαñé αñ¼αñ¿αÑç αñöαñ░ αñ¬αÑéαñ░αÑÇ αññαñ░αñ╣ αñåαñ»αñ╛αññαñ┐αññ αñ╕αñ¡αÑÇ αñ«αÑëαñíαñ▓αÑïαñé αñ¬αñ░ αñ▓αñ╛αñùαÑé αñ╣αÑïαñùαÑÇαÑñ\n21:23\n21 minutes, 23 seconds\nαñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñ╕αñéαñÿαÑÇαñ» αñàαñªαñ╛αñ▓αññ αñ«αÑçαñé αñÅαñÜ1 αñ¼αÑÇ αñ╡αÑÇαñ£αñ╛ αñ¬αñ░ $1 αñ▓αñ╛αñû αñ╢αÑüαñ▓αÑìαñò αñ▓αñùαñ╛αñ¿αÑç αñòαÑç αñƒαÑìαñ░αñéαñ¬ αñ¬αÑìαñ░αñ╢αñ╛αñ╕αñ¿ αñòαÑç αñ½αÑêαñ╕αñ▓αÑç αñòαÑï αñ░αñªαÑìαñª αñòαñ┐αñ»αñ╛αÑñ αñàαñªαñ╛αñ▓αññ αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñ╕αñéαñÿαÑÇαñ» αñ╕αñ░αñòαñ╛αñ░ αñòαÑç αñ¬αñ╛αñ╕ αñÉαñ╕αñ╛ αñ╢αÑüαñ▓αÑìαñò αñ▓αñùαñ╛αñ¿αÑç αñòαñ╛ αñ╕αÑìαñ¬αñ╖αÑìαñƒ αñòαñ╛αñ¿αÑéαñ¿αÑÇ αñàαñºαñ┐αñòαñ╛αñ░ αñ¿αñ╣αÑÇαñé αñÑαñ╛αÑñ\n21:35\n21 minutes, 35 seconds\nαñÅαñ╕αñÅαñ¼αÑÇ αñ╢αÑüαñ▓αÑìαñò αñ¼αñóαñ╝αñ¿αÑç αñ╕αÑç αñ╡αñ┐αñªαÑçαñ╢αÑÇ αñ¬αÑçαñ╢αÑçαñ╡αñ░αÑïαñé αñòαÑÇ αñ¡αñ░αÑìαññαÑÇ αñ¬αÑìαñ░αñ¡αñ╛αñ╡αñ┐αññ αñ╣αÑï αñ░αñ╣αÑÇ αñ╣αÑê αñ£αñ┐αñ╕αñòαñ╛ αñàαñ╕αñ░ αñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñàαñ░αÑìαñÑαñ╡αÑìαñ»αñ╡αñ╕αÑìαñÑαñ╛ αñ¬αñ░ αñ¡αÑÇ αñ¬αñíαñ╝αñ╛αÑñ\n21:44\n21 minutes, 44 seconds\nαñêαñ░αñ╛αñ¿ αñöαñ░ αñçαñ£αñ░αñ╛αñçαñ▓ αñ¿αÑç αñÅαñò αñªαÑéαñ╕αñ░αÑç αñ¬αñ░ αñ╣αñ«αñ▓αÑç αñ░αÑïαñòαñ¿αÑç αñòαÑÇ αñÿαÑïαñ╖αñúαñ╛ αñòαÑÇαÑñ αñ»αñ╣ αñ½αÑêαñ╕αñ▓αñ╛ αñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ¬αññαñ┐ αñíαÑïαñ¿αñ╛αñ▓αÑìαñí αñƒαÑìαñ░αñéαñ¬ αñòαÑÇ αññαññαÑìαñòαñ╛αñ▓ αñ»αÑüαñªαÑìαñº αñ╡αñ┐αñ░αñ╛αñ« αñòαÑÇ αñàαñ¬αÑÇαñ▓ αñòαÑç αñ¼αñ╛αñª αñ▓αñ┐αñ»αñ╛ αñùαñ»αñ╛αÑñ\n21:52\n21 minutes, 52 seconds\nαñêαñ░αñ╛αñ¿ αñòαÑç αñ╢αÑÇαñ░αÑìαñ╖ αñ╡αñ╛αñ░αÑìαññαñ╛αñòαñ╛αñ░ αñ«αÑïαñ╣αñ«αÑìαñ«αñª αñ╡αñ╛αñòαÑçαñ░ αñòαñ▓αñ┐αñ¼αñ╛αñ½ αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αññαÑçαñ╣αñ░αñ╛αñ¿ αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñªαÑìαñ╡αñ╛αñ░αñ╛ αñ╕αÑìαñÑαñ╛αñ¬αñ┐αññ αñ¿αÑîαñ╕αÑêαñ¿αñ┐αñò αñ¿αñ╛αñòαñ╛αñ¼αñéαñªαÑÇ αñòαÑï αñ╢αññαÑìαñ░αÑü αñòαÑÇ αñÅαñò αñöαñ░ αñ╣αñ╛αñ░ αñ«αÑçαñé αñ¼αñªαñ▓ αñªαÑçαñùαñ╛αÑñ\n22:02\n22 minutes, 2 seconds\nαñ«αÑïαñ╣αñ«αÑìαñ«αñª αñ╡αñ╛αñòαÑçαñ░ αñòαñ▓αñ┐αñ¼αñ╛αñ½ αñ¿αÑç αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñ¬αñ░ αñ╕αñ╣αñ«αññαñ┐ αñ╕αÑç αñ¬αÑÇαñ¢αÑç αñ╣αñƒαñ¿αÑç αñòαñ╛ αñåαñ░αÑïαñ¬ αñ▓αñùαñ╛αññαÑç αñ╣αÑüαñÅ αñòαñ╣αñ╛ αñòαñ┐ αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñ¿αñ╛ αññαÑï αñ»αÑüαñªαÑìαñº αñ╡αñ┐αñ░αñ╛αñ« αñÜαñ╛αñ╣αññαñ╛ αñ╣αÑê αñöαñ░ αñ¿αñ╛ αñ╣αÑÇ αñ╕αñ╛αñ░αÑìαñÑαñò αñ¼αñ╛αññαñÜαÑÇαññαÑñ\n22:12\n22 minutes, 12 seconds\nαñòαñ▓αñ┐αñ¼αñ╛αñ½ αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñêαñ░αñ╛αñ¿ αñòαñ╛ αñ▓αñòαÑìαñ╖αÑìαñ» αñ╣αÑê αñ»αÑüαñªαÑìαñº αñ╕αñ«αñ╛αñ¬αÑìαññ αñòαñ░αñ¿αñ╛ αñöαñ░ αñ╕αÑìαñÑαñ╛αñê αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñ╕αÑìαñÑαñ╛αñ¬αñ┐αññ αñòαñ░αñ¿αñ╛αÑñ αñ▓αÑçαñòαñ┐αñ¿ αñëαñ╕αÑç αñ╡αñ┐αñ░αÑïαñºαÑÇ αñ¬αñòαÑìαñ╖ αñ¬αñ░ αñ¡αñ░αÑïαñ╕αñ╛ αñ¿αñ╣αÑÇαñéαÑñ\n22:21\n22 minutes, 21 seconds\nαñ╕αñéαñ»αÑüαñòαÑìαññ αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░ αñ¿αÑç αñùαñ╛αñ£αñ╛ αñòαÑç αñ╕αñ¡αÑÇ αñ¬αÑìαñ░αñ«αÑüαñû αñ¬αÑìαñ░αñ╡αÑçαñ╢ αñ¼αñ┐αñéαñªαÑü αñ¼αñéαñª αñòαñ┐αñÅ αñ£αñ╛αñ¿αÑç αñ¬αñ░ αñÜαñ┐αñéαññαñ╛ αñ£αñ╛αñ╣αñ┐αñ░ αñòαÑÇαÑñ αñòαñ╣αñ╛ αñ¿αñ╛αñùαñ░αñ┐αñòαÑïαñé αñòαÑç αñ▓αñ┐αñÅ αñ«αñ╛αñ¿αñ╡αÑÇαñ» αñ╕αñ╣αñ╛αñ»αññαñ╛ αñöαñ░ αñåαñ╡αñ╢αÑìαñ»αñò αñ╡αñ╕αÑìαññαÑü αñòαÑÇ αñ¿αñ┐αñ░αÑìαñ╡αñ╛αñª αñåαñ¬αÑéαñ░αÑìαññαñ┐ αñ£αñ░αÑéαñ░αÑÇαÑñ\n22:30\n22 minutes, 30 seconds\nαñ«αñ╣αñ╛αñ╕αñÜαñ┐αñ╡ αñÅαñéαñƒαÑïαñ¿αÑÇ αñùαÑüαñƒαÑçαñ░αñ╕ αñ¿αÑç αñùαñ╛αñ£αñ╛ αñ«αÑçαñé αñ░αñ╛αñ╣αññ αñ╕αñ╛αñ«αñùαÑìαñ░αÑÇ αñòαÑÇ αñåαñ╡αñ╛αñ£αñ╛αñ╣αÑÇ αññαññαÑìαñòαñ╛αñ▓ αñ¼αñ╣αñ╛αñ▓ αñòαñ░αñ¿αÑç αñöαñ░ αñ¿αñ╛αñùαñ░αñ┐αñòαÑïαñé αñòαÑÇ αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñ╕αÑüαñ¿αñ┐αñ╢αÑìαñÜαñ┐αññ αñòαñ░αñ¿αÑç αñòαÑÇ αñàαñ¬αÑÇαñ▓ αñòαÑÇαÑñ\n22:38\n22 minutes, 38 seconds\nαñ╕αñéαñ»αÑüαñòαÑìαññ αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░ αñ¿αÑç αñ╡αÑçαñ╕αÑìαñƒ αñ¼αÑêαñéαñò αñ«αÑçαñé αñ£αñ╛αñ░αÑÇ αñ╣αñ┐αñéαñ╕αñ╛ αñöαñ░ αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñûαññαñ░αÑïαñé αñ¬αñ░ αñÜαñ┐αñéαññαñ╛ αñ£αññαñ╛αñê αñöαñ░ αñ½αñ┐αñ░ αñ╕αÑìαññαñ░αÑÇαñ» αñ¿αñ╛αñùαñ░αñ┐αñòαÑïαñé αñòαÑÇ αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñ╕αÑüαñ¿αñ┐αñ╢αÑìαñÜαñ┐αññ αñòαñ░αñ¿αÑç αñòαÑÇ αñàαñ¬αÑÇαñ▓ αñòαÑÇαÑñ\n22:46\n22 minutes, 46 seconds\nαñ¼αÑïαñ▓αÑÇαñ╡αñ┐αñ»αñ╛ αñòαÑç αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ¬αññαñ┐ αñ¿αÑç αñåαñ¬αñ╛αññαñòαñ╛αñ▓ αñòαÑï αñ╡αñ┐αñ¿αñ┐αñ»αñ«αñ┐αññ αñòαñ░αñ¿αÑç αñ╡αñ╛αñ▓αÑç αñ╡αñ┐αñºαÑçαñ»αñò αñ¬αñ░ αñ╣αñ╕αÑìαññαñ╛αñòαÑìαñ╖αñ░ αñòαñ░ αñëαñ╕αÑç αñòαñ╛αñ¿αÑéαñ¿ αñòαñ╛ αñ░αÑéαñ¬ αñªαñ┐αñ»αñ╛αÑñ\n22:53\n22 minutes, 53 seconds\nαñ¿αñ»αñ╛ αñòαñ╛αñ¿αÑéαñ¿ αñåαñéαññαñ░αñ┐αñò αñ╕αñéαñÿαñ░αÑìαñ╖ αñ¬αÑìαñ░αñ╛αñòαÑâαññαñ┐αñò αñåαñ¬αñªαñ╛ αñ»αñ╛ αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αÑÇαñ» αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñ╕αñéαñòαñƒ αñòαÑç αñªαÑîαñ░αñ╛αñ¿ αñ╕αñ░αñòαñ╛αñ░ αñòαÑï αñ╡αñ┐αñ╢αÑçαñ╖ αñàαñºαñ┐αñòαñ╛αñ░ αñªαÑçαññαñ╛ αñ╣αÑê αñöαñ░ αñåαñéαññαñ░αñ┐αñò αñàαñ╢αñ╛αñéαññαñ┐ αñòαÑç αñªαÑîαñ░αñ╛αñ¿ αñ╕αÑçαñ¿αñ╛ αñòαÑÇ αñ¡αÑéαñ«αñ┐αñòαñ╛ αñ╕αÑìαñ¬αñ╖αÑìαñƒ αñòαñ░αññαñ╛ αñ╣αÑêαÑñ\n23:05\n23 minutes, 5 seconds\nαñÜαñ┐αñ▓αÑÇ αñòαÑç αñàαñºαñ┐αñòαñ╛αñ░αñ┐αñ»αÑïαñé αñ¿αÑç αñªαÑçαñ╢ αñòαÑç αñ¬αÑìαñ░αñ«αÑüαñû αñ¼αñéαñªαñ░αñùαñ╛αñ╣αÑïαñé αñ¬αñ░ 100 αñƒαñ¿ αñ╕αÑç αñ£αÑìαñ»αñ╛αñªαñ╛ αñ«αñ╛αñªαñò αñ¬αñªαñ╛αñ░αÑìαñÑαÑïαñé αñ╕αÑç αñªαÑéαñ╖αñ┐αññ αñ▓αñòαñíαñ╝αÑÇ αñ£αñ¼αÑìαññ αñòαÑÇ αñöαñ░ αñçαñ╕αÑç αñªαÑçαñ╢ αñòαÑç αñçαññαñ┐αñ╣αñ╛αñ╕ αñòαÑÇ αñ╕αñ¼αñ╕αÑç αñ¼αñíαñ╝αÑÇ αñíαÑìαñ░αñùαÑìαñ╕ αñ£αÑìαññαÑÇ αñòαñ╛αñ░αñ╡αñ╛αñê αñ¼αññαñ╛αñ»αñ╛αÑñ\n23:16\n23 minutes, 16 seconds\nαñ»αñ╣ αñòαñ╛αñ░αñ╡αñ╛αñê αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑîαñ╕αÑçαñ¿αñ╛ αñöαñ░ αñ╕αÑÇαñ«αñ╛ αñ╢αÑüαñ▓αÑìαñò αñ╡αñ┐αñ¡αñ╛αñù αñ¿αÑç αñ«αñ┐αñ▓αñòαñ░ αñòαÑÇαÑñ αñàαñºαñ┐αñòαñ╛αñ░αñ┐αñ»αÑïαñé αñòαÑç αñàαñ¿αÑüαñ╕αñ╛αñ░ αñ£αñ¼αÑìαññ αñ▓αñòαñíαñ╝αÑÇ αñ«αÑçαñé 10 αñ╕αÑç 20% αññαñò αñòαÑïαñòαñ┐αñ¿ αñ╣αñ╛αñê αñ╣αñ╛αñçαñíαÑìαñ░αÑïαñòαÑìαñ▓αÑïαñ░αñ╛αñçαñí αñöαñ░ αñòαÑêαñƒαñ╛αñ«αñ╛αñçαñ¿ αñ«αñ┐αñ▓αÑçαÑñ\n23:28\n23 minutes, 28 seconds\nαñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñòαÑç αñƒαÑçαñòαÑìαñ╕αñ╛αñ╕ αñöαñ░ αñ¿αÑìαñ»αÑé αñ«αÑçαñòαÑìαñ╕αñ┐αñòαÑï αñ«αÑçαñé αñ¿αÑìαñ»αÑé αñ╡αñ░αÑìαñ▓αÑìαñí αñ╕αÑìαñòαÑìαñ░αÑéαñ¼αñ░αÑìαñ« αñ╕αñéαñòαÑìαñ░αñ«αñú αñòαÑç αññαÑÇαñ¿ αñ¿αñÅ αñ«αñ╛αñ«αñ▓αÑïαñé αñòαÑÇ αñ¬αÑüαñ╖αÑìαñƒαñ┐ αñòαÑç αñ¼αñ╛αñª αñòαÑüαñ▓ αñ«αñ╛αñ«αñ▓αÑïαñé αñòαÑÇ αñ╕αñéαñûαÑìαñ»αñ╛ αñ¼αñóαñ╝αñòαñ░ αñ¬αñ╛αñéαñÜ αñ╣αÑüαñêαÑñ\n23:37\n23 minutes, 37 seconds\nαñ╡αñ╣αÑÇαñé αñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñòαÑâαñ╖αñ┐ αñ╡αñ┐αñ¡αñ╛αñù αñ¿αÑç αñ╕αÑìαñòαÑìαñ░αÑéαñ½αñ░αÑìαñ« αñ¿αñ┐αñ»αñéαññαÑìαñ░αñú αññαñòαñ¿αÑÇαñòαÑïαñé αñòαÑç αñ▓αñ┐αñÅ 100 αñ«αñ┐αñ▓αñ┐αñ»αñ¿ αñíαÑëαñ▓αñ░ αñòαÑç αñ½αñéαñí αñòαÑç αññαñ╣αññ αñ£αñ▓αÑìαñª αñ¿αñê αñÿαÑïαñ╖αñúαñ╛αñÅαñé αñòαñ░αñ¿αÑç αñòαÑÇ αñ¼αñ╛αññ αñòαñ╣αÑÇαÑñ\n23:47\n23 minutes, 47 seconds\nαñ╕αÑìαñ¬αÑçαñ¿ αñªαÑîαñ░αÑç αñòαÑç αññαÑÇαñ╕αñ░αÑç αñªαñ┐αñ¿ αñ¬αÑëαñ¬ αñ▓αñ┐αñ»αÑï 14αñÑ αñ¿αÑç αñ¬αÑéαñ░αÑìαñ╡ αñ░αñ╛αñ£αñ╛ αñòαÑÇ αñ¬αññαÑìαñ¿αÑÇ αñòαÑìαñ╡αÑÇαñ¿ αñ╕αÑïαñ½αñ┐αñ»αñ╛ αñöαñ░ αñ╡αñ┐αñ¬αñòαÑìαñ╖αÑÇ αñ¿αÑçαññαñ╛ αñàαñ▓αÑìαñ¼αñ░αÑìαñƒαÑïαñ╕ αñ▓αñ¿αÑçαñ╕ αñ½αÑêαñ£αÑé αñ╕αÑç αñ«αÑüαñ▓αñ╛αñòαñ╛αññ αñòαÑÇαÑñ\n23:58\n23 minutes, 58 seconds\nαñ¬αÑïαñ¬αñ▓αñ┐αñ»αÑï αñ¿αÑç αñ«αÑçαñíαÑìαñ░αñ┐αñí αñòαÑç αñ╕αÑçαñéαñƒαñ┐αñ»αñ╛αñùαÑï αñ╡αñ¿αñ╡αÑçαñè αñ╕αÑìαñƒαÑçαñíαñ┐αñ»αñ« αñòαñ╛ αñªαÑîαñ░αñ╛ αñ¡αÑÇ αñòαñ┐αñ»αñ╛αÑñ αñ£αñ╣αñ╛αñé αñ╣αñ£αñ╛αñ░αÑïαñé αñ▓αÑïαñùαÑïαñé αñ¿αÑç αñëαñ¿αñòαñ╛ αñ╕αÑìαñ╡αñ╛αñùαññ αñòαñ┐αñ»αñ╛αÑñ\n24:05\n24 minutes, 5 seconds\nT20 αñòαÑìαñ░αñ┐αñòαÑçαñƒ αñ╡αñ┐αñ╢αÑìαñ╡ αñòαñ¬ αñòαÑç αñàαñ¡αÑìαñ»αñ╛αñ╕ αñ«αÑêαñÜ αñ«αÑçαñé αñ¡αñ╛αñ░αññαÑÇαñ» αñ«αñ╣αñ┐αñ▓αñ╛ αñƒαÑÇαñ« αñ¿αÑç αñçαñéαñíαÑÇαñ£ αñòαÑï 26 αñ░αñ¿ αñ╕αÑç αñ╣αñ░αñ╛αñ»αñ╛αÑñ αñ¡αñ╛αñ░αññαÑÇαñ» αñ½αñ┐αñ▓αÑìαñ« αñ«αñ╛αñ▓αÑÇ αñ¿αÑç αñûαÑçαñ▓αÑÇ 56 αñ░αñ¿\n24:13\n24 minutes, 13 seconds\nαñòαÑÇ αñ¿αñ╛αñ¼αñ╛αñª αñ¬αñ╛αñ░αÑÇαÑñ αñ░αñ╛αñºαñ╛ αñ»αñ╛αñªαñ╡ αñ¿αÑç αññαÑÇαñ¿ αñöαñ░ αñ╢αÑìαñ░αÑçαñ»αñòαñ╛ αñ¬αñ╛αñƒαñ┐αñ▓ αñ¿αÑç αñÜαñ╛αñ░ αñ╡αñ┐αñòαÑçαñƒ αñ▓αñ┐αñÅαÑñ\n24:19\n24 minutes, 19 seconds\nαñ¡αñ╛αñ░αññ αñ¿αÑç αñàαñ½αñùαñ╛αñ¿αñ┐αñ╕αÑìαññαñ╛αñ¿ αñòαÑï αñ¿αÑìαñ»αÑé αñÜαñéαñíαÑÇαñùαñóαñ╝ αñƒαÑçαñ╕αÑìαñƒ αñ«αÑçαñé αñ¬αñ╛αñ░αÑÇ αñöαñ░ 300 αñ░αñ¿ αñ╕αÑç αñ╣αñ░αñ╛αñ»αñ╛αÑñ\n24:25\n24 minutes, 25 seconds\nαñƒαÑçαñ╕αÑìαñƒ αñòαÑìαñ░αñ┐αñòαÑçαñƒ αñ«αÑçαñé αñàαñ¬αñ¿αÑÇ αñ╕αñ¼αñ╕αÑç αñ¼αñíαñ╝αÑÇ αñ£αÑÇαññ αñªαñ░αÑìαñ£ αñòαÑÇαÑñ\n24:30\n24 minutes, 30 seconds\nαñ¬αÑéαñ░αÑìαñ╡ αñ¡αñ╛αñ░αññαÑÇαñ» αñòαñ¬αÑìαññαñ╛αñ¿ αñ╕αÑîαñ░αñ╡ αñùαñ╛αñéαñùαÑüαñ▓αÑÇ αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñ╡αÑêαñ¡αñ╡ αñ╕αÑéαñ░αÑìαñ»αñ╡αñéαñ╢αÑÇ αñòαÑï αñàαñ¬αñ¿αÑç αñûαÑçαñ▓ αñ«αÑçαñé αñóαñ▓αñ¿αÑç αñòαñ╛ αñ╕αñ«αñ» αñªαñ┐αñ»αñ╛ αñ£αñ╛αñÅαÑñ αñàαñ¬αÑçαñòαÑìαñ╖αñ╛αñôαñé αñòαÑç αñ¼αÑïαñ¥ αñ╕αÑç αñ¼αñÜαñ¿αÑç αñòαÑÇ αñ¡αÑÇ αñ╕αñ▓αñ╛αñ╣ αñªαÑÇαÑñ\n24:39\n24 minutes, 39 seconds\nαñ¡αñ╛αñ░αññαÑÇαñ» αññαÑÇαñ░αñéαñªαñ╛αñ£αÑÇ αñƒαÑÇαñ« αñåαñ£ αñ╕αÑç αññαÑüαñ░αÑìαñòαñ┐αñÅ αñ«αÑçαñé αñ╢αÑüαñ░αÑé αñ╣αÑï αñ░αñ╣αÑç αñ╡αñ┐αñ╢αÑìαñ╡ αñòαñ¬ αññαÑÇαñ╕αñ░αÑç αñÜαñ░αñú αñ«αÑçαñé αñ▓αÑçαñùαÑÇ αñ╣αñ┐αñ╕αÑìαñ╕αñ╛αÑñ αñåαñùαñ╛αñ«αÑÇ αñÅαñ╢αñ┐αñ»αñ╛αñê αñûαÑçαñ▓αÑïαñé αñòαÑÇ αññαÑêαñ»αñ╛αñ░αÑÇ αñ¬αñ░ αñ░αñ╣αÑçαñùαÑÇ αñ¿αñ£αñ░αÑñ\n24:48\n24 minutes, 48 seconds\nαñ¿αñ┐αñ╢αñ╛αñ¿αÑçαñ¼αñ╛αñ£ αñ░αñ╛αñ╣αÑÇ αñ╕αñ░αñ¿αÑïαñ¼αññ αñòαñ╛ αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αÑÇαñ» αñÜαñ»αñ¿ αñƒαÑìαñ░αñ╛αñ»αñ▓ αñ½αÑïαñ░ αñ«αÑçαñé αñ╢αñ╛αñ¿αñªαñ╛αñ░ αñ¬αÑìαñ░αñªαñ░αÑìαñ╢αñ¿αÑñ αñ«αñ¿αÑüαñ¡αñ╛αñòαñ░ αñòαÑï αñ¬αñ¢αñ╛αñíαñ╝αñòαñ░ αñ╣αñ╛αñ╕αñ┐αñ▓ αñòαñ┐αñ»αñ╛ αñ╢αÑÇαñ░αÑìαñ╖ αñ╕αÑìαñÑαñ╛αñ¿αÑñ\n24:59\n24 minutes, 59 seconds\nαñÜαÑÇαñ¿ αñòαÑç αñƒαÑçαñ¿αñ┐αñ╕ αñûαñ┐αñ▓αñ╛αñíαñ╝αÑÇ αñ╢αñ┐αñ¿αñ¬αÑçαñ¿ αñ¥αÑçαñéαñòαÑï αñòαÑìαñ╡αÑÇαñéαñ╕ αñòαÑìαñ▓αñ¼ αñÜαÑêαñéαñ¬αñ┐αñ»αñ¿αñ╢αñ┐αñ¬ αñòαÑç αñ¬αñ╣αñ▓αÑç αñªαÑîαñ░ αñ«αÑçαñé αñ«αñ┐αñ▓αÑÇ αñ╣αñ╛αñ░αÑñ αñ¥αÑçαñé αñ░αÑïαñ«αñ╛αñ¿αñ┐αñ»αñ╛ αñòαÑÇ αñòαÑìαñ░αñ┐αñ╢αÑìαñÜαñ┐αñ»αñ¿ αñ¿αÑç αñªαÑÇ αñ«αñ╛αññαÑñ\n25:09\n25 minutes, 9 seconds\nαñíαÑçαñ¿αñ«αñ╛αñ░αÑìαñò αñòαÑç αñ«αñ┐αñíαñ½αÑÇαñ▓αÑìαñíαñ░ αñòαÑìαñ░αñ┐αñ╢αÑìαñÜαñ┐αñ»αñ¿ αñÅαñ░αñ┐αñòαÑìαñ╕αñ¿ αñòαÑÇ αññαñ¼αÑÇαñ»αññ αñ«αÑçαñé αñ╣αÑï αñ░αñ╣αñ╛ αñ╣αÑê αñ╕αÑüαñºαñ╛αñ░αÑñ αñ»αÑéαñòαÑìαñ░αÑçαñ¿ αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñªαÑïαñ╕αÑìαññαñ╛αñ¿αñ╛ αñ«αÑêαñÜ αñòαÑç αñªαÑîαñ░αñ╛αñ¿ αñ╣αÑüαñÅ αñÑαÑç αñ¼αÑçαñ╣αÑïαñ╢αÑñ\n25:19\n25 minutes, 19 seconds\nαñ½αÑüαñƒαñ¼αÑëαñ▓ αñ╡αñ┐αñ╢αÑìαñ╡ αñòαñ¬ αñ╕αÑç αñ¬αñ╣αñ▓αÑç αñûαÑçαñ▓αÑç αñùαñÅ αñªαÑïαñ╕αÑìαññαñ╛αñ¿αñ╛ αñ«αÑêαñÜ αñ«αÑçαñé αñ½αÑìαñ░αñ╛αñéαñ╕ αñ¿αÑç αñëαññαÑìαññαñ░αÑÇ αñåαñ»αñ░αñ▓αÑêαñéαñí αñòαÑï αññαÑÇαñ¿ αñÅαñò αñ╕αÑç αñ╣αñ░αñ╛αñ»αñ╛αÑñ\n25:27\n25 minutes, 27 seconds\nαñàαñ░αÑìαñ£αÑçαñéαñƒαÑÇαñ¿αñ╛ αñöαñ░ αñåαñçαñ╕αñ▓αÑêαñéαñí αñòαÑç αñ¼αÑÇαñÜ αñªαÑïαñ╕αÑìαññαñ╛αñ¿αñ╛ αñ½αÑüαñƒαñ¼αÑëαñ▓ αñ«αÑêαñÜαÑñ αñåαñ£ αñàαñ¡αÑìαñ»αñ╛αñ╕ αñ«αÑçαñé αñƒαÑÇαñ« αñòαÑç αñòαñ¬αÑìαññαñ╛αñ¿ αñ▓αÑëαñ»αñ¿αñ▓ αñ«αÑçαñ╕αÑÇ αñ¿αÑç αñ¡αÑÇ αñ▓αñ┐αñ»αñ╛ αñ╣αñ┐αñ╕αÑìαñ╕αñ╛αÑñ\n25:36\n25 minutes, 36 seconds\nαñ▓αÑçαñ«αñ┐αñ¿αñ┐αñ»αñ«αñ╛αñ▓ αñ¿αñ┐αñòαÑï αñ╡αñ┐αñ▓αñ┐αñ»αñ«αÑìαñ╕ αñöαñ░ αñ╡αñ┐αñòαÑìαñƒαñ░ αñ«αÑüαñ¿αÑïαñ£αÑï αñ╡αñ┐αñ╢αÑìαñ╡ αñòαñ¬ αñ╕αÑç αñ¬αñ╣αñ▓αÑç αñ╣αÑï αñ╕αñòαññαÑç αñ╣αÑêαñé αñ½αñ┐αñƒαÑñ\n25:42\n25 minutes, 42 seconds\nαñ╕αÑìαñ¬αÑçαñ¿ αñòαÑç αñòαÑïαñÜ αñ¿αÑç αññαÑÇαñ¿αÑïαñé αñòαÑç αñ¬αñ╣αñ▓αÑç αñ«αÑêαñÜ αñòαÑç αñ▓αñ┐αñÅ αñëαñ¬αñ▓αñ¼αÑìαñº αñ╣αÑïαñ¿αÑç αñòαÑÇ αñëαñ«αÑìαñ«αÑÇαñª αñ£αññαñ╛αñêαÑñ\n25:48\n25 minutes, 48 seconds\nαñ¿αÑÇαñªαñ░αñ▓αÑêαñéαñíαÑìαñ╕ αñòαÑç αñ£αñ░αñ┐αñ»αñ¿ αñƒαñ┐αñ«αñ¼αñ░ αñ½αÑüαñƒαñ¼αÑëαñ▓ αñ╡αñ┐αñ╢αÑìαñ╡ αñòαñ¬ αñ╕αÑç αñ¼αñ╛αñ╣αñ░ αñÜαÑïαñƒ αñòαÑç αñòαñ╛αñ░αñú αñ¿αñ╣αÑÇαñé αñûαÑçαñ▓ αñ¬αñ╛αñÅαñéαñùαÑç αñ½αÑüαñƒαñ¼αÑëαñ▓ αñ╡αñ┐αñ╢αÑìαñ╡ αñòαñ¬αÑñ\n25:55\n25 minutes, 55 seconds\nαñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñƒαÑÇαñ« αñòαÑç αñàαñ¡αÑìαñ»αñ╛αñ╕ αñ«αÑêαñÜ αñòαÑï αñªαÑçαñûαñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ 5000 αñ╕αÑç αñ£αÑìαñ»αñ╛αñªαñ╛ αñ¬αÑìαñ░αñ╢αñéαñ╕αñò αñ¬αñ╣αÑüαñéαñÜαÑçαÑñ\n26:00\n26 minutes\nαñ«αÑçαñòαÑìαñ╕αñ┐αñòαÑï αñ½αÑüαñƒαñ¼αÑëαñ▓ αñƒαÑÇαñ« αñòαÑç αñ▓αñ┐αñÅ αñ«αÑçαñòαÑìαñ╕αñ┐αñòαÑï αñ╕αñ┐αñƒαÑÇ αñ«αÑçαñé αñÅαñò αñ╕αÑçαñéαñƒ αñæαñ½ αñ╕αÑçαñ░αÑçαñ«αñ¿αÑÇ αñòαñ╛ αñåαñ»αÑïαñ£αñ¿αÑñ αñ╡αñ┐αñ╢αÑìαñ╡ αñòαñ¬ αñ«αÑçαñé αñ╕αñ╣αñ« αñ«αÑçαñ£αñ¼αñ╛αñ¿ αñ«αÑçαñòαÑìαñ╕αñ┐αñòαÑï αñòαñ╛ αñ¬αñ╣αñ▓αñ╛ αñ«αÑêαñÜ αñªαñòαÑìαñ╖αñ┐αñú αñàαñ½αÑìαñ░αÑÇαñòαñ╛ αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñ╣αÑïαñùαñ╛αÑñ\n26:12\n26 minutes, 12 seconds\n2026 αñ½αÑüαñƒαñ¼αÑëαñ▓ αñ╡αñ┐αñ╢αÑìαñ╡ αñòαñ¬ αñ½αñ╛αñçαñ¿αñ▓ αñòαÑç αñªαÑîαñ░αñ╛αñ¿ αñ¿αÑìαñ»αÑéαñ»αÑëαñ░αÑìαñò αñòαÑç αñ╕αÑçαñéαñƒαÑìαñ░αñ▓ αñ¬αñ╛αñ░αÑìαñò αñ«αÑçαñé αñ╣αÑïαñùαÑÇ αñ½αÑìαñ░αÑÇ αñ╡αÑëαñÜ αñ¬αñ╛αñ░αÑìαñƒαÑÇαÑñ αñ¿αÑìαñ»αÑéαñ»αÑëαñ░αÑìαñò αñòαÑç αñùαñ╡αñ░αÑìαñ¿αñ░ αñöαñ░ αñ«αÑçαñ»αñ░ αñ¿αÑç αñòαÑÇ αñÿαÑïαñ╖αñúαñ╛αÑñ\n26:20\n26 minutes, 20 seconds\nαñ»αÑéαñÅαñ½αñ╛ αñòαÑç αñ¬αÑéαñ░αÑìαñ╡ αñàαñºαÑìαñ»αñòαÑìαñ╖ αñ«αñ╛αñçαñòαñ▓ αñ¬αÑìαñ▓αñ╛αñ¿αÑÇ αñ¿αÑç αñ½αÑìαñ░αñ╛αñéαñ╕ αñ«αÑçαñé αñ½αÑÇαñ½αñ╛ αñöαñ░ αñ£αñ┐αñ»αñ╛αñ¿αÑÇ αñçαñ¿αñ½αÑçαñéαñƒ αñçαñ¿αñ½αÑçαñéαñƒαñ┐αñ¿αÑï αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñ╕αñ┐αñ╡αñ┐αñ▓ αñöαñ░ αñòαÑìαñ░αñ┐αñ«αñ┐αñ¿αñ▓ αñòαÑçαñ╕\n26:29\n26 minutes, 29 seconds\nαñòαñ┐αñÅαÑñ αñ¬αÑìαñ▓αñ╛αñ¿αÑÇ αñòαÑç αñèαñ¬αñ░ 2015 αñ«αÑçαñé αñ▓αñùαñ╛αñÅ αñùαñÅ αñÑαÑç αñ¡αÑìαñ░αñ╖αÑìαñƒαñ╛αñÜαñ╛αñ░ αñòαÑç αñåαñ░αÑïαñ¬αÑñ\n26:36\n26 minutes, 36 seconds\nαñöαñ░ αñçαñ╕αÑÇ αñòαÑç αñ╕αñ╛αñÑ αñ½αñ┐αñ▓αñ╣αñ╛αñ▓ αñÅαñòαÑìαñ╕αñ¬αÑìαñ░αÑçαñ╕ 100 αñ«αÑçαñé αñ«αÑüαñ¥αÑç αñöαñ░ αñ╣αñ«αñ╛αñ░αÑÇ αñ¬αÑéαñ░αÑÇ αñƒαÑÇαñ« αñòαÑï αñªαÑÇαñ£αñ┐αñÅ αñàαñ¿αÑüαñ«αññαñ┐αÑñ αñ¿αñ«αñ╕αÑìαñòαñ╛αñ░αÑñ	f	2026-06-09 13:23:52.856212
34	UCRWFSbif-RFENbBrSiez1DA	National	General	Transcript\nSearch transcript\n0:03\n3 seconds\nαñ«αñºαÑìαñ» αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñùαÑüαñ¿αñ╛ αñöαñªαÑìαñ»αÑïαñùαñ┐αñò αñòαÑìαñ╖αÑçαññαÑìαñ░ αñ«αÑçαñé αñ¬αñ╛αñçαñ¬ αñ½αÑêαñòαÑìαñƒαÑìαñ░αÑÇ αñ«αÑçαñé αñ▓αñùαÑÇ αñ¡αÑÇαñ╖αñú αñåαñùαÑñ Γé╣50 αñ▓αñ╛αñû αñ╕αÑç αñ£αÑìαñ»αñ╛αñªαñ╛ αñòαñ╛ αñ¿αÑüαñòαñ╕αñ╛αñ¿αÑñ αñ╢αÑëαñ░αÑìαñƒ αñ╕αñ░αÑìαñòαñ┐αñƒ αñòαÑÇ αñ╡αñ£αñ╣ αñ╕αÑç αñåαñù αñ▓αñùαñ¿αÑç αñòαÑÇ αñåαñ╢αñéαñòαñ╛αÑñ\n0:14\n14 seconds\nαñ«αñ╣αñ╛αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░ αñòαÑç αñ¬αÑüαñúαÑç αñ«αÑçαñé αñÜαñ╛αñ░ αñªαÑüαñòαñ╛αñ¿αÑçαñéαÑñ αñåαñù αñ«αÑçαñé αñ£αñ▓αñòαñ░ αñ╣αÑüαñê αñûαñ╛αÑñ αñ½αñ╛αñ»αñ░ αñ¼αÑìαñ░αñ┐αñùαÑçαñí αñ¿αÑç αñ«αÑüαñ╢αÑìαñòαñ┐αñ▓ αñ╕αÑç αñ¬αñ╛αñ»αñ╛ αñåαñù αñ¬αñ░ αñòαñ╛αñ¼αÑéαÑñ\n0:26\n26 seconds\nαñ░αñ╛αñ£αñ╕αÑìαñÑαñ╛αñ¿ αñòαÑç αñ¼αÑÇαñòαñ╛αñ¿αÑçαñ░ αñ«αÑçαñé αñëαñáαñ╛ αñ░αÑçαññ αñòαñ╛ αñ¼αñ╡αñéαñíαñ░αÑñ αñòαÑüαñ¢ αñ╣αÑÇ αñªαÑçαñ░ αñ«αÑçαñé αñºαÑéαñ▓ αñ╕αÑç αñ¡αñ░ αñùαñ»αñ╛ αñ¬αÑéαñ░αñ╛ αñ╢αñ╣αñ░αÑñ αñºαÑéαñ▓ αñ¡αñ░αÑÇ αñåαñéαñºαÑÇ αñ╕αÑç αñ£αñ¿αñ£αÑÇαñ╡αñ¿ αñ╣αÑüαñå αñàαñ╕αÑìαññ-αñ╡αÑìαñ»αñ╕αÑìαññαÑñ\n0:35\n35 seconds\nαñ£αñ«αÑìαñ«αÑé αñòαñ╢αÑìαñ«αÑÇαñ░ αñòαÑç αñ¼αñ╛αñ░αñ╛αñ«αÑüαñ▓αñ╛ αñ«αÑçαñé αñ¼αñ╛αñ░αñ┐αñ╢, αññαÑéαñ½αñ╛αñ¿ αñ╕αÑç αññαñ¼αñ╛αñ╣αÑÇαÑñ αñ¼αñ╛αñÿ αñöαñ░ αñûαñíαñ╝αÑÇ αñ½αñ╕αñ▓αÑïαñé αñòαÑï αñ¬αñ╣αÑüαñéαñÜαñ╛ αñ¿αÑüαñòαñ╕αñ╛αñ¿αÑñ αñòαñ┐αñ╕αñ╛αñ¿αÑïαñé αñòαÑÇ αñÜαñ┐αñéαññαñ╛αñÅαñé αñ¼αñóαñ╝αÑÇαÑñ\n0:44\n44 seconds\nαñ╣αÑêαñªαñ░αñ╛αñ¼αñ╛αñª αñ«αÑçαñé αñÅαñéαñƒαÑÇ αñòαñ░αñ¬αÑìαñ╢αñ¿ αñ¼αÑìαñ»αÑéαñ░αÑï αñ¿αÑç αñ£αñ«αÑÇαñ¿ αñöαñ░ αñ╕αñ░αÑìαñ╡αÑç αñ╡αñ┐αñ¡αñ╛αñù αñòαÑç αñàαñºαñ┐αñòαñ╛αñ░αÑÇ αñòαÑç αñáαñ┐αñòαñ╛αñ¿αÑïαñé αñ¬αñ░ αñòαÑÇ αñ¢αñ╛αñ¬αÑçαñ«αñ╛αñ░αÑÇαÑñ αñåαñ» αñ╕αÑç αñàαñºαñ┐αñò αñ╕αñéαñ¬αññαÑìαññαñ┐ αñöαñ░ αñ¡αÑìαñ░αñ╖αÑìαñƒαñ╛αñÜαñ╛αñ░ αñòαÑç αñ«αñ╛αñ«αñ▓αÑïαñé αñ«αÑçαñé αñ▓αñ┐αñ¬αÑìαññ αñ╣αÑïαñ¿αÑç αñòαÑç αñåαñ░αÑïαñ¬αÑñ\n0:56\n56 seconds\nαñëαññαÑìαññαñ░αñ╛αñûαñéαñí αñòαÑç αñÜαñ«αÑïαñ▓αÑÇ αñ«αÑçαñé αñ¿αñ┐αñ╣αñéαñù αñ╕αñ┐αñûαÑïαñé αñ¿αÑç αñ▓αÑïαñùαÑïαñé αñ¬αñ░ αññαñ▓αñ╡αñ╛αñ░ αñ╕αÑç αñòαñ┐αñ»αñ╛ αñ╣αñ«αñ▓αñ╛αÑñ αñ╣αñ«αñ▓αÑç αñ«αÑçαñé αñòαñê αñ▓αÑïαñù αñÿαñ╛αñ»αñ▓αÑñ αñ¬αñ╛αñ░αÑìαñòαñ┐αñéαñù αñòαÑï αñ▓αÑçαñòαñ░ αñ╣αÑüαñå αñÑαñ╛ αñ╡αñ┐αñ╡αñ╛αñªαÑñ\n1:15\n1 minute, 15 seconds\nαñ»αÑéαñ¬αÑÇ αñòαÑç αñòαÑêαñ░αñ╛αñ¿αñ╛ αñ«αÑçαñé αñªαñ¼αñéαñùαÑïαñé αñ¿αÑç αñªαÑï αñ»αÑüαñ╡αñòαÑïαñé αñ╕αÑç αñòαÑÇ αñ«αñ╛αñ░αñ¬αÑÇαñƒαÑñ αñ▓αñ╛αñáαÑÇ αñíαñéαñíαÑïαñé αñöαñ░ αñºαñ╛αñ░αñªαñ╛αñ░ αñ╣αñÑαñ┐αñ»αñ╛αñ░αÑïαñé αñ╕αÑç αñòαñ┐αñ»αñ╛ αñ╣αñ«αñ▓αñ╛αÑñ αñåαñ░αÑïαñ¬αñ┐αñ»αÑïαñé αñòαÑÇ αññαñ▓αñ╛αñ╢ αñòαñ░ αñ░αñ╣αÑÇ αñ╣αÑê αñ¬αÑüαñ▓αñ┐αñ╕αÑñ\n1:26\n1 minute, 26 seconds\nαñùαÑïαñéαñíαñ╛ αñ«αÑçαñé αñ¬αÑüαñ▓αñ┐αñ╕ αñÜαÑîαñòαÑÇ αñ«αÑçαñé αñªαÑï αñ»αÑüαñ╡αñòαÑïαñé αñòαÑÇ αñ¬αñ┐αñƒαñ╛αñê αñòαñ╛ αñ«αñ╛αñ«αñ▓αñ╛αÑñ αñ╡αÑÇαñíαñ┐αñ»αÑï αñ╡αñ╛αñ»αñ░αñ▓ αñ╣αÑïαñ¿αÑç αñ¬αñ░ αñÅαñ╕αñ¬αÑÇ αñ¿αÑç αñòαÑÇ αñòαñ╛αñ░αÑìαñ»αñ╡αñ╛αñ╣αÑÇαÑñ αñªαÑï αñòαñ╛αñéαñ╕αÑìαñƒαÑçαñ¼αñ▓ αñ╕αñ«αÑçαññ αññαÑÇαñ¿ αñ¬αÑüαñ▓αñ┐αñ╕αñòαñ░αÑìαñ«αÑÇ αñ▓αñ╛αñÅ αñ╣αñ╛αñ£αñ┐αñ░αÑñ\n1:37\n1 minute, 37 seconds\nαñ▓αñûαñ¿αñè αñ«αÑçαñé αñ»αÑüαñ╡αññαñ┐αñ»αÑïαñé αñ¿αÑç αñëαñíαñ╝αñ╛αñê αñ»αñ╛αññαñ╛αñ»αñ╛αññ αñ¿αñ┐αñ»αñ«αÑïαñé αñòαÑÇ αñºαñ£αÑìαñ£αñ┐αñ»αñ╛αñéαÑñ αñƒαÑÇαñ▓αÑç αñ╡αñ╛αñ▓αÑÇ αñ«αñ╕αÑìαñ£αñ┐αñª αñòαÑç αñ¬αñ╛αñ╕ αñ»αÑüαñ╡αññαñ┐αñ»αÑïαñé αñòαñ╛ αñ╕αÑìαñƒαñéαñƒαÑñ αñòαñ╛αñ░ αñòαÑÇ αñ╕αñ¿αñ░αÑéαñ½ αñ╕αÑç αñ¼αñ╛αñ╣αñ░ αñ¿αñ┐αñòαñ▓αñòαñ░ αñ╕αñ½αñ░ αñòαñ░αññαÑÇ αñ¿αñ£αñ░ αñåαñê αñ»αÑüαñ╡αññαñ┐αñ»αñ╛αñéαÑñ\n1:49\n1 minute, 49 seconds\nαñªαñ┐αñ▓αÑìαñ▓αÑÇ αñòαÑç αñ«αñªαñ¿αñ¬αÑüαñ░ αñûαñ╛αñªαñ░ αñçαñ▓αñ╛αñòαÑç αñ«αÑçαñé αñàαññαñ┐αñòαÑìαñ░αñ«αñú αñ¬αñ░ αñòαñ╛αñ░αÑìαñ»αñ╡αñ╛αñ╣αÑÇαÑñ αñ»αñ«αÑüαñ¿αñ╛ αñ¿αñªαÑÇ αñòαÑç αñ¬αñ╛αñ╕ αñ╡αñ╛αñ▓αÑç αñçαñ▓αñ╛αñòαÑç αñ«αÑçαñé αñàαññαñ┐αñòαÑìαñ░αñ«αñú αñ¬αñ░ αñ¼αÑüαñ▓αñíαÑïαñ£αñ░ αñÅαñòαÑìαñ╢αñ¿αÑñ\n1:58\n1 minute, 58 seconds\nαñ»αÑéαñ¬αÑÇ αñòαÑÇ αñ╡αñ╛αñ░αñ╛αñúαñ╕αÑÇ αñ«αÑçαñé αñªαñ╛αñ▓ αñ«αñéαñíαÑÇ αñçαñ▓αñ╛αñòαÑç αñ«αÑçαñé αñàαññαñ┐αñòαÑìαñ░αñ«αñú αñ╣αñƒαñ╛αñ¿αÑç αñòαñ╛ αñòαñ╛αñ« αñ£αñ╛αñ░αÑÇαÑñ αñ¼αñ╛αñ£αñ╛αñ░ αñ«αÑçαñé αñàαñ╡αÑêαñº αñ¿αñ┐αñ░αÑìαñ«αñ╛αñú αñòαÑï αñ╣αñƒαñ╛αñ»αñ╛ αñ£αñ╛ αñ░αñ╣αñ╛ αñ╣αÑêαÑñ αñ¡αñ╛αñ░αÑÇ αñ¬αÑüαñ▓αñ┐αñ╕ αñòαÑÇ αñ«αÑîαñ£αÑéαñªαñùαÑÇ αñ«αÑçαñé αñòαñ╛αñ░αñ╡αñ╛αñêαÑñ\n2:09\n2 minutes, 9 seconds\nαñ¿αÑêαñ¿αÑÇαññαñ╛αñ▓ αñ«αÑçαñé αñòαñ╛αñ▓αñ╛ αñóαÑïαñéαñùαÑÇ αñ░αÑïαñí αñ¬αñ░ αñ╣αñ╛αñªαñ╕αñ╛αÑñ\n2:11\n2 minutes, 11 seconds\nαñàαñ¿αñ┐αñ»αñéαññαÑìαñ░αñ┐αññ αñ╣αÑïαñòαñ░ αñ╕αñ░αñ┐αñ»αñ╛ αññαñ╛αñ▓ αñ¥αÑÇαñ▓ αñ«αÑçαñé αñùαñ┐αñ░αÑÇ αñòαñ╛αñ░αÑñ αñòαñ╛αñ░ αñ╕αñ╡αñ╛αñ░ αñ╕αñ¡αÑÇ αñÜαñ╛αñ░ αñ▓αÑïαñù αñ╕αÑüαñ░αñòαÑìαñ╖αñ┐αññαÑñ\n2:19\n2 minutes, 19 seconds\nαñ»αÑéαñ¬αÑÇ αñòαÑç αñòαÑüαñ¢ αñçαñ▓αñ╛αñòαÑïαñé αñ«αÑçαñé αñ¡αÑÇαñ╖αñú αñùαñ░αÑìαñ«αÑÇ αñòαñ╛ αñòαñ╣αñ░αÑñ αñ¬αÑìαñ░αñ»αñ╛αñùαñ░αñ╛αñ£ αñ«αÑçαñé αñùαñ░αÑìαñ«αÑÇ αñòαÑÇ αñ╡αñ£αñ╣ αñ╕αÑç αñ£αñ¿αñ£αÑÇαñ╡αñ¿ αñàαñ╕αÑìαññ-αñ╡αÑìαñ»αñ╕αÑìαññ αñ╣αÑüαñåαÑñ αñ╕αñíαñ╝αñòαÑçαñé αñ╕αÑüαñ¿αÑÇ αñ¬αñíαñ╝αÑÇαÑñ\n2:28\n2 minutes, 28 seconds\nαñ╡αñ╛αñ░αñ╛αñúαñ╕αÑÇ αñ«αÑçαñé αñ¼αñ╛αñ░αñ┐αñ╢ αñòαÑç αñ▓αñ┐αñÅ αñùαñéαñùαñ╛ αñ¿αñªαÑÇ αñ«αÑçαñé αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛ αñ╡αñ┐αñ╢αÑçαñ╖ αñàαñ¿αÑüαñ╖αÑìαñáαñ╛αñ¿αÑñ αñºαñ╛αñ░αÑìαñ«αñ┐αñò αñàαñ¿αÑüαñ╖αÑìαñáαñ╛αñ¿ αñòαÑç αñ╕αñ╛αñÑ αñòαÑÇ αñ╕αñéαñùαÑÇαññ αñ╕αñ╛αñºαñ¿αñ╛αÑñ\n2:37\n2 minutes, 37 seconds\nαñ«αÑçαñ░αñá αñ«αÑçαñé αñÜαñ▓αññαÑÇ αñòαñ╛αñ░ αñ«αÑçαñé αñ▓αñùαÑÇ αñåαñùαÑñ αñòαñ╛αñ░ αñ╕αñ╡αñ╛αñ░ αñ▓αÑïαñùαÑïαñé αñ¿αÑç αñ╕αñ«αñ» αñ░αñ╣αññαÑç αñòαñ╛αñ░ αñ╕αÑç αñ¼αñ╛αñ╣αñ░ αñ¿αñ┐αñòαñ▓αñòαñ░ αñ¼αñÜαñ╛αñê αñ£αñ╛αñ¿αÑñ αñ«αÑïαñªαÑÇαñ¬αÑüαñ░αñ« αñ«αÑçαñé αñ¬αñ▓αÑìαñ▓αñ╡αñ¬αÑüαñ░αñ« αñÑαñ╛αñ¿αñ╛ αñòαÑìαñ╖αÑçαññαÑìαñ░ αñòαÑÇ αñÿαñƒαñ¿αñ╛αÑñ\n2:48\n2 minutes, 48 seconds\nαñ╣αÑêαñªαñ░αñ╛αñ¼αñ╛αñª αñ«αÑçαñé αñçαñ▓αÑçαñòαÑìαñƒαÑìαñ░αñ┐αñò αñ╡αÑìαñ╣αÑÇαñòαñ▓ αñòαÑç αñùαÑïαñªαñ╛αñ« αñ«αÑçαñé αñ▓αñùαÑÇ αñåαñùαÑñ αñ¬αÑéαñ░αÑç αñ¬αñ░αñ┐αñ╕αñ░ αñ«αÑçαñé αñåαñù αñ½αÑêαñ▓αñ¿αÑç αñ╕αÑç αñ«αñÜαñ╛ αñ╣αñíαñ╝αñòαñéαñ¬αÑñ\n2:56\n2 minutes, 56 seconds\nαñªαñ┐αñ▓αÑìαñ▓αÑÇ αñòαÑç αñ╢αñ╛αñ╕αÑìαññαÑìαñ░αÑÇ αñ¿αñùαñ░ αñ«αÑçαñƒαÑìαñ░αÑï αñ╕αÑìαñƒαÑçαñ╢αñ¿ αñòαÑç αñ¬αñ╛αñ╕ αñ▓αñùαÑÇ αñåαñùαÑñ αñ▓αñòαñíαñ╝αÑÇ αñòαÑç αñùαÑïαñªαñ╛αñ« αñ«αÑçαñé αñåαñù αñ╕αÑç αñòαñê αñÿαñ░ αñ¡αÑÇ αñÜαñ¬αÑçαñƒ αñ«αÑçαñé αñåαñÅαÑñ αñ½αñ╛αñ»αñ░ αñ¼αÑìαñ░αñ┐αñùαÑçαñí αñƒαÑÇαñ« αñ¿αÑç αñ¬αñ╛αñ»αñ╛ αñåαñù αñ¬αñ░ αñòαñ╛αñ¼αÑéαÑñ\n3:06\n3 minutes, 6 seconds\nαñ£αñ╛αñ▓αñéαñºαñ░ αñ«αÑçαñé αñíαÑìαñ░αñù αññαñ╕αÑìαñòαñ░αÑÇ αñ╕αÑç αñ£αÑüαñíαñ╝αÑç αñ╡αÑÇαñ░ αñªαñ╛ αñóαñ╛αñ¼αñ╛ αñ¬αñ░ αñÜαñ▓αñ╛ αñ¼αÑüαñ▓αñíαÑïαñ£αñ░αÑñ αñ¿αñùαñ░ αñ¿αñ┐αñùαñ« αñöαñ░ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ╣αñƒαñ╛αñ»αñ╛ αñàαññαñ┐αñòαÑìαñ░αñ«αñúαÑñ αñ¬αÑìαñ░αÑëαñ¬αñ░αÑìαñƒαÑÇ αñ¬αñ░ αñ«αñ╛αñ▓αñ┐αñòαñ╛αñ¿αñ╛ αñ╣αñò αñòαÑï αñ▓αÑçαñòαñ░ αñ╕αñ╛αñ«αñ¿αÑç αñåαñ»αñ╛ αñ╡αñ┐αñ╡αñ╛αñªαÑñ\n3:18\n3 minutes, 18 seconds\nαñ«αÑüαñ░αñ╛αñªαñ╛αñ¼αñ╛αñª αñòαÑç αñ¡αñùαññαñ¬αÑüαñ░ αñòαÑìαñ╖αÑçαññαÑìαñ░ αñ«αÑçαñé αñàαñ╡αÑêαñº αñ«αñ╕αÑìαñ£αñ┐αñª αñ¬αñ░ αñÜαñ▓αñ╛ αñ¼αÑüαñ▓αñíαÑïαñ£αñ░αÑñ αñ¼αÑüαñ▓αñíαÑïαñ£αñ░ αñ╕αÑç αñùαñ┐αñ░αñ╛αñê αñùαñê αñ«αñ╕αÑìαñ£αñ┐αñªαÑñ 300 αñ╡αñ░αÑìαñù αñ«αÑÇαñƒαñ░ αñ╕αñ░αñòαñ╛αñ░αÑÇ αñ£αñ«αÑÇαñ¿ αñ¬αñ░ αñ«αñ╕αÑìαñ£αñ┐αñª αñ¼αñ¿αñ╛αñê αñùαñê αñÑαÑÇαÑñ\n3:29\n3 minutes, 29 seconds\nαñëαññαÑìαññαñ░αñ╛αñûαñéαñí αñòαÑç αñªαÑçαñ╣αñ░αñ╛αñªαÑéαñ¿ αñ«αÑçαñé αñ¼αñ╛αñçαñò αñ«αÑçαñé αñÿαÑüαñ╕αñ╛ αñ£αñ╣αñ░αÑÇαñ▓αñ╛ αñ╕αñ╛αñéαñ¬αÑñ αñòαñíαñ╝αÑÇ αñ«αñ╢αñòαÑìαñòαññ αñòαÑç αñ¼αñ╛αñª αñ╕αñ░αÑìαñ¬αñ«αñ┐αññαÑìαñ░ αñ¿αÑç αñ╕αñ╛αñéαñ¬ αñòαÑï αñ░αÑçαñ╕αÑìαñòαÑìαñ»αÑé αñòαñ┐αñ»αñ╛αÑñ\n3:38\n3 minutes, 38 seconds\nαñ«αÑüαñéαñ¼αñê αñòαÑç αñ¼αÑÇαñòαÑçαñ╕αÑÇ αñçαñ▓αñ╛αñòαÑç αñ«αÑçαñé αñçαñéαñƒαñ░αñ¿αÑçαñƒ αñíαñò αñ╕αÑç αñ╕αñ╛αññ αñàαñ£αñùαñ░ αñòαÑç αñ¼αñÜαÑìαñÜαÑç αñöαñ░ αñÅαñò αñ╕αñ╛αñéαñ¬ αñòαñ╛ αñ░αÑçαñ╕αÑìαñòαÑìαñ»αÑé αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛αÑñ αñ╕αñ░αÑìαñ¬αñ«αñ┐αññαÑìαñ░ αñ¿αÑç αñ╕αñ¡αÑÇ αñ╕αñ╛αñéαñ¬αÑïαñé αñòαÑï αñ¼αñ╛αñ╣αñ░ αñ¿αñ┐αñòαñ╛αñ▓αñ╛αÑñ\n3:50\n3 minutes, 50 seconds\nαñ▓αÑüαñºαñ┐αñ»αñ╛αñ¿αñ╛ αñ«αÑçαñé αñªαñ¼αñéαñùαÑïαñé αñ¿αÑç αñ¼αÑïαñ▓αñ╛ αñÅαñò αñÿαñ░ αñ¬αñ░ αñ╣αñ«αñ▓αñ╛αÑñ αñÿαñ░ αñ¬αñ░ αñ¼αñ░αñ╕αñ╛αñÅ αñêαñƒ αñ¬αññαÑìαñÑαñ░αÑñ αñ¼αñ╛αñ╣αñ░ αñûαñíαñ╝αÑç αñ╡αñ╛αñ╣αñ¿αÑïαñé αñ«αÑçαñé αñ¡αÑÇ αññαÑïαñíαñ╝αñ½αÑïαñíαñ╝αÑñ αñªαÑïαñ¿αÑïαñé αñ╣αÑÇ αñ¬αñòαÑìαñ╖αÑïαñé αñòαÑç αñ¼αÑÇαñÜ αñÜαñ▓αÑÇ αñå αñ░αñ╣αÑÇ αñ¬αÑüαñ░αñ╛αñ¿αÑÇ αñ░αñéαñ£αñ┐αñ╢αÑñ\n4:02\n4 minutes, 2 seconds\nαñùαÑüαñ£αñ░αñ╛αññ αñòαÑç αñ╕αñ╛αñ¼αñ░αñòαñ╛αñáαñ╛ αñ«αÑçαñé αñÿαñ░ αñòαÑç αñ¼αñ╛αñ╣αñ░ αñ¼αÑêαñáαÑç αññαÑÇαñ¿ αñ▓αÑïαñùαÑïαñé αñòαÑï αñòαñ╛αñ░ αñ¿αÑç αñ«αñ╛αñ░αÑÇ αñƒαñòαÑìαñòαñ░αÑñ αñ╣αñ╛αñªαñ╕αÑç αñ«αÑçαñé αññαÑÇαñ¿αÑïαñé αñ╣αÑüαñÅ αñÿαñ╛αñ»αñ▓αÑñ αñòαñê αñ╡αñ╛αñ╣αñ¿ αñ¡αÑÇ αñ╣αÑüαñÅ αñòαÑìαñ╖αññαñ┐αñùαÑìαñ░αñ╕αÑìαññαÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñòαñ╛αñ░ αñÜαñ╛αñ▓αñò αñòαÑï αñ¬αñòαñíαñ╝αñ╛αÑñ\n4:14\n4 minutes, 14 seconds\nαñòαÑïαñ░αÑìαñƒαñª αñòαÑç αñ░αñ╛αñ«αñ░αÑÇ αñùαñ╛αñéαñ╡ αñ«αÑçαñé αñÿαÑüαñ╕αñ╛ αñ╣αñ╛αñÑαÑÇαÑñ\n4:16\n4 minutes, 16 seconds\nαñùαÑìαñ░αñ╛αñ«αÑÇαñúαÑïαñé αñ«αÑçαñé αñ«αñÜαÑÇ αñàαñ½αñ░αñ╛αññαñ½αñ░αÑÇαÑñ αñ╢αÑïαñ░ αñ«αñÜαñ╛αñ¿αÑç αñ¬αñ░ αñ╣αñ╛αñÑαÑÇ αñ£αñéαñùαñ▓ αñòαÑÇ αñôαñ░ αñ¡αñ╛αñùαñ╛αÑñ αñ╡αñ¿ αñ╡αñ┐αñ¡αñ╛αñù αñ╕αÑç αñçαñ▓αñ╛αñòαÑç αñ«αÑçαñé αñùαñ╢αÑìαññ αñ¼αñóαñ╝αñ╛αñ¿αÑç αñòαÑÇ αñ«αñ╛αñéαñùαÑñ\n4:25\n4 minutes, 25 seconds\nαñ¼αñ┐αñ╣αñ╛αñ░ αñòαÑç αñ╕αñ«αñ╕αÑìαññαÑÇαñ¬αÑüαñ░ αñ«αÑçαñé αñ«αñ╣αñ┐αñ▓αñ╛ αñ¬αÑüαñ▓αñ┐αñ╕αñòαñ░αÑìαñ«αñ┐αñ»αÑïαñé αñöαñ░ αñ»αÑüαñ╡αññαñ┐αñ»αÑïαñé αñòαÑç αñ¼αÑÇαñÜ αñ¥αñíαñ╝αñ¬αÑñ\n4:28\n4 minutes, 28 seconds\nαñ£αñ╛αñ¿αñòαñ╛αñ░αÑÇ αñòαÑç αñ«αÑüαññαñ╛αñ¼αñ┐αñò αñòαñ╛αñ░ αñöαñ░ αñ¼αñ╛αñçαñò αñòαÑÇ αñƒαñòαÑìαñòαñ░ αñòαÑç αñ¼αñ╛αñª αñ╢αÑüαñ░αÑé αñ╣αÑüαñå αñ╡αñ┐αñ╡αñ╛αñªαÑñ\n4:35\n4 minutes, 35 seconds\nαñ¼αñ╣αñ░αñ╛αñçαñÜ αñ«αÑçαñé αñ¬αÑçαñƒαÑìαñ░αÑïαñ▓ αñ¬αñéαñ¬ αñ¬αñ░ Γé╣5,000 αñòαÑÇ αñ▓αÑéαñƒαÑñ αñ╕αñ╛αñ«αñ╛αñ¿ αñ▓αÑçαñ¿αÑç αñòαÑç αñ¼αñ╣αñ╛αñ¿αÑç αñåαñÅ αñÑαÑç αñ▓αÑüαñƒαÑçαñ░αÑçαÑñ\n4:40\n4 minutes, 40 seconds\nαñ¬αÑçαñƒαÑìαñ░αÑïαñ▓ αñ¬αñéαñ¬ αñ¬αñ░ αñ▓αñùαÑç αñ╕αÑÇαñ╕αÑÇαñƒαÑÇαñ╡αÑÇ αñòαÑêαñ«αñ░αÑç αñ«αÑçαñé αñ░αñ┐αñòαÑëαñ░αÑìαñí αñ╣αÑüαñê αñ╡αñ╛αñ░αñªαñ╛αññαÑñ\n4:47\n4 minutes, 47 seconds\nαñªαñ┐αñ▓αÑìαñ▓αÑÇ αñòαÑç αñªαñ»αñ╛αñ▓αñ¬αÑüαñ░ αñ«αÑçαñé αñ╣αññαÑìαñ»αñ╛ αñòαñ░αñ¿αÑç αñ╡αñ╛αñ▓αÑç αñ¼αñªαñ«αñ╛αñ╢αÑïαñé αñòαñ╛ αñ╕αÑÇαñ╕αÑÇαñƒαÑÇαñ╡αÑÇ αñ½αÑüαñƒαÑçαñ£ αñåαñ»αñ╛ αñ╕αñ╛αñ«αñ¿αÑçαÑñ\n4:51\n4 minutes, 51 seconds\nαñ¼αñªαñ«αñ╛αñ╢ αñòαÑç αñ╣αñ╛αñÑ αñ«αÑçαñé αñ¬αñ┐αñÜαñ▓αñ╛ αñ░αñ╣αÑÇ αñ¿αñ£αñ░αÑñ αñ¡αñ╛αñùαññαÑç αñ╣αÑüαñÅ αñ╕αÑìαñòαÑéαñƒαÑÇ αñ╕αñ╡αñ╛αñ░ αñ¼αñªαñ«αñ╛αñ╢ αñ╣αÑüαñÅ αñ½αñ░αñ╛αñ░αÑñ\n4:59\n4 minutes, 59 seconds\nαñ╕αÑéαñ░αññ αñ«αÑçαñé αñ╕αÑìαñòαÑéαñ▓ αñòαÑç αñùαÑçαñƒ αñ¬αñ░ αñòαÑìαñ▓αñ╛αñ╕ αñ╕αñ┐αñòαÑìαñ╕ αñòαÑç αñ¢αñ╛αññαÑìαñ░ αñ¬αñ░ αñÜαñ╛αñòαÑé αñ╕αÑç αñ╣αñ«αñ▓αñ╛αÑñ αñ¬αñ░αñ┐αñ╡αñ╛αñ░ αñ╡αñ╛αñ▓αÑïαñé αñ¿αÑç αñ¼αññαñ╛αñ»αñ╛ αñ¢αñ╛αññαÑìαñ░αÑïαñé αñòαÑç αñ¼αÑÇαñÜ αñòαÑüαñ¢ αñªαñ┐αñ¿ αñ¬αñ╣αñ▓αÑç αñ╣αÑüαñå αñÑαñ╛ αñ╡αñ┐αñ╡αñ╛αñªαÑñ\n5:10\n5 minutes, 10 seconds\nαñ╣αÑêαñªαñ░αñ╛αñ¼αñ╛αñª αñ«αÑçαñé αñ╢αñ╛αññαñ┐αñ░ αñÜαÑïαñ░ αñ¿αÑç αñæαñƒαÑï αñ╕αÑç αñíαÑìαñ░αñ╛αñçαñ╡αñ░ αñòαñ╛ αñ«αÑïαñ¼αñ╛αñçαñ▓ αñòαñ┐αñ»αñ╛ αñÜαÑïαñ░αÑÇαÑñ αñ¡αÑÇαñíαñ╝αñ¡αñ╛αñíαñ╝ αñ╡αñ╛αñ▓αÑç αñçαñ▓αñ╛αñòαÑç αñ«αÑçαñé αñ╡αñ╛αñ░αñªαñ╛αññ αñòαÑï αñªαñ┐αñ»αñ╛ αñàαñéαñ£αñ╛αñ«αÑñ\n5:20\n5 minutes, 20 seconds\nαñ«αñ╣αñ╛αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░ αñòαÑç αñ¬αÑüαñúαÑç αñ«αÑçαñé αñ¼αñ╛αñçαñò αñòαÑÇ αñíαñ┐αñùαÑìαñòαÑÇ αñ╕αÑç αñòαÑêαñ╢ αñÜαÑïαñ░αÑÇαÑñ αñÜαÑïαñ░αÑÇ αñòαñ╛ αñ╕αÑÇαñ╕αÑÇαñƒαÑÇαñ╡αÑÇ αñ½αÑüαñƒαÑçαñ£ αñ¡αÑÇ αñåαñ»αñ╛ αñ╕αñ╛αñ«αñ¿αÑçαÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αññαÑÇαñ¿ αñ▓αÑïαñùαÑïαñé αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñªαñ░αÑìαñ£ αñòαñ┐αñ»αñ╛ αñòαÑçαñ╕αÑñ\n5:31\n5 minutes, 31 seconds\nαñ»αÑéαñ¬αÑÇ αñòαÑç αñ╣αñ«αÑÇαñ░αñ¬αÑüαñ░ αñ«αÑçαñé αñ¬αññαÑìαñ¿αÑÇ αñòαÑï αñ¬αñ╛αñ░αÑìαñ▓αñ░ αñ£αñ╛αñ¿αÑç αñ╕αÑç αñ░αÑïαñòαñ¿αñ╛, αñ¬αññαñ┐ αñòαÑï αñ¬αñíαñ╝αñ╛ αñ¡αñ╛αñ░αÑÇαÑñ αñ¬αññαÑìαñ¿αÑÇ αñòαÑç αñ¬αñ░αñ┐αñ╡αñ╛αñ░ αñ╡αñ╛αñ▓αÑïαñé αñ¿αÑç αñòαñ┐αñ»αñ╛ αñ¬αññαñ┐ αñ¬αñ░ αñ╣αñ«αñ▓αñ╛αÑñ\n5:38\n5 minutes, 38 seconds\nαñ¼αÑÇαñÜ-αñ¼αñÜαñ╛αñ╡ αñòαñ░αñ¿αÑç αñåαñÅ αñ¬αñíαñ╝αÑïαñ╕αñ┐αñ»αÑïαñé αñòαÑç αñ╕αñ╛αñÑ αñ╣αÑüαñê αñ«αñ╛αñ░αñ¬αÑÇαñƒαÑñ\n5:44\n5 minutes, 44 seconds\nαñ«αñ╣αñ╛αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░ αñòαÑç αñ¡αñ┐αñ╡αñéαñíαÑÇ αñ«αÑçαñé αñûαÑüαñ▓αÑç αñ╕αÑçαñ½αÑìαñƒαÑÇ αñƒαÑêαñéαñò αñ«αÑçαñé αñùαñ┐αñ░αñ¿αÑç αñ╕αÑç 5 αñ╕αñ╛αñ▓ αñòαÑç αñ«αñ╛αñ╕αÑéαñ« αñòαÑÇ αñ«αÑîαññαÑñ αñÿαñƒαñ¿αñ╛ αñ╕αÑÇαñ╕αÑÇαñƒαÑÇαñ╡αÑÇ αñòαÑêαñ«αñ░αÑç αñ«αÑçαñé αñ░αñ┐αñòαÑëαñ░αÑìαñí αñ╣αÑüαñêαÑñ\n5:50\n5 minutes, 50 seconds\nαñçαñ▓αñ╛αñòαÑç αñ«αÑçαñé αñ«αñ╛αñ╕αÑéαñ« αñòαÑÇ αñ«αÑîαññ αñ╕αÑç αñ«αñ╛αññαñ«αÑñ\n5:55\n5 minutes, 55 seconds\nαñ¼αñ┐αñ╣αñ╛αñ░ αñòαÑç αñ¬αñ╢αÑìαñÜαñ┐αñ« αñÜαñéαñ¬αñ╛αñ░αñú αñ«αÑçαñé αñ╕αñíαñ╝αñò, αñ¼αñ┐αñ£αñ▓αÑÇ αñöαñ░ αñ╕αÑìαñ╡αñ╛αñ╕αÑìαñÑαÑìαñ» αñ╕αÑüαñ╡αñ┐αñºαñ╛αñôαñé αñòαñ╛ αñ╕αñéαñòαñƒαÑñ αñ£αñ╛αñ¿ αñ£αÑïαñûαñ┐αñ« αñ«αÑçαñé αñíαñ╛αñ▓αñòαñ░ αñ¼αÑçαñƒαÑç αñ¿αñªαÑÇ αñòαÑï αñ¬αñ╛αñ░ αñòαñ░ αñ░αñ╣αÑç αñ╣αÑêαñé αñ╡αñ╛αñ╣αñ¿αÑñ αñçαñ▓αñ╛αñòαÑç αñòαÑç 22 αñùαñ╛αñéαñ╡ αñ╡αñ┐αñòαñ╛αñ╕ αñòαÑÇ αñ«αÑüαñûαÑìαñ»αñºαñ╛αñ░αñ╛ αñ╕αÑç αñòαñƒαÑçαÑñ\n6:08\n6 minutes, 8 seconds\nαñ▓αñûαñ¿αñè αñ«αÑçαñé αñ½αñ░αÑìαñ£αÑÇ αñåαñêαñ¬αÑÇαñÅαñ╕ αñ¼αñ¿αñòαñ░ αñ░αñ¼ αñ¥αñ╛αñíαñ╝ αñ░αñ╣αñ╛ αñÑαñ╛ αñ»αÑüαñ╡αñòαÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñòαñ┐αñ»αñ╛ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░αÑñ αñ¬αÑüαñ▓αñ┐αñ╕αñòαñ░αÑìαñ«αñ┐αñ»αÑïαñé αñ¬αñ░ αñ░αñ¼ αñ¥αñ╛αñíαñ╝αññαñ╛ αñÑαñ╛ αñåαñ░αÑïαñ¬αÑÇαÑñ\n6:14\n6 minutes, 14 seconds\nαñ╕αÑêαñ▓αÑìαñ»αÑéαñƒ αñ¿αñ╛ αñòαñ░αñ¿αÑç αñ¬αñ░ αñ¿αñ┐αñ▓αñéαñ¼αñ┐αññ αñòαñ░αñ¿αÑç αñòαÑÇ αñºαñ«αñòαÑÇ αñªαÑçαññαñ╛ αñÑαñ╛αÑñ\n6:22\n6 minutes, 22 seconds\nαñ»αÑéαñ¬αÑÇ αñòαÑç αñ«αñÑαÑüαñ░αñ╛ αñ«αÑçαñé αñªαñ¼αñ┐αñ╢ αñªαÑçαñ¿αÑç αñ¬αñ╣αÑüαñéαñÜαÑÇ αñ¬αÑüαñ▓αñ┐αñ╕ αñƒαÑÇαñ« αñ¿αÑç αñÿαñ░ αñ«αÑçαñé αñòαÑÇ αññαÑïαñíαñ╝αñ½αÑïαÑñ αñÿαñ░ αñòαÑç αñ¼αñ╛αñ╣αñ░ αñ▓αñùαÑç αñ╕αÑÇαñ╕αÑÇαñƒαÑÇαñ╡αÑÇ αñòαÑï αñ¡αÑÇ αññαÑïαñíαñ╝αñ╛αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñòαÑÇ αñòαñ╛αñ░αÑìαñ»αñ╢αÑêαñ▓αÑÇ αñ¬αñ░ αñûαñíαñ╝αÑç αñ╣αÑï αñ░αñ╣αÑç αñ╕αñ╡αñ╛αñ▓αÑñ\n6:33\n6 minutes, 33 seconds\nαñÅαñ«αñ¬αÑÇ αñòαÑç αñ£αñ¼αñ▓αñ¬αÑüαñ░ αñ«αÑçαñé αñ╕αÑìαñƒαÑçαñ╢αñ¿ αñòαÑç αñ▓αñ┐αñ½αÑìαñƒ αñ«αÑçαñé αñ½αñéαñ╕αÑç αñ»αñ╛αññαÑìαñ░αÑÇαÑñ αñ▓αñ┐αñ½αÑìαñƒ αñ«αÑêαñòαÑçαñ¿αñ┐αñò αñòαÑÇ αñòαñíαñ╝αÑÇ αñ«αñ╢αñòαÑìαñòαññ αñòαÑç αñ¼αñ╛αñª αñ»αñ╛αññαÑìαñ░αñ┐αñ»αÑïαñé αñòαÑï αñ╕αÑüαñ░αñòαÑìαñ╖αñ┐αññ αñ¼αñ╛αñ╣αñ░ αñ¿αñ┐αñòαñ╛αñ▓αñ╛ αñùαñ»αñ╛αÑñ\n6:44\n6 minutes, 44 seconds\nαñ«αñ╣αñ╛αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░ αñòαÑç αñ¬αñ╛αñ▓αñÿαñ░ αñ«αÑçαñé αñÅαñò αñÿαñéαñƒαÑç αñ╕αÑç αñ£αÑìαñ»αñ╛αñªαñ╛ αñ▓αñ┐αñ½αÑìαñƒ αñ«αÑçαñé αñ½αñéαñ╕αÑÇ αñ░αñ╣αÑÇ αñ«αñ╣αñ┐αñ▓αñ╛αÑñ αñ½αñ╛αñ»αñ░ αñ¼αÑìαñ░αñ┐αñùαÑçαñí αñòαÑÇ αñƒαÑÇαñ« αñ¿αÑç αñ¿αñ┐αñòαñ╛αñ▓αñ╛ αñ«αñ╣αñ┐αñ▓αñ╛ αñòαÑï αñ╕αÑüαñ░αñòαÑìαñ╖αñ┐αññ αñ¼αñ╛αñ╣αñ░αÑñ αñ¼αñ┐αñ£αñ▓αÑÇ αñòαñƒαñ¿αÑç αñòαÑÇ αñ╡αñ£αñ╣ αñ╕αÑç αñ╣αÑüαñå αñ╣αñ╛αñªαñ╕αñ╛αÑñ\n6:55\n6 minutes, 55 seconds\nαñ»αÑéαñ¬αÑÇ αñòαÑç αñ«αñÑαÑüαñ░αñ╛ αñ«αÑçαñé αñûαñ╛αñªαÑìαñ» αñ╡αñ┐αñ¡αñ╛αñù αñòαÑÇ αñ¼αñíαñ╝αÑÇ αñòαñ╛αñ░αÑìαñ»αñ╡αñ╛αñ╣αÑÇαÑñ αñ«αñéαñªαñ┐αñ░αÑïαñé αñòαÑç αñåαñ╕αñ¬αñ╛αñ╕ αñ¼αñ┐αñòαñ¿αÑç αñ╡αñ╛αñ▓αÑç αñûαñ╛αñªαÑìαñ» αñ¬αñªαñ╛αñ░αÑìαñÑαÑïαñé αñòαñ╛ αñ▓αñ┐αñ»αñ╛ αñ╕αÑêαñéαñ¬αñ▓αÑñ 50 αñòαñ┐αñ▓αÑï αñ¿αñòαñ▓αÑÇ αñ¬αÑçαñíαñ╝αÑç αñöαñ░ 600 αñòαñ┐αñ▓αÑï αñ¿αñòαñ▓αÑÇ αñàαñÜαñ╛αñ░ αñòαñ┐αñ»αñ╛ αñ¿αñ╖αÑìαñƒαÑñ\n7:08\n7 minutes, 8 seconds\nαñ¢αññαÑìαññαÑÇαñ╕αñùαñóαñ╝ αñòαÑç αñòαÑïαñ░αñ┐αñ»αñ╛ αñ«αÑçαñé αñÜαñ╛αñ░ αñ▓αÑïαñùαÑïαñé αñòαÑï αñòαñ╛αñ░ αñ«αÑçαñé αñ¼αñéαñª αñòαñ░ αñ▓αñùαñ╛ αñªαñ┐αñ»αñ╛αÑñ αñÅαñò αñòαÑÇ αñ«αÑîαññ, αññαÑÇαñ¿ αñÿαñ╛αñ»αñ▓αÑñ αñÜαñ╛αñ░ αñåαñ░αÑïαñ¬αÑÇ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░αÑñ αñ£αñ▓αññαÑÇ αñòαñ╛αñ░ αñ╕αÑç\n7:15\n7 minutes, 15 seconds\nαñ¿αñ┐αñòαñ▓αñ¿αÑç αñòαÑÇ αñòαÑïαñ╢αñ┐αñ╢ αñòαÑç αñªαÑîαñ░αñ╛αñ¿ αñ¡αÑÇ αñåαñ░αÑïαñ¬αñ┐αñ»αÑïαñé αñ¿αÑç αñòαñ┐αñ»αñ╛ αñÑαñ╛ αñ╣αñ«αñ▓αñ╛αÑñ\n7:20\n7 minutes, 20 seconds\nαñàαñéαñ¼αñ╛αñ▓αñ╛ αñòαÑÇ αñ¬αÑüαñ░αñ╛αñ¿αÑÇ αñ╕αñ¼αÑìαñ£αÑÇ αñ«αñéαñíαÑÇ αñ«αÑçαñé αñùαñ┐αñ░αñ╛ αñçαñ«αñ╛αñ░αññ αñòαñ╛ αñ¢αñ£αÑìαñ£αñ╛αÑñ αñ╕αÑéαñÜαñ¿αñ╛ αñòαÑç αñ¼αñ╛αñª αñ«αÑîαñòαÑç αñ¬αñ░ αñ¬αñ╣αÑüαñéαñÜαñ╛ αñ¬αÑìαñ░αñ╢αñ╛αñ╕αñ¿αÑñ αñ«αñ▓αñ¼αÑç αñ«αÑçαñé αñªαñ¼αÑç αñªαÑï αñ▓αÑïαñùαÑïαñé αñòαÑï\n7:28\n7 minutes, 28 seconds\nαñ¿αñ┐αñòαñ╛αñ▓αñ╛ αñùαñ»αñ╛αÑñ αñòαñ╛αñ½αÑÇ αñ╕αñ«αñ» αñ╕αÑç αñ£αñ£αñ░ αñ╣αñ╛αñ▓αññ αñ«αÑçαñé αñÑαÑÇ αñçαñ«αñ╛αñ░αññαÑñ\n7:33\n7 minutes, 33 seconds\nαñùαÑïαñ░αñûαñ¬αÑüαñ░ αñ«αÑçαñé αñ░αñ╛αÑìαññαÑÇ αñ¿αñªαÑÇ αñ«αÑçαñé αñ¿αñ╣αñ╛αñ¿αÑç αñùαñÅ αñªαÑï αñ¼αñÜαÑìαñÜαÑç αñíαÑéαñ¼αÑçαÑñ αñ¬αñ╛αñ¿αÑÇ αñ«αÑçαñé αñíαÑéαñ¼αñ¿αÑç αñ╕αÑç αñÅαñò αñ¼αñÜαÑìαñÜαÑç αñòαÑÇ αñ╣αÑüαñê αñ«αÑîαññαÑñ αñ¼αñÜαÑìαñÜαÑÇ αñòαÑÇ αññαñ▓αñ╛αñ╢ αñòαÑç αñ▓αñ┐αñÅ αñ╕αñ░αÑìαñÜ αñæαñ¬αñ░αÑçαñ╢αñ¿αÑñ αñÿαñƒαñ¿αñ╛ αñòαÑç αñ¼αñ╛αñª αñ¬αñ░αñ┐αñ£αñ¿αÑïαñé αñ«αÑçαñé αñòαÑïαñ╣αñ░αñ╛αÑñ\n7:44\n7 minutes, 44 seconds\nαñàαñ▓αÑìαñ«αÑïαñíαñ╝αñ╛ αñ«αÑçαñé αñûαñ╛αñê αñ«αÑçαñé αñùαñ┐αñ░αÑÇ αñ¼αÑüαñ▓αÑçαñ░αÑï αñùαñ╛αñíαñ╝αÑÇαÑñ αñ╣αñ╛αñªαñ╕αÑç αñ«αÑçαñé αñÜαñ╛αñ░ αñ¼αñÜαÑìαñÜαÑïαñé αñ╕αñ«αÑçαññ 11 αñ▓αÑïαñù αñÿαñ╛αñ»αñ▓αÑñ αññαÑÇαñ¿ αñÿαñ╛αñ»αñ▓αÑïαñé αñòαÑï αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛ αñ╣αñ╛αñ»αñ░ αñ╕αÑçαñéαñƒαñ░ αñ░αÑçαñ½αñ░αÑñ\n7:50\n7 minutes, 50 seconds\nαñ£αñ╛αñùαÑçαñ╢αÑìαñ╡αñ░ αñ«αñéαñªαñ┐αñ░ αñªαñ░αÑìαñ╢αñ¿ αñòαÑç αñ▓αñ┐αñÅ αñ£αñ╛ αñ░αñ╣αÑç αñÑαÑç αñòαñ╛αñ░ αñ╕αñ╡αñ╛αñ░αÑñ\n7:56\n7 minutes, 56 seconds\nαñ▓αñûαñ¿αñè αñ«αÑçαñé αñûαñ¿αñ¿ αñ«αñ╛αñ½αñ┐αñ»αñ╛ αñòαÑç αñ¼αÑÇαñÜ αñ½αñ╛αñ»αñ░αñ┐αñéαñù αñ¬αÑüαñ░αñ╛αñ¿αÑÇ αñ░αñéαñ£αñ┐αñ╢ αñòαÑï αñ▓αÑçαñòαñ░ αñ½αñ╛αñ»αñ░αñ┐αñéαñù αñ╕αÑüαñ╢αñ╛αñéαññ αñùαÑïαñ▓ αñ╕αñ┐αñƒαÑÇ αñÑαñ╛αñ¿αñ╛ αñòαÑìαñ╖αÑçαññαÑìαñ░ αñ«αÑçαñé αñ╕αÑçαñ╡αñê αñƒαÑëαñòαÑÇ αñòαñ╛ αñ«αñ╛αñ«αñ▓αñ╛ αñ¢αñ╛αñ¿αñ¼αÑÇαñ¿ αñòαñ░ αñ░αñ╣αÑÇ αñ╣αÑê αñ¬αÑüαñ▓αñ┐αñ╕\n8:07\n8 minutes, 7 seconds\nαñ«αÑçαñ░αñá αñ«αÑçαñé αñ╕αñ░αñòαñ╛αñ░ αñòαÑï αñòαñ░αÑïαñíαñ╝αÑïαñé αñòαñ╛ αñÜαÑéαñ¿αñ╛ αñ▓αñùαñ╛αñ¿αÑç αñ╡αñ╛αñ▓αÑç αñ½αñ░αÑìαñ£αÑÇ αñ░αÑëαñ»αñ▓αÑìαñƒαÑÇ αñùαÑêαñéαñù αñòαñ╛ αñ¬αñ░αÑìαñªαñ╛αñ½αñ╛αñ╢ αñÅαñ╕αñƒαÑÇαñÅαñ½ αñ¿αÑç αñÜαñ╛αñ░ αñåαñ░αÑïαñ¬αñ┐αñ»αÑïαñé αñòαÑï αñòαñ┐αñ»αñ╛ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░\n8:13\n8 minutes, 13 seconds\nαñûαñ¿αñ¿ αñªαñ╕αÑìαññαñ╛αñ╡αÑçαñ£αÑïαñé αñ«αÑçαñé αñ╣αÑçαñ░αñ╛αñ½αÑçαñ░αÑÇ αñòαñ╛ αñåαñ░αÑïαñ¬ αñ«αñ╣αñ╛αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░ αñòαÑç αñ¿αñ╛αñùαñ¬αÑüαñ░ αñ«αÑçαñé αñ¬αñ╛αñ¿αÑÇ αñòαÑç αñ¢αÑÇαñéαñƒαÑç\n8:21\n8 minutes, 21 seconds\nαñ¬αñíαñ╝αñ¿αÑç αñòαÑç αñ╡αñ┐αñ╡αñ╛αñª αñ«αÑçαñé αñÜαñ╛αñòαÑé αññαñ╛αñ¼αñíαñ╝αññαÑïαñíαñ╝ αñ½αñ╛αñíαñ╝αñòαñ░ αñ»αÑüαñ╡αñò αñòαÑÇ αñ╣αññαÑìαñ»αñ╛ αñ«αñ╛αñ« αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ╕αñ╛αññ αñåαñ░αÑïαñ¬αñ┐αñ»αÑïαñé αñòαÑï αñòαñ┐αñ»αñ╛ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░αÑñ\n8:30\n8 minutes, 30 seconds\nαñ«αñ╕αÑéαñ░αÑÇ αñòαÑç αñºαñ¿αÑîαñƒαÑÇ αñ«αÑçαñé αñ╣αÑïαñ« αñ╕αÑìαñƒαÑç αñ«αÑçαñé αñ«αñ┐αñ▓αñ╛ αñ«αñ╣αñ┐αñ▓αñ╛ αñòαñ╛ αñ╢αñ╡αÑñ αñ╕αÑëαñ½αÑìαñƒαñ╡αÑçαñ»αñ░ αñçαñéαñ£αÑÇαñ¿αñ┐αñ»αñ░ αñòαÑÇ αñ╕αñéαñªαñ┐αñùαÑìαñº αñ╣αñ╛αñ▓αññ αñ«αÑçαñé αñ«αÑîαññαÑñ αñ¬αñ░αñ┐αñ╡αñ╛αñ░ αñ╡αñ╛αñ▓αÑïαñé αñ¿αÑç αñòαÑÇ αñ¿αñ┐αñ╖αÑìαñ¬αñòαÑìαñ╖ αñ£αñ╛αñéαñÜ αñòαÑÇ αñ«αñ╛αñéαñùαÑñ αñ«αñ╛αñ«αñ▓αÑç αñòαÑÇ αñ£αñ╛αñéαñÜ αñòαñ░ αñ░αñ╣αÑÇ αñ╣αÑê αñ¬αÑüαñ▓αñ┐αñ╕αÑñ\n8:43\n8 minutes, 43 seconds\nαñùαñ╛αñ£αñ┐αñ»αñ╛αñ¼αñ╛αñª αñòαÑç αñûαÑïαñíαñ╝αñ╛ αñ«αÑçαñé αñªαÑï αñ╕αñùαÑÇ αñ¼αñ╣αñ¿αÑïαñé αñòαÑï αñùαÑïαñ▓αÑÇ αñ«αñ╛αñ░αñ¿αÑç αñòαñ╛ αñ«αñ╛αñ«αñ▓αñ╛αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ£αÑëαñ¿αÑÇ αñ¿αñ╛αñ« αñòαÑç αñåαñ░αÑïαñ¬αÑÇ αñòαÑï αñòαñ┐αñ»αñ╛ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░αÑñ αñ╢αñ╛αñªαÑÇ αñòαñ╛ αñ░αñ┐αñ╢αÑìαññαñ╛ αñƒαÑéαñƒαñ¿αÑç αñòαÑÇ αñ╡αñ£αñ╣ αñ╕αÑç αñ¿αñ╛αñ░αñ╛αñ£ αñÑαñ╛ αñ»αÑüαñ╡αñòαÑñ\n8:55\n8 minutes, 55 seconds\nαñ£αñ»αñ¬αÑüαñ░ αñ«αÑçαñé αñàαñ╡αÑêαñº αñ╕αñéαñ¼αñéαñº αñòαÑç αñ╢αñò αñ«αÑçαñé αñ¬αñíαñ╝αÑïαñ╕αñ¿ αñ¼αñ¿αÑÇ αñ╣αÑêαñ╡αñ╛αñ¿αÑñ 5 αñ╕αñ╛αñ▓ αñòαÑÇ αñ«αñ╛αñ╕αÑéαñ« αñòαÑï αñëαññαñ╛αñ░αñ╛ αñ«αÑîαññ αñòαÑç αñÿαñ╛αñƒαÑñ αñåαñ░αÑïαñ¬αÑÇ αñ«αñ╣αñ┐αñ▓αñ╛ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░αÑñ\n9:06\n9 minutes, 6 seconds\nαñ¼αÑçαñéαñùαñ▓αÑüαñ░αÑü αñ«αÑçαñé 22 αñ╕αñ╛αñ▓ αñòαÑÇ αñ»αÑüαñ╡αññαÑÇ αñòαÑÇ αñ«αÑîαññ αñòαñ╛ αñûαÑüαñ▓αñ╛αñ╕αñ╛αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñòαÑçαñ╡αÑÇ αñÜαñéαñªαñ¿ αñòαÑï αñòαñ┐αñ»αñ╛ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░αÑñ αñªαÑïαñ¿αÑïαñé αñ¿αÑç αñ¬αñ░αñ┐αñ╡αñ╛αñ░ αñòαÑï αñ¼αñ┐αñ¿αñ╛ αñ¼αññαñ╛αñÅ αñòαñ░ αñ▓αÑÇ αñÑαÑÇ αñ╢αñ╛αñªαÑÇαÑñ\n9:17\n9 minutes, 17 seconds\nαñòαñ░αÑìαñ¿αñ╛αñƒαñò αñòαÑç αñ¼αÑçαñ▓αñùαñ╛αñ╡αÑÇ αñ«αÑçαñé αñ░αñ┐αñ╢αÑìαññαÑç αñ╣αÑüαñÅ αñ╢αñ░αÑìαñ«αñ╕αñ╛αñ░αÑñ 2 αñòαñ░αÑïαñíαñ╝ αñòαÑç αñçαñéαñ╢αÑìαñ»αÑïαñ░αÑçαñéαñ╕ αñòαÑìαñ▓αÑçαñ« αñòαÑç αñ▓αñ┐αñÅ αñ¬αÑéαñ░αÑìαñ╡ αñ╕αÑêαñ¿αñ┐αñò αñòαÑÇ αñ╣αññαÑìαñ»αñ╛αÑñ αñ¬αññαÑìαñ¿αÑÇ αñ╕αñ«αÑçαññ αñ¿αÑî αñ▓αÑïαñù αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░αÑñ\n9:27\n9 minutes, 27 seconds\nαñ«αñ╣αñ╛αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░ αñòαÑç αñ¿αñ╛αñùαñ¬αÑüαñ░ αñ«αÑçαñé αñ░αÑçαñ¬ αñ¼αÑìαñ▓αÑêαñòαñ«αÑçαñ▓ αñöαñ░ αñ£αñ¼αñ░αñªαñ╕αÑìαññαÑÇ αñºαñ¿ αñ¼αñªαñ▓αñ¿αÑç αñòαñ╛ αñòαÑçαñ╕ αñªαñ░αÑìαñ£αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñªαÑï αñòαÑï αñòαñ┐αñ»αñ╛ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░αÑñ αñÅαñò αñòαÑÇ αññαñ▓αñ╛αñ╢ αñ£αñ╛αñ░αÑÇαÑñ\n9:38\n9 minutes, 38 seconds\nαñ«αñ╣αñ╛αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░ αñòαÑç αñ¬αÑüαñúαÑç αñ«αÑçαñé αñ¬αÑìαñ░αÑçαñ«αÑÇ αñ¿αÑç αñ»αÑüαñ╡αññαÑÇ αñòαÑï αñ¿αñªαÑÇ αñ«αÑçαñé αñ½αÑçαñéαñòαñ╛αÑñ αñûαÑüαñª αñ¡αÑÇ αñ¿αñªαÑÇ αñ«αÑçαñé αñòαÑéαñªαñ╛αñ»αñ╛ αñ¬αÑìαñ░αÑçαñ«αÑÇαÑñ αñ»αÑüαñ╡αññαÑÇ αñòαÑÇ αñíαÑéαñ¼ αñòαñ░ αñ«αÑîαññαÑñ αñ¬αÑìαñ░αÑçαñ«αÑÇ αñ¿αÑç αññαÑêαñ░ αñòαñ░ αñ¼αñÜαñ╛ αñ▓αÑÇ αñ£αñ╛αñ¿αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñòαñ░ αñ░αñ╣αÑÇ αñ╣αÑê αñ«αñ╛αñ«αñ▓αÑç αñòαÑÇ αñ£αñ╛αñéαñÜαÑñ\n9:49\n9 minutes, 49 seconds\nαñ»αÑéαñ¬αÑÇ αñòαÑç αñ¬αÑìαñ░αñ»αñ╛αñùαñ░αñ╛αñ£ αñ«αÑçαñé αññαÑÇαñ¿ αñ▓αÑïαñùαÑïαñé αñòαÑÇ αñ╣αññαÑìαñ»αñ╛ αñ╕αÑç αñ╕αñ¿αñ╕αñ¿αÑÇαÑñ αñÅαñò αñ╣αÑÇ αñ¬αñ░αñ┐αñ╡αñ╛αñ░ αñ«αÑçαñé αññαÑÇαñ¿ αñ▓αÑïαñùαÑïαñé αñòαñ╛ αñòαññαÑìαñ▓αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñòαñ░ αñ░αñ╣αÑÇ αñ╣αÑê αñ£αñ╛αñéαñÜαÑñ\n10:00\n10 minutes\nαñ»αÑéαñ¬αÑÇ αñòαÑç αñ¼αñíαñ╝αÑîαññ αñ«αÑçαñé αñƒαÑçαñéαñƒ αñòαñ╛αñ░αÑïαñ¼αñ╛αñ░αñ┐αñ»αÑïαñé αñöαñ░ αñëαñ¿αñòαÑç αñ¼αÑçαñƒαÑç αñòαÑÇ αñ╣αññαÑìαñ»αñ╛ αñòαñ╛ αñ«αñ╛αñ«αñ▓αñ╛αÑñ αñ╣αññαÑìαñ»αñ╛αñòαñ╛αñéαñí αñ«αÑçαñé αñ╢αñ╛αñ«αñ┐αñ▓ αñåαñ░αÑïαñ¬αÑÇ αñòαÑç αñ╕αñ╛αñÑ αñ¬αÑüαñ▓αñ┐αñ╕ αñòαÑÇ αñ«αÑüαñáαñ¡αÑçαñíαñ╝αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñòαÑÇ αñùαÑïαñ▓αÑÇ αñ╕αÑç αñÿαñ╛αñ»αñ▓ αñ╣αÑüαñå αñ¼αñªαñ«αñ╛αñ╢αÑñ\n10:12\n10 minutes, 12 seconds\nαñ¼αñªαñ╛αñ»αÑéαñé αñ«αÑçαñé αñ¬αññαÑìαñ¿αÑÇ αñòαÑç αñ░αÑÇαñ▓αÑìαñ╕ αñ¼αñ¿αñ╛αñ¿αÑç αñ╕αÑç αñ¬αñ░αÑçαñ╢αñ╛αñ¿αÑñ αñ¬αññαñ┐ αñ¿αÑç αñ½αñ╛αñéαñ╕αÑÇ αñ▓αñùαñ╛αñòαñ░ αñªαÑÇ αñ£αñ╛αñ¿αÑñ\n10:16\n10 minutes, 16 seconds\nαñ¬αñ░αñ┐αñ╡αñ╛αñ░ αñ╡αñ╛αñ▓αÑïαñé αñòαñ╛ αñåαñ░αÑïαñ¬ αñ¬αññαÑìαñ¿αÑÇ αñòαÑç αñ╕αñ╛αñÑ αñ╡αñ┐αñ╡αñ╛αñª αñòαÑç αñ¼αñ╛αñª αñëαñáαñ╛αñ»αñ╛ αñûαññαñ░αñ¿αñ╛αñò αñòαñªαñ«αÑñ\n10:24\n10 minutes, 24 seconds\nαñ«αñ╣αñ╛αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░ αñòαÑç αñáαñ╛αñúαÑç αñ«αÑçαñé αñòαÑüαññαÑìαññαÑç αñ¿αÑç αñûαñ╛αñê αñ¬αñíαñ╝αÑïαñ╕αÑÇ αñòαÑÇ αñ«αÑüαñ░αÑìαñùαÑÇαÑñ αñ╡αñ┐αñ╡αñ╛αñª αñ«αÑçαñé αñÜαñ▓αÑÇ αñùαÑïαñ▓αÑÇαÑñ\n10:28\n10 minutes, 28 seconds\nαñòαÑüαññαÑìαññαÑç αñòαñ╛ αñ«αñ╛αñ▓αñ┐αñò αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░αÑñ αñ«αÑüαñ░αÑìαñùαÑÇ αñòαñ╛ αñ╣αñ░αÑìαñ£αñ╛αñ¿αñ╛ αñ«αñ╛αñéαñùαñ¿αÑç αñ¬αñ░ αñòαÑüαññαÑìαññαÑç αñòαÑç αñ«αñ╛αñ▓αñ┐αñò αñòαÑï αñÜαñ▓αñ╛αñê αñÑαÑÇ αñùαÑïαñ▓αÑÇαÑñ\n10:36\n10 minutes, 36 seconds\nαñ£αÑïαñºαñ¬αÑüαñ░ αñ«αÑçαñé αñ¬αÑüαñ▓αñ┐αñ╕ αñÑαñ╛αñ¿αÑç αñ«αÑçαñé αñ¬αÑéαñ¢αññαñ╛αñ¢ αñòαÑç αñ▓αñ┐αñÅ αñ¼αÑüαñ▓αñ╛αñÅ αñùαñÅ αñ»αÑüαñ╡αñò αñòαÑÇ αñ«αÑîαññαÑñ αñ▓αñ╛αñ¬αññαñ╛ αñ«αñ╣αñ┐αñ▓αñ╛ αñòαÑç αñ╕αñ┐αñ▓αñ╕αñ┐αñ▓αÑç αñ«αÑçαñé αñ¬αÑéαñ¢αññαñ╛αñ¢ αñòαÑç αñ▓αñ┐αñÅ αñÑαñ╛αñ¿αÑç αñ¼αÑüαñ▓αñ╛αñ»αñ╛ αñùαñ»αñ╛ αñÑαñ╛ αñ»αÑüαñ╡αñòαÑñ αñ¬αñ░αñ┐αñ╡αñ╛αñ░ αñ╡αñ╛αñ▓αÑïαñé αñ¿αÑç αñòαÑÇ αñ«αñ╛αñ«αñ▓αÑç αñòαÑÇ αñ£αñ╛αñéαñÜ αñòαÑÇ αñ«αñ╛αñéαñùαÑñ\n10:48\n10 minutes, 48 seconds\nαñ¢αññαÑìαññαÑÇαñ╕αñùαñóαñ╝ αñòαÑç αñ╕αÑéαñ░αñ£αñ¬αÑüαñ░ αñ«αÑçαñé αñùαñ░αÑìαñ¡αñ╡αññαÑÇ αñ«αñ╣αñ┐αñ▓αñ╛ αñòαÑÇ αñ«αÑîαññ αñ¬αñ░ αñ╣αñéαñùαñ╛αñ«αñ╛αÑñ αñ¬αñ░αñ┐αñ╡αñ╛αñ░ αñ╡αñ╛αñ▓αÑïαñé αñ¿αÑç αñàαñ╕αÑìαñ¬αññαñ╛αñ▓ αñòαÑç αñíαÑëαñòαÑìαñƒαñ░αÑìαñ╕ αñ¬αñ░ αñ▓αñùαñ╛αñ»αñ╛ αñ▓αñ╛αñ¬αñ░αñ╡αñ╛αñ╣αÑÇ αñòαñ╛ αñåαñ░αÑïαñ¬αÑñ αñ╕αÑìαñ╡αñ╛αñ╕αÑìαñÑαÑìαñ» αñ╡αñ┐αñ¡αñ╛αñù αñ¿αÑç αñùαñáαñ┐αññ αñòαÑÇ αñ£αñ╛αñéαñÜ αñƒαÑÇαñ«αÑñ\n11:00\n11 minutes\nαñ░αñ╛αñ£αñ╕αÑìαñÑαñ╛αñ¿ αñòαÑç αñ¥αñ╛αñ▓αñ╛αñ╡αñ╛αñíαñ╝ αñ«αÑçαñé αñ╣αññαÑìαñ»αñ╛ αñòαÑç αñåαñ░αÑïαñ¬αÑÇ αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñ¼αñíαñ╝αÑÇ αñòαñ╛αñ░αÑìαñ»αñ╡αñ╛αñ╣αÑÇαÑñ αñ¬αÑìαñ░αñ╢αñ╛αñ╕αñ¿ αñ¿αÑç αñ╣αñ┐αñ╕αÑìαñƒαÑìαñ░αÑÇ αñ╢αÑÇαñƒαñ░ αñ╕αñ╛αñùαñ░ αñòαÑüαñ░αÑêαñ╢αÑÇ αñòαÑç αñ╕αñ╛αñÑ αñàαñ╡αÑêαñº αñòαñ¼αÑìαñ£αÑïαñé αñ¬αñ░ αñÜαñ▓αñ╛αñ»αñ╛ αñ¼αÑüαñ▓αñíαÑïαñ£αñ░αÑñ αñ«αÑîαñòαÑç αñ¬αñ░ αñ¡αñ╛αñ░αÑÇ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¼αñ▓ αñ░αñ╣αñ╛ αñ«αÑîαñ£αÑéαñªαÑñ\n11:13\n11 minutes, 13 seconds\nαñ£αÑêαñ╕αñ▓αñ«αÑçαñ░ αñ«αÑçαñé αñåαñêαñÅαñ╕αñåαñê αñÅαñ£αÑçαñéαñƒ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░αÑñ\n11:15\n11 minutes, 15 seconds\nαñ¼αÑÇαñÅαñ╕αñÅαñ½ αñöαñ░ αñ╕αÑçαñ¿αñ╛ αñòαÑç αñ«αÑéαñ╡αñ«αÑçαñéαñƒ αñòαÑÇ αñ£αñ╛αñ¿αñòαñ╛αñ░αÑÇ αñ¡αÑçαñ£αññαñ╛ αñÑαñ╛αÑñ αñªαÑüαñòαñ╛αñ¿ αñòαÑÇ αñåαñíαñ╝ αñ«αÑçαñé αñòαñ░αññαñ╛ αñÑαñ╛ αñ¬αñ╛αñòαñ┐αñ╕αÑìαññαñ╛αñ¿ αñòαÑç αñ▓αñ┐αñÅ αñ£αñ╛αñ╕αÑéαñ╕αÑÇαÑñ\n11:25\n11 minutes, 25 seconds\nαñùαÑüαñ░αÑüαñùαÑìαñ░αñ╛αñ« αñ«αÑçαñé αñòαÑìαñ░αñ╛αñçαñ« αñ¼αÑìαñ░αñ╛αñéαñÜ αñ¿αÑç 13 αñàαñ╡αÑêαñº αñ¼αñ╛αñéαñùαÑìαñ▓αñ╛αñªαÑçαñ╢αñ┐αñ»αÑïαñé αñòαÑï αñ¬αñòαñíαñ╝αñ╛αÑñ αñòαñ╛αñ▓αñ┐αñ»αñ╛αñùαñéαñ£ αñ¼αÑëαñ░αÑìαñíαñ░ αñ╕αÑç αñÅαñ£αÑçαñéαñƒ αñòαÑÇ αñ«αñªαñª αñ╕αÑç αñÿαÑüαñ╕αÑç αñÑαÑç αñ¡αñ╛αñ░αññαÑñ\n11:31\n11 minutes, 31 seconds\nαñ«αñ£αñªαÑéαñ░ αñ¼αñ¿αñòαñ░ αñ¥αÑüαñùαÑìαñùαñ┐αñ»αÑïαñé αñ«αÑçαñé αñ░αñ╣ αñ░αñ╣αÑç αñÑαÑç αñ¼αñ╛αñéαñùαÑìαñ▓αñ╛αñªαÑçαñ╢ αñ¿αñ╛αñùαñ░αñ┐αñòαÑñ\n11:38\n11 minutes, 38 seconds\nαñƒαÑÇαñ╡αÑÇ αñÅαñòαÑìαñƒαÑìαñ░αÑçαñ╕ αñàαñéαñ£αñ┐αññαñ╛ αñëαñùαñ▓αÑç αñòαñ╛ αñíαÑëαñòαÑìαñƒαñ░ αñòαÑç αñ╕αñ╛αñÑ αñÜαÑêαñƒ αñåαñ»αñ╛ αñ╕αñ╛αñ«αñ¿αÑçαÑñ αñ¢ αñ«αñ╣αÑÇαñ¿αÑïαñé αñ╕αÑç αñíαñ┐αñ¬αÑìαñ░αÑçαñ╢αñ¿ αñ«αÑçαñé αñÑαÑÇ αñ╕αñéαñ┐αññαñ╛αÑñ\n11:49\n11 minutes, 49 seconds\nαñ░αñ╛αñ£αñ╕αÑìαñÑαñ╛αñ¿ αñòαÑç αñ¥αñ╛αñ▓αñ╛αñ╡αñ╛αñíαñ╝ αñ«αÑçαñé αñ¿αñ╢αñ╛ αññαñ╕αÑìαñòαñ░αÑïαñé αñöαñ░ αñëαñ¿αñòαÑç αñ«αñªαñªαñùαñ╛αñ░αÑïαñé αñòαÑÇ αñòαñ░αÑïαñíαñ╝αÑïαñé αñòαÑÇ αñ╕αñéαñ¬αññαÑìαññαñ┐ αñ╕αÑÇαñ£ αñÅαñ¿αñíαÑÇαñ¬αÑÇαñÅαñ╕ αñÅαñòαÑìαñƒ αñòαÑç αññαñ╣αññ αñòαÑÇ αñùαñê αñòαñ╛αñ░αñ╡αñ╛αñêαÑñ\n11:59\n11 minutes, 59 seconds\nαñ¢αññαÑìαññαÑÇαñ╕αñùαñóαñ╝ αñòαÑç αñòαñê αñ£αñ┐αñ▓αÑïαñé αñ«αÑçαñé αñêαñíαÑÇ αñòαÑÇ αñ░αÑçαñí, αñ░αñ╛αñ»αñ¬αÑüαñ░, αñªαÑüαñ░αÑìαñù, αñºαñ«αñòαññ αñöαñ░ αñòαÑïαñ░αñ¼αñ╛ αñ╕αñ«αÑçαññ αñ¿αÑî αñ£αñùαñ╣ αñ¢αñ╛αñ¬αÑçαñ«αñ╛αñ░αÑÇαÑñ αñíαÑÇαñÅαñ«αñÅαñ½ αñöαñ░ αñ¡αñ╛αñ░αññαñ«αñ╛αñ▓αñ╛ αñÿαÑïαñƒαñ╛αñ▓αÑç αñòαÑï\n12:07\n12 minutes, 7 seconds\nαñ▓αÑçαñòαñ░ αñ£αñ╛αñéαñÜαÑñ αñ░αñ╛αñ¿αÑé αñ╕αñ╛αñ╣αÑé αñòαÑç αñòαñ░αÑÇαñ¼αñ┐αñ»αÑïαñé αñòαÑç αñÿαñ░ αñ¬αñ╣αÑüαñéαñÜαÑÇ αñêαñíαÑÇαÑñ\n12:14\n12 minutes, 14 seconds\nαñ░αñ╛αñ£αñ╕αÑìαñÑαñ╛αñ¿ αñòαÑç αñòαñê αñçαñ▓αñ╛αñòαÑïαñé αñ«αÑçαñé αñ¼αñªαñ▓αñ╛αñ╡, αñ«αÑîαñ╕αñ« αñòαñ╛ αñ«αñ┐αñ£αñ╛αñ£, αñ£αÑêαñ╕αñ▓αñ«αÑçαñ░ αñòαÑç αñ░αñ╛αñ«αñùαñóαñ╝ αñ╕αñ«αÑçαññ αñ╕αÑÇαñ«αñ╛αñ╡αñ░αÑìαññαÑÇ αñçαñ▓αñ╛αñòαÑïαñé αñ«αÑçαñé αñ¼αñ╛αñ░αñ┐αñ╢αÑñ αñ▓αÑïαñùαÑïαñé αñòαÑï αñ«αñ┐αñ▓αÑÇ αñùαñ░αÑìαñ«αÑÇ αñ╕αÑç αñ░αñ╛αñ╣αññαÑñ\n12:24\n12 minutes, 24 seconds\nαñªαñ┐αñ▓αÑìαñ▓αÑÇ αñòαÑç αñªαÑìαñ╡αñ╛αñ░αñòαñ╛ αñçαñ▓αñ╛αñòαÑç αñ«αÑçαñé αññαÑéαñ½αñ╛αñ¿ αñ╕αÑç αññαñ¼αñ╛αñ╣αÑÇαÑñ αññαÑçαñ£ αñ╣αñ╡αñ╛αñôαñé αñòαÑÇ αñ╡αñ£αñ╣ αñ╕αñíαñ╝αñò αñ¬αñ░ αñùαñ┐αñ░αÑç αñªαÑï αñ¬αÑçαñíαñ╝ αñåαñ╡αñ╛αñ£αñ╛αñ╣αÑÇ αñ¬αÑìαñ░αñ¡αñ╛αñ╡αñ┐αññ\n12:34\n12 minutes, 34 seconds\nαñùαÑüαñ░αÑüαñùαÑìαñ░αñ╛αñ« αñ«αÑçαñé αñ¼αñ╛αñ░αñ┐αñ╢ αñ¿αÑç αñûαÑïαñ▓αÑÇ αñ¬αÑìαñ░αñ╢αñ╛αñ╕αñ¿ αñòαÑÇ αñ¬αÑïαñ▓ αñ╣αñ▓αÑìαñòαÑÇ αñ¼αñ╛αñ░αñ┐αñ╢ αñ«αñ┐αñ▓αÑÇ αñ¬αÑüαñ▓αñ┐αñ╕ αñ▓αñ╛αñçαñ¿ αñòαÑç αñ╕αñ╛αñ«αñ¿αÑç αñ¡αñ░αñ╛ αñ¬αñ╛αñ¿αÑÇ αñ▓αÑïαñùαÑïαñé αñòαÑï αñ«αÑüαñ╢αÑìαñòαñ┐αñ▓αÑïαñé αñòαñ╛ αñòαñ░αñ¿αñ╛ αñ¬αñíαñ╝αñ╛\n12:41\n12 minutes, 41 seconds\nαñ╕αñ╛αñ«αñ¿αñ╛ 68 αñ╕αñ╛αñ▓ αñòαÑç αñ¿αñ┐αñÜαñ▓αÑç αñ╕αÑìαññαñ░ αñ¬αñ░ αñ¬αñ╣αÑüαñéαñÜαñ╛ αñ«αñªαÑüαñ░αñ╣ αñòαÑç αñ¬αñ╛αñ╕ αñ¬αñ╛αñ¿αÑÇ αññαñ«αñ┐αñ▓αñ¿αñ╛αñíαÑü αñòαÑç αñ╡αÑêαñª αñ¬αñ╛αñ░αÑìαñò αñòαñ╛ αñ¼αñíαñ╝αñ╛\n12:50\n12 minutes, 50 seconds\nαñ╣αñ┐αñ╕αÑìαñ╕αñ╛ αñûαñ╛αñ▓αÑÇ αñ¬αÑÇαñ¿αÑç αñòαÑç αñ¬αñ╛αñ¿αÑÇ αñöαñ░ αñ╕αñ¬αÑìαñ▓αñ╛αñê αñ¬αñ░ αñ¬αñíαñ╝αñ╛ αñàαñ╕αñ░ αñ«αñúαñ┐αñ¬αÑüαñ░ αñòαÑç αñ░αñ╛αñ£αñºαñ╛αñ¿αÑÇ αñçαñéαñ½αñ╛αñ▓ αñ«αÑçαñé αñ½αñ┐αñ░ αñ╕αÑç αññαñ¿αñ╛αñ╡\n12:58\n12 minutes, 58 seconds\nαñ¬αÑìαñ░αñªαñ░αÑìαñ╢αñ¿αñòαñ╛αñ░αñ┐αñ»αÑïαñé αñ¿αÑç αñ¬αÑìαñ░αñ«αÑüαñû αñ╕αÑìαñ╡αñ╛αñ╕αÑìαñÑαÑìαñ» αñ╕αñéαñ╕αÑìαñÑαñ╛αñ¿ αñ░αñ┐αñ«αÑìαñ╕ αñòαÑï αñÿαÑçαñ░αñ╛αÑñ αñàαñ╕αÑìαñ¬αññαñ╛αñ▓ αñ«αÑçαñé αññαÑÇαñ¿ αñòαÑüαñòαÑÇ αñ»αÑüαñ╡αñòαÑïαñé αñòαÑï αñ¡αñ░αÑìαññαÑÇ αñòαñ░αñ¿αÑç αñòαñ╛ αñ╡αñ┐αñ░αÑïαñºαÑñ\n13:08\n13 minutes, 8 seconds\nαñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ¿αÑçαññαñ╛ αñ£αñ╣αñ╛αñéαñùαÑÇαñ░ αñòαÑÇ αñ░αñ┐αñ╣αñ╛αñê αñòαÑç αñ▓αñ┐αñÅ αñ╕αñ«αñ░αÑìαñÑαñòαÑïαñé αñòαÑç αñ╕αñ╛αñÑ αñÑαñ╛αñ¿αÑç αñ¬αñ╣αÑüαñéαñÜαÑÇ αñ¬αññαÑìαñ¿αÑÇαÑñ\n13:11\n13 minutes, 11 seconds\nαñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñ¼αñ▓αÑïαñé αñ╕αÑç αñ╣αÑüαñê αñ¥αñíαñ╝αñ¬αÑñ αñ¡αñ╛αñùαññαÑç αñ╡αñòαÑìαññ αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñ¼αñ▓αÑïαñé αñ╕αÑç αñ¼αñÜαñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ αññαñ╛αñ▓αñ╛αñ¼ αñ«αÑçαñé αñòαÑéαñªαÑç αñ▓αÑïαñùαÑñ\n13:20\n13 minutes, 20 seconds\nαñ¬αñ╢αÑìαñÜαñ┐αñ« αñ¼αñéαñùαñ╛αñ▓ αñòαÑç αñ░αñ╛αñ¿αÑÇαñùαñéαñ£ αñ«αÑçαñé αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ¿αÑçαññαñ╛ αñ╕αÑîαñ«αñ┐αññαÑìαñ░ αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñòαÑï αñ½αÑçαñéαñòαÑç αñùαñÅ αñàαñéαñíαÑçαÑñ αñòαÑïαñ░αÑìαñƒ αñ▓αÑç αñ£αñ╛αñ¿αÑç αñòαÑç αñªαÑîαñ░αñ╛αñ¿ αñ╕αÑîαñ«αñ┐αññαÑìαñ░ αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñ¬αñ░ αñàαñéαñíαÑïαñé αñ╕αÑç αñ╣αñ«αñ▓αñ╛αÑñ\n13:31\n13 minutes, 31 seconds\nαñ▓αñûαñ¿αñè αñ«αÑçαñé 1912 αñòαÑëαñ▓ αñ╕αÑçαñéαñƒαñ░ αñ«αÑçαñé αñòαñ░αÑìαñ«αñÜαñ╛αñ░αñ┐αñ»αÑïαñé αñòαñ╛ αñòαÑëαñ▓ αñ╕αÑçαñéαñƒαñ░ αñòαÑç αñ¼αñ╛αñ╣αñ░ αñ╣αñéαñùαñ╛αñ«αñ╛αÑñ αñ╡αñ┐αñ¡αñ┐αñ¿αÑìαñ¿ αñ«αñ╛αñéαñùαÑïαñé αñòαÑï αñ▓αÑçαñòαñ░ αñæαñ½αñ┐αñ╕ αñòαÑç αñ¼αñ╛αñ╣αñ░ αñòαñ┐αñ»αñ╛ αñ¬αÑìαñ░αÑïαñƒαÑçαñ╕αÑìαñƒαÑñ αñíαÑìαñ»αÑéαñƒαÑÇ αñ¬αñ░ αñåαñ¿αÑç αñ¬αñ░ αñ¡αÑÇ αñ¡αññαÑìαññαñ╛ αñòαñ╛αñƒαñ¿αÑç αñòαÑç αñåαñ░αÑïαñ¬αÑñ\n13:43\n13 minutes, 43 seconds\nαñ╕αñéαñ¡αñ▓ αñ«αÑçαñé αñ«αÑüαñ╣αñ░αÑìαñ░αñ« αñòαÑï αñ▓αÑçαñòαñ░ αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñ╡αÑìαñ»αñ╡αñ╕αÑìαñÑαñ╛ αñ╣αÑüαñê αñòαñíαñ╝αÑÇαÑñ αñíαÑÇαñÅαñ« αñöαñ░ αñÅαñ╕αñ¬αÑÇ αñòαÑÇ αñàαñùαÑüαñ╡αñ╛αñê αñ«αÑçαñé αñ¿αñ┐αñòαñ╛αñ▓αñ╛ αñ½αÑìαñ▓αÑêαñù αñ«αñ╛αñ░αÑìαñÜαÑñ αñ▓αÑïαñùαÑïαñé αñòαÑç αñ╢αñ╛αñéαññαñ┐ αñòαÑç αñ╕αñ╛αñÑ αñ«αÑüαñ╣αñ░αÑìαñ░αñ« αñ«αñ¿αñ╛αñ¿αÑç αñòαÑÇαÑñ\n13:57\n13 minutes, 57 seconds\nαñ¿αÑÇαñƒ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛ αñªαÑïαñ¼αñ╛αñ░αñ╛ αñòαñ░αñ╛αñ¿αÑç αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñ»αñ╛αñÜαñ┐αñòαñ╛αÑñ αñåαñ£ αñ╕αÑüαñ¬αÑìαñ░αÑÇαñ« αñòαÑïαñ░αÑìαñƒ αñ¿αÑç αñ╕αÑüαñ¿αñ╡αñ╛αñêαÑñ αñòαñ╣αñ╛ αñòαÑüαñ¢ αñ▓αÑïαñùαÑïαñé αñöαñ░ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛ αñòαÑçαñéαñªαÑìαñ░ αññαñò αñ╕αÑÇαñ«αñ┐αññ αñòαÑÇ αñùαñíαñ╝αñ¼αñíαñ╝αÑÇαÑñ\n14:07\n14 minutes, 7 seconds\nαñ░αñ╛αñ£αñ╕αÑìαñÑαñ╛αñ¿ αñòαÑç αñ╕αÑÇαñòαñ░ αñ«αÑçαñé αñ¿αÑÇαñƒ αñàαñ¡αÑìαñ»αñ░αÑìαñÑαÑÇ αñ¿αÑç αñòαÑÇ αñåαññαÑìαñ«αñ╣αññαÑìαñ»αñ╛αÑñ αñ½αÑìαñ▓αÑêαñƒ αñ«αÑçαñé αñ¬αñéαñ£αÑç αñ╕αÑç αñ▓αñƒαñòαñ╛ αñ«αñ┐αñ▓αñ╛ αñ╢αñ╡αÑñ αñ¬αñ░αñ┐αñ╡αñ╛αñ░ αñòαÑç αñ╕αñ╛αñÑ αñ░αñ╣αñòαñ░ αñòαñ░ αñ░αñ╣αñ╛ αñÑαñ╛ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛ αñòαÑÇ αññαÑêαñ»αñ╛αñ░αÑÇαÑñ\n14:18\n14 minutes, 18 seconds\nαñªαÑçαñ╣αñ░αñ╛αñªαÑéαñ¿ αñ«αÑçαñé αñ¿αÑÇαñƒ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛ αñ«αÑçαñé αñ╕αñ½αñ▓αññαñ╛ αñ¿αñ╛ αñ«αñ┐αñ▓αñ¿αÑç αñ╕αÑç αñ¿αñ┐αñ░αñ╛αñ╢ αñ»αÑüαñ╡αññαÑÇ αñ¿αÑç αñ▓αñùαñ╛αñê αñ½αñ╛αñéαñ╕αÑÇαÑñ αñ«αÑîαñòαÑç αñ╕αÑç αñ«αñ┐αñ▓αñ╛ αñ╕αÑüαñ╕αñ╛αñçαñí αñ¿αÑïαñƒαÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ¬αñ░αñ┐αñ╡αñ╛αñ░ αñ╡αñ╛αñ▓αÑïαñé αñòαÑï αñªαÑÇ αñ£αñ╛αñ¿αñòαñ╛αñ░αÑÇαÑñ\n14:30\n14 minutes, 30 seconds\nαñ«αñÑαÑüαñ░αñ╛ αñ«αÑçαñé αñ¿αÑÇαñƒ αñ¬αÑçαñ¬αñ░ αñ▓αÑç αñ£αñ╛ αñ░αñ╣αÑÇ αñùαñ╛αñíαñ╝αÑÇ αñ░αÑüαñòαñ¿αÑç αñ╕αÑç αñ¼αñÜαñ╛ αñ╣αñíαñ╝αñòαñéαñ¬αÑñ αññαÑüαñ░αñéαññ αñ¿αÑç αñ╕αñéαñ¡αñ╛αñ▓αñ╛ αñ«αÑïαñ░αÑìαñÜαñ╛αÑñ\n14:35\n14 minutes, 35 seconds\nαñ¬αÑüαñ▓αñ┐αñ╕ αñòαÑÇ αñùαñ╛αñíαñ╝αÑÇ αñ«αÑçαñé αñûαñ░αñ╛αñ¼αÑÇ αñòαÑç αñ¼αñ╛αñª αñ░αÑüαñòαñ╛ αñÑαñ╛ αñòαñ╛αñ½αñ┐αñ▓αñ╛αÑñ\n14:42\n14 minutes, 42 seconds\nαññαñ«αñ┐αñ▓αñ¿αñ╛αñíαÑü αñ«αÑçαñé αñ¿αÑÇαñƒ αñ¬αÑçαñ¬αñ░ αñ▓αÑç αñ£αñ╛αñ¿αÑç αñòαÑç αñ░αñ┐αñ╣αñ░αÑìαñ╕αñ▓ αñÅαñ»αñ░αñ½αÑïαñ░αÑìαñ╕ αñòαÑÇ αñ╣αÑçαñ▓αÑÇαñòαÑëαñ¬αÑìαñƒαñ░ αñ╕αÑç αñ¿αÑÇαñƒ αñ¬αÑçαñ¬αñ░ αñ▓αÑç αñ£αñ╛αñ¿αÑç αñòαñ╛ αñàαñ¡αÑìαñ»αñ╛αñ╕ 21 αñ£αÑéαñ¿ αñòαÑï αñ╣αÑïαñ¿αÑç αñ╡αñ╛αñ▓αÑÇ αñ╣αÑê\n14:49\n14 minutes, 49 seconds\nαñ¿αÑÇαñƒ αñòαÑÇ αñªαÑïαñ¼αñ╛αñ░αñ╛ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛ αñ¿αÑÇαñƒ αñ¬αÑçαñ¬αñ░ αñ▓αÑÇαñò αñòαÑç αñåαñ░αÑïαñ¬αÑÇ αñ»αñ╢ αñ»αñ╛αñªαñ╡ αñòαÑï 21 αñ£αÑéαñ¿\n14:57\n14 minutes, 57 seconds\nαñòαÑï αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛ αñ«αÑçαñé αñ╢αñ╛αñ«αñ┐αñ▓ αñ╣αÑïαñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ αñ«αñ┐αñ▓αÑÇ αñ£αñ«αñ╛αñ¿αññαÑñ αñ¼αñ╣αñ¿ αñòαÑÇ αñ╢αñ╛αñªαÑÇ αñ«αÑçαñé αñ╢αñ╛αñ«αñ┐αñ▓ αñ╣αÑïαñ¿αÑç αñòαÑÇ αñ¡αÑÇ αñ«αñ┐αñ▓αÑÇ αñçαñ£αñ╛αñ£αññαÑñ\n15:06\n15 minutes, 6 seconds\nαñ»αÑéαñ¬αÑÇ αñ«αÑçαñé αñ¿αÑÇαñƒ αñàαñ¡αÑìαñ»αñ░αÑìαñÑαñ┐αñ»αÑïαñé αñòαÑï αñ¼αñ╕ αñòαñ┐αñ░αñ╛αñÅ αñ«αÑçαñé αñ«αñ┐αñ▓αÑçαñùαÑÇ 50% αñòαÑÇ αñ¢αÑéαñƒαÑñ αñ»αÑïαñùαÑÇ αñ╕αñ░αñòαñ╛αñ░ αñòαñ╛ αñ¼αñíαñ╝αñ╛ αñ½αÑêαñ╕αñ▓αñ╛αÑñ 21 αñ£αÑéαñ¿ αñòαÑï αñ╣αÑïαñùαÑÇ αñ¿αÑÇαñƒ αñòαÑÇ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛αÑñ\n15:17\n15 minutes, 17 seconds\nαñªαÑçαñ╢ αñ¡αñ░ αñ«αÑçαñé αñƒαÑçαñ▓αÑÇαñùαÑìαñ░αñ╛αñ« αñ¬αñ░ 22 αñ£αÑéαñ¿ αññαñò αñàαñ╕αÑìαñÑαñ╛αñê αñ░αÑïαñòαÑñ αñ¿αÑÇαñƒ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛ αñòαÑï αñ▓αÑçαñòαñ░ αñòαÑçαñéαñªαÑìαñ░ αñ╕αñ░αñòαñ╛αñ░ αñòαñ╛ αñ½αÑêαñ╕αñ▓αñ╛αÑñ αñ«αÑêαñ╕αÑçαñ£ αñÅαñíαñ┐αñƒ αñ½αÑÇαñÜαñ░ αñ¼αñéαñªαÑñ\n15:28\n15 minutes, 28 seconds\nαñòαÑïαñƒαñ╛ αñ«αÑçαñé αñòαñ╛αñ░αÑìαñ»αñòαÑìαñ░αñ« αñ╕αÑç αñ¬αñ╣αñ▓αÑç αñ╣αñƒαñ╛αñÅ αñùαñÅ αñ░αñ╛αñ╣αÑüαñ▓ αñùαñ╛αñéαñºαÑÇ αñòαÑç αñ¬αÑïαñ╕αÑìαñƒαñ░αÑñ αñ¿αñùαñ░ αñ¿αñ┐αñùαñ« αñ¿αÑç αñòαñ╣αñ╛ αñ¼αñ┐αñ¿αñ╛ αñçαñ£αñ╛αñ£αññ αñ▓αñùαñ╛αñÅ αñùαñÅ αñ¬αÑïαñ╕αÑìαñƒαñ░αÑñ\n15:38\n15 minutes, 38 seconds\nαñ¼αñ┐αñ╣αñ╛αñ░ αñ«αÑçαñé αñ«αñºαÑìαñ» αñ¿αñ┐αñ╖αÑçαñº αñ╡αñ┐αñ¡αñ╛αñù αñòαÑÇ αñòαñ╛αñéαñ╕αÑìαñƒαÑçαñ¼αñ▓ αñ¡αñ░αÑìαññαÑÇ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛αÑñ αñÅαñùαÑìαñ£αñ╛αñ« αñòαñ╛ αñåαñ£ αñªαÑéαñ╕αñ░αñ╛ αñªαñ┐αñ¿αÑñ αñªαÑï αñ¬αñ╛αñ▓αñ┐αñ»αÑïαñé αñ«αÑçαñé αñ╣αÑïαñùαÑÇ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛αÑñ\n15:48\n15 minutes, 48 seconds\nαñ░αñ╛αñ« αñ«αñéαñªαñ┐αñ░ αñÜαñóαñ╝αñ╛αñ╡αñ╛ αñÜαÑïαñ░αÑÇ αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñÅαñ╕αñåαñêαñíαÑÇ αñòαÑÇ αñ£αñ╛αñéαñÜ αñ£αñ╛αñ░αÑÇαÑñ αñ«αñéαñùαñ▓αñ╡αñ╛αñ░ αñòαÑï αñ«αñéαñªαñ┐αñ░ αñ¬αñ░αñ┐αñ╕αñ░ αñ«αÑçαñé 40 αñ╕αÑç αñ£αÑìαñ»αñ╛αñªαñ╛ αñ¼αÑêαñéαñò αñòαñ░αÑìαñ«αñ┐αñ»αÑïαñé αñ╕αÑç αñ¬αÑéαñ¢αññαñ╛αñ¢αÑñ\n15:55\n15 minutes, 55 seconds\nαñ£αÑüαñƒαñ╛αñê αñ¬αÑêαñ╕αÑç αñòαÑç αñ░αñûαñ░αñûαñ╛αñ╡ αñ╕αÑç αñ£αÑüαñíαñ╝αÑÇ αñ£αñ╛αñ¿αñòαñ╛αñ░αÑÇαÑñ\n16:01\n16 minutes, 1 second\nαñ░αñ╛αñ« αñ«αñéαñªαñ┐αñ░ αñòαÑç αñÜαñóαñ╝αñ╛αñ╡αñ╛ αñòαÑç αñÜαÑïαñ░αÑÇ αñòαñ╛ αñåαñ░αÑïαñ¬αÑÇ αñàαñ»αÑïαñºαÑìαñ»αñ╛ αñ╕αñ«αñ╛αñ£αñ╡αñ╛αñªαÑÇ αñ¬αñ╛αñ░αÑìαñƒαÑÇ αñòαÑç αñ╕αñ╛αñéαñ╕αñª αñ░αñ╛αÑçαñ╢ αñ¬αÑìαñ░αñ╕αñ╛αñª αñ¿αÑç αñòαñ╣αñ╛ αñ╕αÑüαñ¬αÑìαñ░αÑÇαñ« αñòαÑïαñ░αÑìαñƒ αñòαÑÇ αñ¿αñ┐αñùαñ░αñ╛αñ¿αÑÇ\n16:07\n16 minutes, 7 seconds\nαñ«αÑçαñé αñ╣αÑï αñ£αñ╛αñéαñÜ αñ«αñ«αññαñ╛ αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñ¿αÑç αñ¡αñ╡αñ╛αñ¿αÑÇαñ¬αÑüαñ░ αñ╕αÑÇαñƒ αñòαÑç αñ¿αññαÑÇαñ£αÑïαñé αñòαÑï\n16:14\n16 minutes, 14 seconds\nαñªαÑÇ αñÜαÑüαñ¿αÑîαññαÑÇ αñòαÑïαñ▓αñòαñ╛αññαñ╛ αñ╣αñ╛αñê αñòαÑïαñ░αÑìαñƒ αñ«αÑçαñé αñªαñ╛αñûαñ┐αñ▓ αñòαÑÇ αñ»αñ╛αñÜαñ┐αñòαñ╛ αñ¬αñòαÑìαñ╖αñ¬αñ╛αññ αñòαÑÇ αñåαñ╢αñéαñòαñ╛ αñ£αññαñ╛αñê\n16:22\n16 minutes, 22 seconds\nαñ╢αñ┐αñ╡αñ╕αÑçαñ¿αñ╛ αñëαñªαÑìαñºαñ╡ αñùαÑüαñƒ αñ«αÑçαñé αñƒαÑéαñƒ αñòαÑÇ αñÜαñ░αÑìαñÜαñ╛αñÅαñé αñ╕αÑéαññαÑìαñ░αÑïαñé αñòαÑç αñ«αÑüαññαñ╛αñ¼αñ┐αñò αñ╢αñ┐αñéαñª αñ╢αñ┐αñ╡αñ╕αÑçαñ¿αñ╛ αñòαÑç αñ╕αñéαñ¬αñ░αÑìαñò αñ«αÑçαñé αñëαñªαÑìαñºαñ╡ αñòαÑç αñ╕αñ╛αñéαñ╕αñª αñ¬αñ╣αÑüαñéαñÜαÑç αñªαñ┐αñ▓αÑìαñ▓αÑÇ αñåαñ£ αñ╢αÑìαñ░αÑÇαñòαñ╛αñéαññ αñ╢αñ┐αñéαñª αñòαÑç αñåαñ╡αñ╛αñ╕ αñ¬αñ░ αñ¼αÑêαñáαñòαÑñ\n16:35\n16 minutes, 35 seconds\nαñ¬αñéαñ£αñ╛αñ¼ αñ«αÑçαñé αñºαñ╛αñ░αÑìαñ«αñ┐αñò αñ«αÑüαñªαÑìαñªαÑïαñé αñ¬αñ░ αñùαñ«αñ╛αñê αñ░αñ╛αñ£αñ¿αÑÇαññαñ┐αÑñ αñ¡αñùαñ╡αñéαññ αñ«αñ╛αñ¿ αñ¿αÑç αñòαñ╣αñ╛ αñ╕αñ┐αñ»αñ╛αñ╕αÑÇ αñåαñòαñ╛αñ╢αñ╛αñôαñé αñòαÑç αñçαñ╢αñ╛αñ░αÑç αñ¬αñ░ αñ¼αñªαñ¿αñ╛αñ« αñòαñ░αñ¿αÑç αñòαÑÇ αñòαÑïαñ╢αñ┐αñ╢ αñòαñ░ αñ░αñ╣αÑç αñ╣αÑêαñé αñëαñÜαÑìαñÜ αñºαñ╛αñ░αÑìαñ«αñ┐αñò αñ╕αÑìαñÑαñ╛αñ¿αÑïαñé αñ¬αñ░ αñ¼αÑêαñáαÑç αñ▓αÑïαñùαÑñ\n16:46\n16 minutes, 46 seconds\nαñ¼αñ┐αñ╣αñ╛αñ░ αñòαÑêαñ¼αñ┐αñ¿αÑçαñƒ αñòαÑÇ αñ¼αÑêαñáαñòαÑñ αñåαñ£ αñ¬αñƒαñ¿αñ╛ αñ«αÑçαñé αñ╕αÑÇαñÅαñ« αñ╕αñ«αÑìαñ░αñ╛αñƒ αñÜαÑîαñºαñ░αÑÇ αñòαÑÇ αñàαñºαÑìαñ»αñòαÑìαñ╖αññαñ╛ αñ«αÑçαñé αñ╣αÑïαñùαÑÇ αñ«αÑÇαñƒαñ┐αñéαñùαÑñ αñòαñê αñàαñ╣αñ« αñ½αÑêαñ╕αñ▓αÑïαñé αñ¬αñ░ αñ▓αñù αñ╕αñòαññαÑÇ αñ╣αÑê αñ«αÑïαñ╣αñ░αÑñ\n16:56\n16 minutes, 56 seconds\nαñ¢αññαÑìαññαÑÇαñ╕αñùαñóαñ╝ αñ«αÑçαñé αñ¼αñ┐αñ£αñ▓αÑÇ αñ╣αÑüαñê αñ«αñ╣αñéαñùαÑÇαÑñ αñÿαñ░αÑçαñ▓αÑé αñ¼αñ┐αñ£αñ▓αÑÇ αñªαñ░αÑïαñé αñ«αÑçαñé 30 αñ╕αÑç 50 αñ¬αÑêαñ╕αÑç αñ¬αÑìαñ░αññαñ┐ αñ»αÑéαñ¿αñ┐αñƒ αññαñòαÑñ αñ¼αñóαñ╝αÑïαññαñ░αÑÇ αñòαñ«αñ░αÑìαñ╢αñ┐αñ»αñ▓ αñ¼αñ┐αñ£αñ▓αÑÇ 20 αñ╕αÑç 40 αñ¬αÑêαñ╕αÑç αñ¬αÑìαñ░αññαñ┐ αñ»αÑéαñ¿αñ┐αñƒ αñ«αñ╣αñéαñùαÑÇαÑñ\n17:09\n17 minutes, 9 seconds\nαñàαñ«αñ░αñ¿αñ╛αñÑ αñ»αñ╛αññαÑìαñ░αñ╛ αñòαÑï αñ▓αÑçαñòαñ░ αñ£αñ«αÑìαñ«αÑé αñòαñ╢αÑìαñ«αÑÇαñ░ αñ«αÑçαñé αñòαñíαñ╝αÑÇ αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛αÑñ αñòαñáαÑüαñå αñ«αÑçαñé αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñ¼αñ▓αÑïαñé αñ¿αÑç αñòαÑÇ αñ£αñ╛αñéαñÜαÑñ αñ░αÑçαñ▓αñ╡αÑç αñ╕αÑìαñƒαÑçαñ╢αñ¿ αñöαñ░ αñàαñ╣αñ« αñ£αñùαñ╣αÑïαñé αñòαñ╛ αñòαñ┐αñ»αñ╛ αñ¿αñ┐αñ░αÑÇαñòαÑìαñ╖αñúαÑñ\n17:20\n17 minutes, 20 seconds\nαñ¬αñéαñ£αñ╛αñ¼ αñòαÑç αñàαñ«αÑâαññαñ╕αñ░ αñ«αÑçαñé αñ╕αÑç αñ«αñ╛αññαñ╛ αñ╡αÑêαñ╖αÑìαñúαÑï αñªαÑçαñ╡αÑÇ αñòαñƒαñ╡αñ╛ αñòαÑç αñ▓αñ┐αñÅ αñ╡αñéαñªαÑç αñ¡αñ╛αñ░αññ αñƒαÑìαñ░αÑçαñ¿ αñòαÑÇ αñ╢αÑüαñ░αÑüαñåαññαÑñ\n17:25\n17 minutes, 25 seconds\nαñ¬αñéαñ£αñ╛αñ¼ αñòαÑç αñòαñê αñ╢αñ╣αñ░αÑïαñé αñòαÑï αñ¬αñ╣αñ▓αÑÇ αñ¼αñ╛αñ░ αñ╡αñéαñªαÑç αñ¡αñ╛αñ░αññ αñƒαÑìαñ░αÑçαñ¿ αñòαÑÇ αñ«αñ┐αñ▓αÑçαñùαÑÇ αñ╕αÑüαñ╡αñ┐αñºαñ╛αÑñ\n17:32\n17 minutes, 32 seconds\nαñôαñ╕αñ╛ αñòαÑÇ αñ╡αñ┐αñ░αñ╛αñ╕αññ αñöαñ░ αñ¬αñ░αñéαñ¬αñ░αñ╛ αñ╕αÑç αñ£αÑüαñíαñ╝αñ╛ αñòαñ╛αñ░αÑìαñ»αñòαÑìαñ░αñ«αÑñ αñ░αñ╛αñ»αñùαñóαñ╝αñ╛ αñ«αÑçαñé αñ«αñ¿αñ╛αñ»αñ╛ αñùαñ»αñ╛ αñ½αÑçαñ╕αÑìαñƒαñ┐αñ╡αñ▓αÑñ αñëαñíαñ╝αñ┐αñ»αñ╛ αñ╡αñ┐αñ░αñ╛αñ╕αññ αñöαñ░ αñ¬αñ░αñéαñ¬αñ░αñ╛αñôαñé αñòαÑï αñ¼αñ¿αñ╛αñÅ αñ░αñûαñ¿αÑç αñòαÑÇ αñ¬αñ╣αñ▓αÑñ\n17:43\n17 minutes, 43 seconds\nαñ«αñ╣αñ┐αñ▓αñ╛ αñƒαÑÇ20 αñ╡αñ░αÑìαñ▓αÑìαñí αñòαñ¬ αñ«αÑçαñé αñåαñ£ αñ¡αñ╛αñ░αññ αñòαÑç αñ╕αñ╛αñ«αñ¿αÑç αñ╣αÑïαñùαÑÇ αñ¿αÑÇαñªαñ░αñ▓αÑêαñéαñí αñòαÑÇ αñƒαÑÇαñ«αÑñ αñ¬αñ╛αñòαñ┐αñ╕αÑìαññαñ╛αñ¿ αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñ╢αñ╛αñ¿αñªαñ╛αñ░ αñ£αÑÇαññ αñ╕αÑç αñ¡αñ╛αñ░αññ αñòαÑç αñ╣αÑîαñ╕αñ▓αÑç αñ¼αÑüαñ▓αñéαñªαÑñ\n17:49\n17 minutes, 49 seconds\nαñ╢αñ╛αñ« 7:00 αñ¼αñ£αÑç αñ╢αÑüαñ░αÑé αñ╣αÑïαñùαñ╛ αñ«αÑüαñòαñ╛αñ¼αñ▓αñ╛αÑñ\n18:02\n18 minutes, 2 seconds\nαñÅαñ¼αÑÇαñ¬αÑÇ αñ¿αÑìαñ»αÑéαñ£αñ╝ αñåαñ¬αñòαÑï αñ░αñûαÑç αñåαñùαÑçαÑñ	f	2026-06-17 12:27:12.095263
35	UCRWFSbif-RFENbBrSiez1DA	National	General	Transcript\nSearch transcript\n0:02\n2 seconds\nαñ½αÑìαñ░αñ╛αñéαñ╕ αñ«αÑçαñé αñåαñ£ αñ¬αÑÇαñÅαñ« αñ«αÑïαñªαÑÇ αñöαñ░ αñƒαÑìαñ░αñéαñ¬ αñòαÑÇ αñ«αÑüαñ▓αñ╛αñòαñ╛αññαÑñ αñªαÑïαñ¿αÑïαñé αñ¿αÑçαññαñ╛αñôαñé αñòαÑç αñ¼αÑÇαñÜ αñ╣αÑïαñùαÑÇ αñªαÑìαñ╡αñ┐αñ¬αñòαÑìαñ╖αÑÇαñ» αñ¼αñ╛αññαñÜαÑÇαññαÑñ αñ¡αñ╛αñ░αññ αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñòαÑÇ αñƒαÑìαñ░αÑçαñí αñíαÑÇαñ▓ αñ╣αÑïαñùαÑÇ αñ¼αñ╛αññαñÜαÑÇαññ αñòαñ╛ αñ«αÑüαñûαÑìαñ» αñÅαñ£αÑçαñéαñíαñ╛αÑñ\n0:13\n13 seconds\nαñ½αÑìαñ░αñ╛αñéαñ╕ αñ«αÑçαñé αñòαñê αñªαÑçαñ╢αÑïαñé αñòαÑç αñ¿αÑçαññαñ╛αñôαñé αñòαÑç αñ╕αñ╛αñÑ αñ¬αÑÇαñÅαñ« αñ«αÑïαñªαÑÇ αñòαÑÇ αñ«αÑüαñ▓αñ╛αñòαñ╛αññαÑñ αñ£αñ╛αñ¬αñ╛αñ¿, αñªαñòαÑìαñ╖αñ┐αñú αñòαÑïαñ░αñ┐αñ»αñ╛, αñòαÑçαñ¿αÑìαñ»αñ╛, αñ»αÑéαñÅαñê αñòαÑç αñ¿αÑçαññαñ╛αñôαñé αñòαÑç αñ╕αñ╛αñÑ αñ╣αÑüαñê αñ╡αñ┐αñ¬αñòαÑìαñ╖αÑÇαñ» αñ¼αñ╛αññαñÜαÑÇαññ, αñ╡αÑìαñ»αñ╛αñ¬αñ╛αñ░ αñ╕αñ«αÑçαññ αñòαñê αñàαñ╣αñ« αñ«αÑüαñªαÑìαñªαÑïαñé αñ¬αñ░ αñÜαñ░αÑìαñÜαñ╛αÑñ\n0:27\n27 seconds\nαñ£αÑÇ7 αñ╕αñ«αÑìαñ«αÑçαñ▓αñ¿ αñ«αÑçαñé αñ¬αÑÇαñÅαñ« αñ«αÑïαñªαÑÇ αñ¿αÑç αñòαñ╣αñ╛ αñåαñ£ αñ╡αñ┐αñ╢αÑìαñ╡αñ╛αñ╕ αñòαÑÇ αñòαñ«αÑÇ αñ╕αÑç αñ£αÑéαñ¥ αñ░αñ╣αÑÇ αñ╣αÑê αñªαÑüαñ¿αñ┐αñ»αñ╛αÑñ\n0:31\n31 seconds\nαñ¼αñ╛αññαñÜαÑÇαññ αñòαÑç αñ£αñ░αñ┐αñÅ αñ╣αÑïαñ¿αñ╛ αñÜαñ╛αñ╣αñ┐αñÅ αññαñ¿αñ╛αñ╡αÑïαñé αñöαñ░ αñ»αÑüαñªαÑìαñºαÑïαñé αñòαñ╛ αñ╕αñ«αñ╛αñºαñ╛αñ¿αÑñ\n0:38\n38 seconds\nαñ¬αÑÇαñÅαñ« αñ«αÑïαñªαÑÇ αñ¿αÑç αñòαñ╣αñ╛ αñ¿αñ╛αñ╡αñ┐αñòαÑïαñé αñòαÑÇ αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñ╣αñ«αñ╛αñ░αñ╛ αñªαñ╛αñ»αñ┐αññαÑìαñ╡ αñ╣αÑêαÑñ αñ╕αÑüαñ¿αñ┐αñ╢αÑìαñÜαñ┐αññ αñòαñ░αñ¿αñ╛ αñ╣αÑïαñùαñ╛αÑñ\n0:42\n42 seconds\nαñ╕αñ«αÑüαñªαÑìαñ░αÑÇ αñ«αñ╛αñ░αÑìαñù αñ░αñ╣αÑç αñ╕αÑüαñ░αñòαÑìαñ╖αñ┐αññαÑñ αñ¼αñ┐αñ¿αñ╛ αñíαñ░ αñòαÑç αñ¿αñ╛αñ╡αñ┐αñò αñòαñ░ αñ╕αñòαÑçαñé αñàαñ¬αñ¿αñ╛ αñòαñ╛αñ░αÑìαñ»αÑñ\n0:50\n50 seconds\nαñòαñ¿αñ╛αñíαñ╛ αñòαÑç αñ¬αÑìαñ░αñºαñ╛αñ¿αñ«αñéαññαÑìαñ░αÑÇ αñòαÑç αñ╕αñ╛αñÑ αñ¬αÑÇαñÅαñ« αñ«αÑïαñªαÑÇ αñòαÑÇ αñªαÑìαñ╡αñ┐αñ¬αñòαÑìαñ╖αÑÇαñ» αñ¼αÑêαñáαñòαÑñ αñòαñ╣αñ╛ αñòαñ┐ αñèαñ░αÑìαñ£αñ╛ αñòαÑç αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñòαñ¿αñ╛αñíαñ╛ αñ╣αÑï αñ╕αñòαññαñ╛ αñ╣αÑê αñ¬αÑìαñ░αñ«αÑüαñû αñ¡αñ╛αñùαÑÇαñªαñ╛αñ░αÑñ αñòαñ¿αñ╛αñíαñ╛ αñòαÑç αñ¬αÑÇαñÅαñ« αñ¿αÑç αñòαñ╣αñ╛ αñàαñ¬αñ¿αÑç αñ╡αÑìαñ»αñ╛αñ¬αñ╛αñ░ αñòαÑï αñªαÑïαñùαÑüαñ¿αñ╛ αñòαñ░αñ¿αñ╛ αñ╣αñ«αñ╛αñ░αñ╛ αñ▓αñòαÑìαñ╖αÑìαñ»αÑñ\n1:04\n1 minute, 4 seconds\nαñ½αÑìαñ░αñ╛αñéαñ╕ αñ«αÑçαñé αñ¬αÑÇαñÅαñ« αñ«αÑïαñªαÑÇ αñòαÑÇ αñ¼αÑìαñ░αñ┐αñƒαñ┐αñ╢ αñ¬αÑìαñ░αñºαñ╛αñ¿αñ«αñéαññαÑìαñ░αÑÇ αñòαÑç αñ╕αñ╛αñÑ αñ╣αÑüαñê αñªαÑìαñ╡αñ┐αñ¬αñòαÑìαñ╖αÑÇαñ» αñ╡αñ╛αñ░αÑìαññαñ╛αÑñ αñ»αÑéαñÅαñê αñòαÑç αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ¬αññαñ┐ αñòαÑç αñ╕αñ╛αñÑ αñ¡αÑÇ αñ╣αÑüαñê αñªαÑìαñ╡αñ┐αñ¬αñòαÑìαñ╖αÑÇαñ» αñ¼αñ╛αññαñÜαÑÇαññαÑñ\n1:13\n1 minute, 13 seconds\nαñ½αÑìαñ░αñ╛αñéαñ╕ αñòαÑç αñåαñ¡αñ┐αñ»αñ╛αñ¿ αñ«αÑçαñé αñ£αÑÇ7 αñ╢αñ┐αñûαñ░ αñ╕αñ«αÑìαñ«αÑçαñ▓αñ¿αÑñ\n1:16\n1 minute, 16 seconds\nαñ¬αÑÇαñÅαñ« αñ«αÑïαñªαÑÇ αñ¿αÑç αñ½αÑêαñ«αñ┐αñ▓αÑÇ αñ½αÑïαñƒαÑï αñ«αÑçαñé αñ╣αñ┐αñ╕αÑìαñ╕αñ╛ αñ¡αÑÇ αñ▓αñ┐αñ»αñ╛αÑñ αñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ¬αññαñ┐ αñƒαÑìαñ░αñéαñ¬ αñòαÑï αñ╕αñ╣αñ╛αñ░αñ╛ αñªαÑçαññαÑç αñ¿αñ£αñ░ αñåαñÅαÑñ\n1:24\n1 minute, 24 seconds\nαñÅαñò αññαñ░αñ½ αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñöαñ░ αñêαñ░αñ╛αñ¿ αñòαÑç αñ¼αÑÇαñÜ αñíαÑÇαñ▓ αñ╣αÑïαñ¿αÑç αñòαÑÇ αñûαñ¼αñ░ αñ╕αñ╛αñ«αñ¿αÑç αñå αñ░αñ╣αÑÇ αñ╣αÑê αññαÑï αñªαÑéαñ╕αñ░αÑÇ αññαñ░αñ½ αñ╣αÑëαñ░αÑìαñ¿αÑéαñ╕ αñòαÑï αñ▓αÑçαñòαñ░ αññαñ¿αñ╛αññαñ¿αÑÇ αñ¡αÑÇ αñªαÑçαñûαñ¿αÑç αñòαÑï αñ«αñ┐αñ▓ αñ░αñ╣αÑÇ αñ╣αÑêαÑñ αñíαÑÇαñ▓ αñòαÑï αñ▓αÑçαñòαñ░ αñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑÇ αñ¼αÑçαñÜαÑêαñ¿αÑÇ αñöαñ░\n1:32\n1 minute, 32 seconds\nαñ£αÑìαñ»αñ╛αñªαñ╛ αñ¼αñóαñ╝ αñùαñê αñ╣αÑêαÑñ αñòαÑìαñ»αñ╛ αñ╣αÑê αñ«αñ┐αñíαñ┐αñ▓ αñêαñ╕αÑìαñƒ αñ╕αÑç αñ£αÑüαñíαñ╝αñ╛ αñ¿αñ»αñ╛ αñàαñ¬αñíαÑçαñƒ? αñåαñ¬αñòαÑï αñªαñ┐αñûαñ╛ αñªαÑçαññαÑç αñ╣αÑêαñé αñ¿αÑîαñ╕αñ┐αñò αñ¿αÑìαñ»αÑéαñ£αñ╝ αñ«αÑçαñéαÑñ\n1:39\n1 minute, 39 seconds\nαñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ¬αññαñ┐ αñíαÑïαñ¿αñ▓αÑìαñí αñƒαÑìαñ░αñéαñ¬ αñ¿αÑç αñ»αñ╣ αñòαñ╣αñ╛ αñ╣αÑê αñòαñ┐ αñêαñ░αñ╛αñ¿ αñòαÑç αñ¬αñ╛αñ╕ αñ¿αñ╣αÑÇαñé αñ╣αÑïαñéαñùαÑç αñ¬αñ░αñ«αñ╛αñúαÑü αñ╣αñÑαñ┐αñ»αñ╛αñ░αÑñ αñ╕αñ«αñ¥αÑîαññαÑç αñòαÑç 60 αñªαñ┐αñ¿ αñ¼αñ╛αñª αñ¡αÑÇ αñ╡αñ╣ αñ¼αñùαÑêαñ░ αñòαñ┐αñ╕αÑÇ αñ½αÑÇαñ╕ αñòαÑç αñûαÑïαñ▓ αñªαÑçαñùαñ╛ αñ╣αÑëαñ░αñ«αñ╕αÑñ\n1:51\n1 minute, 51 seconds\nαñ╣αÑïαñ«αÑéαñ£ αñ«αÑçαñé αññαÑçαñ▓ αñƒαÑêαñéαñòαñ░αÑìαñ╕ αñòαÑÇ αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñòαÑç αñ▓αñ┐αñÅ αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñòαñ╛ αñ¿αñ»αñ╛ αñ¬αÑìαñ▓αñ╛αñ¿αÑñ αñôαñ«αñ╛αñ¿ αñöαñ░ αñ»αÑéαñÅαñê αñòαÑç αññαñƒ αñòαÑç αñ¬αñ╛αñ╕ αñ¼αñíαñ╝αÑç αññαÑçαñ▓ αñƒαÑêαñéαñòαñ░αÑìαñ╕ αñ«αÑçαñé αññαÑçαñ▓ αñƒαÑìαñ░αñ╛αñéαñ╕αñ½αñ░ αñòαñ░αññαÑç αñ╣αÑêαñé αñ¢αÑïαñƒαÑç αñƒαÑçαñ▓ αñƒαÑêαñéαñòαñ░αÑñ αñêαñ░αñ╛αñ¿ αñòαÑç αñàαñºαñ┐αñòαñ╛αñ░\n2:00\n2 minutes\nαñ╡αñ╛αñ▓αÑç αñòαÑìαñ╖αÑçαññαÑìαñ░αÑïαñé αñ╕αÑç αñ¼αñ╛αñ╣αñ░ αñ░αñ╣αñòαñ░ αñ╣αÑï αñ░αñ╣αñ╛ αñ╣αÑê αñòαñ╛αñ░αÑìαñ»αÑñ\n2:05\n2 minutes, 5 seconds\nαñ╣αÑëαñ░αÑìαñ«αÑéαñ╕ αñòαÑï αñ▓αÑçαñòαñ░ αñêαñ░αñ╛αñ¿ αñòαñ╛ αñ¼αñíαñ╝αñ╛ αñ¼αñ»αñ╛αñ¿αÑñ αñòαñ╣αñ╛ αñòαñ┐ αñ╕αÑìαñƒαÑçαñƒ αñæαñ½ αñ╣αñ░αñ«αÑéαñ╕ αñ¬αñ░ αñàαñ¬αñ¿αñ╛ αñ¿αñ┐αñ»αñéαññαÑìαñ░αñú αñ¼αñ¿αñ╛αñÅ αñ░αñûαÑçαñùαñ╛ αññαÑêαñ░αñ╛αñ¿αÑñ αñ╣αÑëαñ░αÑìαñ«αÑéαñ╕ αñ╕αÑç αñêαñ░αñ╛αñ¿ αñòαÑÇ αñ¿αñ┐αñùαñ░αñ╛αñ¿αÑÇ αñ╕αÑç αñ╣αÑÇ αñùαÑüαñ£αñ░αÑçαñéαñùαÑç αñ£αñ╣αñ╛αñ£αÑñ\n2:17\n2 minutes, 17 seconds\nαñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñçαñéαñƒαÑçαñ▓αñ┐αñ£αÑçαñéαñ╕ αñ░αñ┐αñ¬αÑïαñ░αÑìαñƒ αñòαÑç αñ╣αñ╡αñ╛αñ▓αÑç αñ╕αÑç αñûαñ¼αñ░αÑñ αñêαñ░αñ╛αñ¿ αñ¿αÑç αñ»αñ╣ αñªαñ┐αñûαñ╛ αñªαñ┐αñ»αñ╛ αñòαñ┐ αñ╡αÑï αñ£αñ¼ αñÜαñ╛αñ╣αÑç αñ╕αÑìαñƒαÑçαñƒ αñæαñ½ αñ½αÑëαñ░αÑìαñ«αÑéαñ╕ αñòαÑï αñàαñ╕αñ░αñªαñ╛αñ░ αññαñ░αÑÇαñòαÑç αñ╕αÑç αñòαñ░ αñ╕αñòαññαñ╛ αñ╣αÑê αñ¼αñéαñªαÑñ αññαñ╣αñ░αñ╛αñ¿ αñòαÑï αñ«αñ┐αñ▓αñ╛ αñùαÑìαñ▓αÑïαñ¼αñ▓ αñçαñòαÑëαñ¿αñ«αÑÇ αñ¬αñ░ αñªαñ¼αñ╛αñ╡ αñ¼αñ¿αñ╛αñ¿αÑç αñòαñ╛ αñ¿αñ»αñ╛ αñ£αñ░αñ┐αñ»αñ╛αÑñ\n2:30\n2 minutes, 30 seconds\nαñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñçαñéαñƒαÑçαñ▓αñ┐αñ£αÑçαñéαñ╕ αñ░αñ┐αñ¬αÑïαñ░αÑìαñƒ αñ«αÑçαñé αñªαñ╛αñ╡αñ╛ αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛ αñ╣αÑê αñòαñ┐ αñêαñ░αñ╛αñ¿ αñòαÑç αñ¬αñ╛αñ╕ αñ╕αñ¡αÑÇ αñ¼αñíαñ╝αÑÇ αñ«αñ╛αññαÑìαñ░αñ╛ αñ«αÑçαñé αñ«αñ┐αñ╕αñ╛αñçαñ▓αÑìαñ╕ αñöαñ░ αñíαÑìαñ░αÑïαñ¿αñ╕ αñöαñ░ αñ¿αÑîαñ╕αÑêαñ¿αñ┐αñò αñ╕αñéαñ╕αñ╛αñºαñ¿ αñ╣αÑêαÑñ αñ╕αñ«αÑüαñªαÑìαñ░αÑÇ αñ«αñ╛αñ░αÑìαñùαÑïαñé αñòαÑç αñ▓αñ┐αñÅ αñ½αñ┐αñ░ αñ¼αñ¿ αñ╕αñòαññαñ╛ αñ╣αÑê αñûαññαñ░αñ╛αÑñ\n2:42\n2 minutes, 42 seconds\nαñ£αñ▓αÑìαñª αñ╕αñ╛αñ«αñ¿αÑç αñåαñÅαñùαñ╛ αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñêαñ░αñ╛αñ¿ αñíαÑÇαñ▓ αñòαñ╛ αñíαÑìαñ░αñ╛αñ½αÑìαñƒαÑñ αñíαÑïαñ¿αñ╛αñ▓αÑìαñí αñƒαÑìαñ░αñéαñ¬ αñ¼αÑïαñ▓αÑç αñ╡αÑï αñûαÑüαñª αñ╣αÑÇ αñ£αñ╛αñ░αÑÇ αñòαñ░αÑçαñéαñùαÑç αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñêαñ░αñ╛αñ¿ αñíαÑÇαñ▓ αñòαñ╛ αñíαÑìαñ░αñ╛αñ½αÑìαñƒ αñòαñ╣αñ╛ αñòαñ┐ αñíαÑÇαñ▓ αñòαñ╛ αñÅαñò-αñÅαñò αñ╢αñ¼αÑìαñª αñ¬αñóαñ╝αñòαñ░ αñ╕αÑüαñ¿αñ╛αñèαñéαñùαñ╛αÑñ\n2:51\n2 minutes, 51 seconds\nαñ¼αñ╣αÑüαññ αñàαñÜαÑìαñ¢αÑÇ αññαñ░αñ╣ αñ╕αÑç αñ¼αñ¿ αñ░αñ╣αñ╛ αñ╣αÑê αñÅαñ«αñôαñ»αÑéαÑñ\n2:56\n2 minutes, 56 seconds\nαñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ¬αññαñ┐ αñíαÑïαñ¿αñ▓αÑìαñí αñƒαÑìαñ░αñéαñ¬ αñ¿αÑç αñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑÇ αñòαñ╛αñ░αñ╡αñ╛αñ╣αÑÇ αñòαÑï αñ▓αÑçαñòαñ░ αñ¿αñ╛αñ░αñ╛αñ£αñùαÑÇ αñ╡αÑìαñ»αñòαÑìαññ αñòαÑÇ αñ╣αÑêαÑñ αñòαñ╣αñ╛ αñ╣αÑê αñòαñ┐ αñ╕αñ«αñ¥αÑîαññαÑç αñ╕αÑç 2 αñÿαñéαñƒαÑç αñ¬αñ╣αñ▓αÑç αñ¼αÑêαñ░αÑéαññ αñ«αÑçαñé αñçαñ£αñ░αñ╛αñçαñ▓ αñòαñ╛ αñ╣αñ«αñ▓αñ╛ αñ╣αÑïαñ¿αñ╛ αñëαñ¿αÑìαñ╣αÑçαñé αñàαñÜαÑìαñ¢αñ╛ αñ¿αñ╣αÑÇαñé αñ▓αñùαñ╛αÑñ\n3:08\n3 minutes, 8 seconds\nαñíαÑïαñ¿αñ▓ αñƒαÑìαñ░αñéαñ¬ αñ¿αÑç αññαÑï αñ»αñ╛αñ╣αÑé αñ¬αñ░ αññαñéαñ£ αñòαñ╕αñ╛αÑñ αñòαñ╣αñ╛ αñòαñ┐ αñ╣αÑ¢αñ¼αÑüαñ▓αÑìαñ▓αñ╛ αñòαÑç αñÅαñò αñ¿αÑçαññαñ╛ αñòαÑï αñûαÑïαñ£αñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ αñ¬αÑéαñ░αÑç αñàαñ¬αñ╛αñ░αÑìαñƒαñ«αÑçαñéαñƒ αñòαÑï αñëαñíαñ╝αñ╛αñ¿αñ╛ αñ╕αñ╣αÑÇ αñ¿αñ╣αÑÇαñé αñ╣αÑêαÑñ αñ£αñ░αÑéαñ░αÑÇ αñ¿αñ╣αÑÇαñé αñçαñ«αñ╛αñ░αññ αñ«αÑçαñé αñ░αñ╣αñ¿αÑç αñ╡αñ╛αñ▓αÑç αñ╕αñ¡αÑÇ αñ▓αÑïαñù αñ╣αÑ¢αñ¼αÑüαñ▓αÑìαñ▓αñ╛ αñ╕αÑç αñ£αÑüαñíαñ╝αÑç αñ╣αÑïαÑñ\n3:22\n3 minutes, 22 seconds\nαñíαÑëαñ¿αñ▓αÑìαñí αñƒαÑìαñ░αñéαñ¬ αñòαÑÇ αñ¿αÑçαññαñ¿ αñ»αñ╛αÑé αñòαÑï αñ╣αñ┐αñªαñ╛αñ»αññ αñòαñ╣αñ╛ αñòαñ┐ αñ¿αÑçαññαñ¿αÑìαñ»αñ╛ αñòαÑï αñ▓αÑçαñ¼αñ¿αñ╛αñ¿ αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñ╣αÑïαñ¿αñ╛ αñÜαñ╛αñ╣αñ┐αñÅ αñ£αÑìαñ»αñ╛αñªαñ╛ αñ£αñ┐αñ«αÑìαñ«αÑçαñªαñ╛αñ░αÑñ αñêαñ░αñ╛αñ¿ αñíαÑÇαñ▓ αñ¬αñ░ αñ¬αñíαñ╝ αñ░αñ╣αñ╛ αñ▓αÑçαñ¼αñ¿αñ╛αñ¿ αñ╣αñ«αñ▓αÑïαñé αñòαñ╛ αñ¿αñòαñ╛αñ░αñ╛αññαÑìαñ«αñò αñàαñ╕αñ░αÑñ\n3:35\n3 minutes, 35 seconds\nαñêαñ░αñ╛αñ¿ αñòαÑç αñ╡αñ┐αñªαÑçαñ╢ αñ«αñéαññαÑìαñ░αÑÇ αñàαñ¼αÑìαñ¼αñ╛αñ╕ αñàαñ░αñ╛αñ£αñ╢αÑÇ αñòαñ╛ αñ¼αñ»αñ╛αñ¿αÑñ αñòαñ╣αñ╛ αñòαñ┐ αñ»αÑüαñªαÑìαñº αññαñ¼ αññαñò αñûαññαÑìαñ« αñ¿αñ╣αÑÇαñé αñ╣αÑïαñùαñ╛ αñ£αñ¼ αññαñò αñçαñ£αñ░αñ╛αñ»αñ▓αÑÇ αñ╕αÑçαñ¿αñ╛ αñ▓αÑçαñ¼αñ¿αñ╛αñ¿ αñ«αÑçαñé αñòαñ¼αÑìαñ£αÑç αñ╡αñ╛αñ▓αÑç αñòαÑìαñ╖αÑçαññαÑìαñ░αÑïαñé αñ╕αÑç αñ╡αñ╛αñ¬αñ╕ αñ¿αñ╣αÑÇαñé αñ╣αñƒ αñ£αñ╛αññαÑÇαÑñ\n3:47\n3 minutes, 47 seconds\nαñêαñ░αñ╛αñ¿ αñòαÑÇ αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñòαÑï αñÜαÑçαññαñ╛αñ╡αñ¿αÑÇαÑñ αñêαñ░αñ╛αñ¿αÑÇ αñ╡αñ┐αñªαÑçαñ╢ αñ«αñéαññαÑìαñ░αÑÇ αñàαñ¼αÑìαñ¼αñ╛αñ╕ αñ░αñ╛αñòαÑìαñ╖αñ╢αÑÇ αñòαñ╛ αñ¼αñ»αñ╛αñ¿ αñòαñ╣αñ╛ αñòαñ┐ αñ▓αÑçαñ¼αñ¿αñ╛αñ¿ αñ¬αñ░ αñçαñ£αñ░αñ╛αñçαñ▓ αñòαñ╛ αñòαÑïαñê αñ¡αÑÇ αñ╣αñ«αñ▓αñ╛ αñ╕αñ«αñ¥αÑîαññαÑç αñòαñ╛ αñëαñ▓αÑìαñ▓αñéαñÿαñ¿ αñ╣αÑïαñùαñ╛αÑñ\n3:58\n3 minutes, 58 seconds\nαñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñêαñ░αñ╛αñ¿ αñ╕αñ«αñ¥αÑîαññαÑç αñòαÑï αñ▓αÑçαñòαñ░ αñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑÇ αñ¼αñíαñ╝αÑÇ αñÜαñ┐αñéαññαñ╛αÑñ αñ░αñ┐αñ¬αÑïαñ░αÑìαñƒαÑìαñ╕ αñòαÑç αñ«αÑüαññαñ╛αñ¼αñ┐αñò αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñ¿αÑç αñÅαñ«αñôαñ»αÑé αñòαñ╛ αñ¬αÑéαñ░αñ╛ αñ«αñ╕αÑîαñªαñ╛ αñ╕αñ╛αñ¥αñ╛ αñòαñ░αñ¿αÑç αñ╕αÑç αñçαñéαñòαñ╛αñ░ αñòαñ┐αñ»αñ╛αÑñ αñçαñ£αñ░αñ╛αñçαñ▓ αñ¿αÑç αñòαñ┐αñ╕αÑÇ αñ╕αñ«αñ¥αÑîαññαÑç αñòαñ╛ αñ¬αÑéαñ░αñ╛ αñ«αñ╕αÑîαñªαñ╛ αñªαÑçαñûαñ¿αÑç αñòαÑÇ αñ«αñ╛αñéαñùαÑñ\n4:11\n4 minutes, 11 seconds\nαñêαñ░αñ╛αñ¿ αñòαÑç αñ╕αñ╛αñÑ αñ╕αñ«αñ¥αÑîαññαñ╛ αñ▓αñ╛αñùαÑé αñ╣αÑïαñ¿αÑç αñòαÑç αñ¼αñ╛αñª αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñ▓αñùαñ╛ αñ╕αñòαññαñ╛ αñ╣αÑê αñ░αÑéαñ╕αÑÇ αññαÑçαñ▓ αñ╢αñ┐αñ¬αñ«αÑçαñéαñƒ αñ¬αñ░ αñÅαñò αñ¼αñ╛αñ░ αñ½αñ┐αñ░ αñ╕αÑç αñ¬αÑìαñ░αññαñ┐αñ¼αñéαñºαÑñ αñíαÑëαñ¿αÑìαñí αñƒαÑìαñ░αñéαñ¬ αñ¿αÑç αñ╕αñéαñòαÑçαññ αñªαñ┐αñÅαÑñ αñòαñ╣αñ╛ αñ╣αÑëαñ░αÑìαñ«αÑéαñ╕ αñ╕αÑç αñåαñ╡αñ╛αñ£αñ╛αñ╣αÑÇ αñ╕αñ╛αñ«αñ╛αñ¿αÑìαñ» αñ╣αÑïαññαÑç αñ╣αÑÇ αñ▓αÑç αñ╕αñòαññαÑç αñ╣αÑêαñé αñ½αÑêαñ╕αñ▓αñ╛αÑñ\n4:24\n4 minutes, 24 seconds\nαñòαñ╝αññαñ░ αñ¿αÑç αñ£αññαñ╛αñ»αñ╛ αñ╣αÑê αñ¡αñ░αÑïαñ╕αñ╛αÑñ αñòαñ╣αñ╛ αñòαñ┐ αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñêαñ░αñ╛αñ¿ αñíαÑÇαñ▓ αñòαÑç αñ¼αñ╛αñª αñûαÑüαñ▓ αñ£αñ╛αñÅαñùαñ╛ αñ╕αÑìαñƒαÑçαñƒ αñæαñ½ αñ½αÑëαñ░αÑìαñ«αÑéαñ╕αÑñ αñèαñ░αÑìαñ£αñ╛ αñåαñ¬αÑéαñ░αÑìαññαñ┐ αñ╕αñ╛αñ«αñ╛αñ¿αÑìαñ» αñ╣αÑïαñ¿αÑç αñòαÑÇ αñ¡αÑÇ αñëαñ«αÑìαñ«αÑÇαñª αñ╡αÑìαñ»αñòαÑìαññ αñòαÑÇαÑñ\n4:33\n4 minutes, 33 seconds\nαñªαñòαÑìαñ╖αñ┐αñúαÑÇ αñ▓αÑçαñ¼αñ¿αñ╛αñ¿ αñ«αÑçαñé αñçαñ£αñ░αñ╛αñçαñ▓αÑÇ αñ╕αÑçαñ¿αñ╛ αñòαÑç αñ╣αñ╡αñ╛αñê αñ╣αñ«αñ▓αÑçαÑñ αñÜαñ╛αñ░ αñ▓αÑïαñùαÑïαñé αñòαÑÇ αñ«αÑîαññ, αñòαñê αñ▓αÑïαñù αñÿαñ╛αñ»αñ▓, αñçαñ£αñ░αñ╛αñçαñ▓αÑÇ αñ╕αÑçαñ¿αñ╛ αñ¿αÑç αñÅαñò αñòαÑç αñ¼αñ╛αñª αñÅαñò αñòαñê αñ╣αñ╡αñ╛αñê αñ╣αñ«αñ▓αÑç αñòαñ┐αñÅαÑñ\n4:45\n4 minutes, 45 seconds\nαñªαñòαÑìαñ╖αñ┐αñúαÑÇ αñ▓αÑçαñ¼αñ¿αñ╛αñ¿ αñ«αÑçαñé αñ╣αñ┐αñ£αñ¼αÑüαñ▓αÑìαñ▓αñ╛ αñòαÑÇ αñ░αÑëαñòαÑçαñƒ αñ▓αÑëαñ¿αÑìαñÜαñ┐αñéαñù αñ╕αñ╛αñçαñƒ αñ¬αñ░ αñåαñêαñ£αÑÇαñÅαñ½ αñ¿αÑç αñàαñƒαÑêαñò αñòαñ┐αñ»αñ╛αÑñ\n4:49\n4 minutes, 49 seconds\nαñ╣αñ┐αñ£αñ¼αÑüαñ▓αÑìαñ▓αñ╛ αñòαÑç αñ╣αñ«αñ▓αÑïαñé αñòαÑç αñ£αñ╡αñ╛αñ¼ αñ«αÑçαñé αñçαñ£αñ░αñ╛αñçαñ▓αÑÇ αñ╕αÑçαñ¿αñ╛ αñ¿αÑç αñ¬αñ▓αñƒαñ╡αñ╛αñ░ αñòαñ┐αñ»αñ╛αÑñ\n4:55\n4 minutes, 55 seconds\nαñçαñ£αñ░αñ╛αñçαñ▓αÑÇ αñ╣αñ«αñ▓αÑïαñé αñ╕αÑç αññαñ¼αñ╛αñ╣ αñ╣αÑüαñå αñªαñòαÑìαñ╖αñ┐αñúαÑÇ αñ▓αñ╛αñ¼αñ¿αñ╛αñ¿ αñòαñ╛ αñ¿αñ╛αññαÑÇαñ» αñ╢αñ╣αñ░αÑñ αñçαñ«αñ╛αñ░αññαÑçαñé, αñ¼αñ╛αñ£αñ╛αñ░ αñöαñ░ αñ¼αÑüαñ¿αñ┐αñ»αñ╛αñªαÑÇ αñóαñ╛αñéαñÜαÑç αñûαñéαñíαñ░ αñ«αÑçαñé αññαñ¼αÑìαñªαÑÇαñ▓ αñ╣αÑüαñÅαÑñ αñÿαñ░ αñ▓αÑîαñƒ αñ░αñ╣αÑç αñ▓αÑïαñùαÑïαñé αñ¿αÑç αñàαñ¬αñ¿αñ╛ αñªαñ░αÑìαñª αñ¼αñ»αñ╛αñé αñòαñ┐αñ»αñ╛αÑñ\n5:08\n5 minutes, 8 seconds\nαñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñêαñ░αñ╛αñ¿ αñ╢αñ╛αñéαññαñ┐ αñ╕αñ«αñ¥αÑîαññαÑç αñòαñ╛ αñ╕αñéαñ»αÑüαñòαÑìαññ αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░ αñ¿αÑç αñ╕αÑìαñ╡αñ╛αñùαññ αñòαñ┐αñ»αñ╛αÑñ αñ»αÑéαñÅαñ¿ αñ¿αÑç αñíαÑÇαñ▓ αñòαÑï αñ¼αññαñ╛αñ»αñ╛ αñ«αñºαÑìαñ» αñ¬αÑéαñ░αÑìαñ╡ αñòαÑç αñ▓αñ┐αñÅ αñ¼αÑçαñ╣αñª αñàαñ╣αñ« αñ«αÑïαñíαñ╝αÑñ\n5:15\n5 minutes, 15 seconds\nαñ»αñ«αñ¿ αñ«αÑçαñé αñ╢αñ╛αñéαññαñ┐ αñ¬αÑìαñ░αñ»αñ╛αñ╕αÑïαñé αñòαÑï αñ¡αÑÇ αñ«αñ┐αñ▓ αñ╕αñòαññαÑÇ αñ╣αÑê αñ░αñ½αÑìαññαñ╛αñ░αÑñ\n5:21\n5 minutes, 21 seconds\nαññαÑüαñ░αÑìαñòαÑÇ αñ¿αÑç αñçαñ£αñ░αñ╛αñçαñ▓ αñ¬αñ░ αñ▓αñùαñ╛αñ»αñ╛ αñ╢αñ╛αñéαññαñ┐ αñ╕αñ«αñ¥αÑîαññαÑç αñ«αÑçαñé αñ¼αñ╛αñºαñ╛ αñíαñ╛αñ▓αñ¿αÑç αñòαñ╛ αñåαñ░αÑïαñ¬αÑñ αñ╡αñ┐αñªαÑçαñ╢ αñ«αñéαññαÑìαñ░αÑÇ αñ╣αñ╛αñòαñ╛αñ¿ αñ½αñªαñ╛αñ¿ αñ¼αÑïαñ▓αÑç αñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñ╕αñ╛αñ¥αñ╛ αñòαÑéαñƒαñ¿αÑÇαññαñ┐αñò αñ░αÑüαñû αñàαñ¬αñ¿αñ╛αñ¿αÑç αñòαÑÇ αñ£αñ░αÑéαñ░αññαÑñ\n5:33\n5 minutes, 33 seconds\nαñ»αÑéαñÅαñ¿ αñ¿αÑç αñòαñ┐αñ»αñ╛ αñªαñ╛αñ╡αñ╛αÑñ αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñêαñ░αñ╛αñ¿ αñòαÑç αñ¼αÑÇαñÜ αñ╣αÑïαñ¿αÑç αñ£αñ╛ αñ░αñ╣αÑç αñ╢αñ╛αñéαññαñ┐ αñ╕αñ«αñ¥αÑîαññαÑç αñòαÑç αñ¼αñ╛αñª αñ▓αÑçαñ¼αñ¿αñ╛αñ¿ αñ«αÑçαñé αñ╕αñéαñÿαñ░αÑìαñ╖ αñ«αÑçαñé αñòαñ«αÑÇ αñåαñê αñ╣αÑêαÑñ αñ╣αñ╡αñ╛αñê αñëαñ▓αÑìαñ▓αñéαñÿαñ¿ αñöαñ░ αñ«αñ┐αñ╕αñ╛αñçαñ▓ αñ╣αñ«αñ▓αÑïαñé αñòαÑÇ αñÿαñƒαñ¿αñ╛αñÅαñé αñ¡αÑÇ αñòαñ« αñ╣αÑüαñê αñ╣αÑêαÑñ\n5:46\n5 minutes, 46 seconds\nαñ»αñ«αñ¿ αñòαÑÇ αñ░αñ╛αñ£αñºαñ╛αñ¿αÑÇ αñ╕αñ¿αñ╛ αñ«αÑçαñé αñ▓αÑïαñùαÑïαñé αñ¿αÑç αñ¬αÑìαñ░αñªαñ░αÑìαñ╢αñ¿ αñòαñ┐αñ»αñ╛αÑñ αñ½αñ┐αñ▓αñ╕αÑìαññαÑÇαñ¿, αñêαñ░αñ╛αñ¿ αñöαñ░ αñ▓αÑçαñ¼αñ¿αñ╛αñ¿ αñòαÑç αñ╕αñ«αñ░αÑìαñÑαñ¿ αñ«αÑçαñé αñ¬αÑìαñ░αñªαñ░αÑìαñ╢αñ¿ αñ╣αÑüαñåαÑñ αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñöαñ░ αñçαñ╕αñ░αñ╛αñçαñ▓ αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñòαÑÇ αñ£αñ«αñòαñ░ αñ¿αñ╛αñ░αÑçαñ¼αñ╛αñ£αÑÇαÑñ\n5:59\n5 minutes, 59 seconds\nαñªαÑçαñûαñ┐αñÅ αñ¼αñéαñùαñ╛αñ▓ αñòαÑÇ αññαñ░αñ╣ αñ╣αÑÇ αñ«αñ╣αñ╛αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░ αñ«αÑçαñé αñ¡αÑÇ αñ¼αñíαñ╝αÑç αñûαÑçαñ▓αñ╛ αñ╣αÑïαñ¿αÑç αñòαÑï αñªαÑçαñûαñ¿αÑç αñòαÑï αñ«αñ┐αñ▓ αñ░αñ╣αñ╛ αñ╣αÑêαÑñ\n6:05\n6 minutes, 5 seconds\nαñ╕αÑéαññαÑìαñ░αÑïαñé αñòαÑç αñàαñ¿αÑüαñ╕αñ╛αñ░ αñëαñªαÑìαñºαñ╡ αñòαÑç αñåαñá αñ╕αñ╛αñéαñ╕αñª αñÅαñòαñ¿αñ╛αñÑ αñ╢αñ┐αñéαñª αñòαÑç αñ╕αñéαñ¬αñ░αÑìαñò αñ«αÑçαñé αñ╣αÑêαÑñ αñÉαñ╕αÑç αñ«αÑçαñé αñÅαñò αñ¼αñ╛αñ░ αñ½αñ┐αñ░ αñëαñªαÑìαñºαñ╡ αñ¿αÑç αñ╡αñ┐αñºαñ╛αñ»αñòαÑïαñé αñòαÑÇ αñ¼αÑêαñáαñò αñ¼αÑüαñ▓αñ╛αñê αñ╣αÑêαÑñ αñåαñ¬αñòαÑï αñªαñ┐αñûαñ╛ αñªαÑçαññαÑç αñ╣αÑêαñé αñ░αñ╛αñ£αñ¿αÑÇαññαñ┐ αñòαÑÇ αñ¼αñíαñ╝αÑÇ αñûαñ¼αñ░αÑçαñéαÑñ\n6:15\n6 minutes, 15 seconds\nαñ╢αñ┐αñ╡αñ╕αÑçαñ¿αñ╛ αñëαñªαÑìαñºαñ╡ αñùαÑüαñá αñ«αÑçαñé αñƒαÑéαñƒ αñòαÑÇ αñÜαñ░αÑìαñÜαñ╛αñÅαñé αññαÑçαñ£ αñ╣αÑï αñùαñê αñ╣αÑêαÑñ αñ╕αÑéαññαÑìαñ░αÑïαñé αñòαÑç αñàαñ¿αÑüαñ╕αñ╛αñ░ αñ╢αñ┐αñéαñª αñòαÑÇ αñ╢αñ┐αñ╡αñ╕αÑçαñ¿αñ╛ αñòαÑç αñ╕αñéαñ¬αñ░αÑìαñò αñ«αÑçαñé αñëαñªαÑìαñºαñ╡ αñòαÑç αñ¢αñ╣ αñ╕αñ╛αñéαñ╕αñª αñ¬αñ╣αÑüαñéαñÜαÑç αñ╣αÑêαñé αñªαñ┐αñ▓αÑìαñ▓αÑÇαÑñ αñåαñ£ αñ╢αÑìαñ░αÑÇαñòαñ╛αñéαññ αñ╢αñ┐αñéαñª αñòαÑç αñåαñ╡αñ╛αñ╕ αñ¬αñ░ αñòαñ░αÑçαñéαñùαÑç αñ¼αÑêαñáαñòαÑñ\n6:27\n6 minutes, 27 seconds\nαñƒαÑéαñƒ αñòαÑÇ αñÜαñ░αÑìαñÜαñ╛αñôαñé αñòαÑç αñ¼αÑÇαñÜ αñ╢αñ┐αñ╡αñ╕αÑçαñ¿αñ╛ αñëαñªαÑìαñºαñ╡ αñùαÑüαñƒ αñ¿αÑç αñ▓αÑïαñòαñ╕αñ¡αñ╛ αñàαñºαÑìαñ»αñòαÑìαñ╖ αñòαÑï αñÜαñ┐αñƒαÑìαñáαÑÇ αñ╕αÑîαñéαñ¬αÑÇ αñ╣αÑêαÑñ\n6:31\n6 minutes, 31 seconds\nαñòαñ╣αñ╛ αñ╣αÑê αñòαñ┐ αñÅαñòαñ«αñ╛αññαÑìαñ░ αñåαñºαñ┐αñòαñ╛αñ░αñ┐αñò αñªαñ▓ αñòαÑç αñ░αÑéαñ¬ αñ«αÑçαñé αñ╕αñéαñ╕αñª αñ«αÑçαñé αñªαÑÇ αñ£αñ╛αñÅ αñ«αñ╛αñ¿αÑìαñ»αññαñ╛αÑñ\n6:38\n6 minutes, 38 seconds\nαñ╢αñ┐αñ╡αñ╕αÑçαñ¿αñ╛ αñ╢αñ┐αñéαñª αñùαÑüαñƒ αñòαÑç αñ¿αÑçαññαñ╛ αñòαÑâαñ¬αñ╛αñ▓ αññαÑï αñ«αñ╛αñ¿αÑç αñòαñ╛ αñªαñ╛αñ╡αñ╛αÑñ αñ╣αñ«αñ╛αñ░αÑç αñ╕αñéαñ¬αñ░αÑìαñò αñ«αÑçαñé 16 αñ╡αñ┐αñºαñ╛αñ»αñò αñöαñ░ αñ╕αñ╛αññ αñ╕αñ╛αñéαñ╕αñª αñ╣αÑêαñéαÑñ αñ«αñ╛αñ¿αñ╕αÑéαñ¿ αñ╕αññαÑìαñ░αÑïαñé αñ╕αÑç αñ¬αñ╣αñ▓αÑç αñ╣αñ«αñ╛αñ░αÑÇ αñ¬αñ╛αñ░αÑìαñƒαÑÇ αñ«αÑçαñé αñ╣αÑï αñ£αñ╛αñÅαñéαñùαÑç αñ╢αñ╛αñ«αñ┐αñ▓αÑñ\n6:48\n6 minutes, 48 seconds\nαñ╢αñ┐αñ╡αñ╕αÑçαñ¿αñ╛ αñ»αÑéαñ¼αÑÇαñƒαÑÇ αñ╕αñ╛αñéαñ╕αñª αñ╕αñéαñ£αñ» αñ░αñ╛αñëαññ αñòαñ╛ αñ¼αñíαñ╝αñ╛ αñªαñ╛αñ╡αñ╛αÑñ αñ╕αñ╛αñéαñ╕αñªαÑïαñé αñòαÑï αñªαñ┐αñÅ αñ£αñ╛ αñ░αñ╣αÑç αñ╣αÑêαñé 15-15 αñòαñ░αÑïαñíαñ╝αÑñ αñ»αñ╣ αñ¼αÑçαñ╣αñª αñÜαÑîαñéαñòαñ╛αñ¿αÑç αñ╡αñ╛αñ▓αÑÇ αñÿαÑâαñúαñ┐αññαñ░αñ╛αñ£ αñ£αñ╛αñ¿αñòαñ╛αñ░αÑÇ αñ╣αÑêαÑñ\n7:00\n7 minutes\nαñëαñªαÑìαñºαñ╡ αñùαÑüαñá αñòαÑç αñòαÑüαñ¢ αñ╕αñ╛αñéαñ╕αñªαÑïαñé αñòαÑç αñ¬αñ╛αñ▓αñ╛ αñ¼αñªαñ▓αñ¿αÑç αñòαÑÇ αñàαñƒαñòαñ▓αÑçαñéαÑñ αñëαñªαÑìαñºαñ╡ αñáαñ╛αñòαñ░αÑç αñ¼αÑïαñ▓αÑç αñàαñùαñ░ αñ£αñ╛αñ¿αñ╛ αñ╣αÑê αññαÑï αñûαÑüαñ╢αÑÇ-αñûαÑüαñ╢αÑÇ αñ£αñ╛αñÅαñéαÑñ\n7:11\n7 minutes, 11 seconds\nαñëαñªαÑìαñºαñ╡ αñòαÑç αñ╕αñ╛αñéαñ╕αñªαÑïαñé αñòαÑç αñ¬αñ╛αñ▓αñ╛ αñ¼αñªαñ▓αñ¿αÑç αñòαÑÇ αñûαñ¼αñ░αÑçαñéαÑñ\n7:13\n7 minutes, 13 seconds\nαñÅαñ╕αñ¬αÑÇ αñ¿αÑçαññαñ╛ αñàαñ¼ αñ╡αÑï αñåαñ£ αñ¡αÑÇ αñ¼αÑïαñ▓αÑç αñªαÑçαñ╢ αñòαÑç αñ¿αÑçαññαñ╛ αñçαññαñ¿αÑç αñòαñ«αñ£αÑïαñ░ αñöαñ░ αñ▓αñ╛αñ▓αñÜαÑÇ αñ╣αÑï αñùαñÅ αñ╣αÑêαñé αñòαñ┐ αñ¢αÑïαñíαñ╝ αñ░αñ╣αÑç αñ╣αÑêαñé αñ╡αñ┐αñÜαñ╛αñ░αñºαñ╛αñ░αñ╛ αñöαñ░ αñ¬αñ╛αñ░αÑìαñƒαÑÇαÑñ\n7:23\n7 minutes, 23 seconds\nαñ╕αñ╛αñéαñ╕αñªαÑïαñé αñòαÑç αñƒαÑéαñƒαñ¿αÑç αñòαÑÇ αñûαñ¼αñ░αÑïαñé αñòαÑç αñ¼αÑÇαñÜ αñëαñªαÑìαñºαñ╡ αñ¿αÑç αñ¼αÑüαñ▓αñ╛αñê αñ╡αñ┐αñºαñ╛αñ»αñòαÑïαñé αñòαÑÇ αñ¼αÑêαñáαñòαÑñ 22 αñ£αÑéαñ¿ αñòαÑï αñ╢αñ╛αñ« 4:00 αñ¼αñ£αÑç αñ«αÑüαñéαñ¼αñê αñ«αÑçαñé αñ»αñ╣ αñ«αÑÇαñƒαñ┐αñéαñù αñ╣αÑïαñùαÑÇαÑñ\n7:35\n7 minutes, 35 seconds\nαñ«αñ«αññαñ╛ αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñ¿αÑç αñ¡αñ╡αñ╛αñ¿αÑÇαñ¬αÑüαñ░ αñ╕αÑÇαñƒ αñòαÑç αñ¿αññαÑÇαñ£αÑïαñé αñòαÑï αñÜαÑüαñ¿αÑîαññαÑÇ αñªαÑÇ αñ╣αÑêαÑñ αñòαÑïαñ▓αñòαñ╛αññαñ╛ αñ╣αñ╛αñê αñòαÑïαñ░αÑìαñƒ αñ«αÑçαñé αñªαñ╛αñûαñ┐αñ▓ αñòαÑÇ αñåαñ╢αñ┐αñòαñ╛αÑñ αñ¬αñòαÑìαñ╖αñ¬αñ╛αññ αñòαÑÇ αñ£αññαñ╛αñê αñ╣αÑê αñåαñ╢αñéαñòαñ╛αÑñ\n7:46\n7 minutes, 46 seconds\nαñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ╕αÑç αñàαñ▓αñù αñ╣αÑüαñÅ αñùαÑüαñƒ αñòαÑï αñ«αñ╛αñ¿αÑìαñ»αññαñ╛ αñªαÑçαñ¿αÑç αñòαñ╛ αñ«αñ╛αñ«αñ▓αñ╛αÑñ αñ╕αÑéαññαÑìαñ░αÑïαñé αñòαÑç αñàαñ¿αÑüαñ╕αñ╛αñ░ αñªαÑïαñ¿αÑïαñé αñùαÑüαñƒ αñòαñ╛ αñ¬αñòαÑìαñ╖ αñ╕αÑüαñ¿αÑçαñéαñùαÑç αñôαñ« αñ¼αñ┐αñ░αñ▓αñ╛αÑñ αñ«αñ«αññαñ╛ αñòαÑç αñùαÑüαñƒ αñòαÑï αñêαñ«αÑçαñ▓ αñ¡αÑçαñ£αñòαñ░ αñ«αñ╛αñéαñùαñ╛ αñ╣αÑê αñ¬αñòαÑìαñ╖αÑñ\n7:59\n7 minutes, 59 seconds\nαñ¼αñ╛αñùαÑÇ αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ╕αñ╛αñéαñ╕αñª αñ╕αÑüαñªαÑÇαñ¬ αñ¼αñ╛αñéαñªαÑïαñ¬αñ╛αñºαÑìαñ»αñ╛αñ» αñ¿αÑç αñòαñ╣αñ╛ αñçαñ╕αñòαñ╛ αñòαÑïαñê αñ«αññαñ▓αñ¼ αñ¿αñ╣αÑÇαñé αñòαñ┐ αñòαÑîαñ¿ αñòαÑìαñ»αñ╛ αñòαñ╣ αñ░αñ╣αñ╛ αñ╣αÑêαÑñ αñòαÑïαñ░αÑìαñƒ αññαñ» αñòαñ░αÑçαñùαñ╛ αñòαñ┐ αñàαñ╕αñ▓αÑÇ αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñòαÑîαñ¿ αñ╣αÑêαÑñ\n8:12\n8 minutes, 12 seconds\nαñ¥αñ╛αñ░αñûαñéαñí αñ«αÑçαñé αñ░αñ╛αñ£αÑìαñ»αñ╕αñ¡αñ╛ αñòαÑÇ αñªαÑï αñ╕αÑÇαñƒαÑïαñé αñ¬αñ░ 18 αñ£αÑéαñ¿ αñòαÑï αñÜαÑüαñ¿αñ╛αñ╡ αñ╡ αñÅαñ¿αñíαÑÇαñÅ αñòαÑç αñ╡αñ┐αñºαñ╛αñ»αñòαÑïαñé αñòαÑï αñ░αñ╛αñ£αÑìαñ» αñòαÑç αñ╣αÑïαñƒαñ▓ αñ«αÑçαñé αñ╢αñ┐αñ½αÑìαñƒ αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛ αñ╣αÑêαÑñ\n8:18\n8 minutes, 18 seconds\nαñ╣αÑçαñ«αñéαññ αñ╕αÑïαñ░αÑçαñ¿ αñòαÑÇ αñàαñºαÑìαñ»αñòαÑìαñ╖αññαñ╛ αñ«αÑçαñé αñçαñéαñíαñ┐αñ»αñ╛ αñ¼αÑìαñ▓αÑëαñò αñòαÑÇ αñ¼αÑêαñáαñò αñ¡αÑÇ αñ╣αÑüαñêαÑñ\n8:26\n8 minutes, 26 seconds\nαñåαñ£ αñ╕αñ«αñ╛αñ£αñ╡αñ╛αñªαÑÇ αñ¬αñ╛αñ░αÑìαñƒαÑÇ αñòαÑç αñæαñ½αñ┐αñ╕ αñ«αÑçαñé αñ¼αÑìαñ░αñ╛αñ╣αÑìαñ«αñú αñ╕αñ«αñ╛αñ£ αñòαÑç αñ¿αÑçαññαñ╛αñôαñé αñòαÑÇ αñ¼αñíαñ╝αÑÇ αñ¼αÑêαñáαñòαÑñ αñ╕αñ¡αÑÇ αñ╡αñ┐αñºαñ╛αñ»αñò, αñ¬αÑéαñ░αÑìαñ╡ αñ╡αñ┐αñºαñ╛αñ»αñò, αñ╕αñ╛αñéαñ╕αñª αñöαñ░ αñ¬αÑéαñ░αÑìαñ╡ αñ╕αñ╛αñéαñ╕αñª αñ╢αñ╛αñ«αñ┐αñ▓\n8:33\n8 minutes, 33 seconds\nαñ╣αÑïαñéαñùαÑçαÑñ αñ£αñ¿αÑçαñ╢αÑìαñ╡αñ░ αñ«αñ┐αñ╢αÑìαñ░ αñ£αñ»αñéαññαÑÇ αñòαÑç αñ£αñ░αñ┐αñÅ αñ╕αñéαñªαÑçαñ╢ αñªαÑçαñ¿αÑç αñòαÑÇ αñ╣αÑê αññαÑêαñ»αñ╛αñ░αÑÇαÑñ\n8:40\n8 minutes, 40 seconds\nαñ«αñ╣αñ┐αñ▓αñ╛αñôαñé αñ¬αñ░ αñàαññαÑìαñ»αñ╛αñÜαñ╛αñ░, αñ¼αÑçαñ░αÑïαñ£αñùαñ╛αñ░αÑÇ αñöαñ░ αñ«αñ╣αñéαñùαñ╛αñê αñòαñ╛ αñ╡αñ┐αñ░αÑïαñºαÑñ αñ¼αñ┐αñ╣αñ╛αñ░ αñ«αÑçαñé αñåαñ£ αñåαñ░αñ£αÑçαñíαÑÇ αñòαñ░αÑçαñùαÑÇ αñ░αñ╛αñ£αÑìαñ»αñ╡αÑìαñ»αñ╛αñ¬αÑÇ αñ¬αÑìαñ░αñªαñ░αÑìαñ╢αñ¿αÑñ\n8:52\n8 minutes, 52 seconds\nαñ¼αñ┐αñ╣αñ╛αñ░ αñòαÑêαñ¼αñ┐αñ¿αÑçαñƒ αñòαÑÇ αñ¼αÑêαñáαñò αñåαñ£ αñ╣αÑïαñ¿αÑÇ αñ╣αÑêαÑñ αñ¬αñƒαñ¿αñ╛ αñ«αÑçαñé αñ╕αÑÇαñÅαñ« αñ╕αñ«αÑìαñ░αñ╛αñƒ αñÜαÑîαñºαñ░αÑÇ αñòαÑÇ αñàαñºαÑìαñ»αñòαÑìαñ╖αññαñ╛ αñ«αÑçαñé αñ«αÑÇαñƒαñ┐αñéαñù αñ╣αÑïαñùαÑÇαÑñ αñòαñê αñàαñ╣αñ« αñ½αÑêαñ╕αñ▓αÑïαñé αñ¬αñ░ αñåαñ£ αñ▓αñù αñ╕αñòαññαÑÇ αñ╣αÑê αñ«αÑüαñ░αÑñ\n9:02\n9 minutes, 2 seconds\nαñ¬αñéαñ£αñ╛αñ¼ αñ«αÑçαñé αñºαñ╛αñ░αÑìαñ«αñ┐αñò αñ«αÑüαñªαÑìαñªαÑïαñé αñ¬αñ░ αñùαñ«αñ╛αñê αñ░αñ╛αñ£αñ¿αÑÇαññαñ┐αÑñ αñ¡αñùαñ╡αñéαññ αñ«αñ╛αñ¿ αñ¿αÑç αñòαñ╣αñ╛ αñ╕αñ┐αñ»αñ╛αñ╕αÑÇ αñåαñòαñ╛αñôαñé αñòαÑç αñçαñ╢αñ╛αñ░αÑç αñ¬αñ░ αñ¼αñªαñ¿αñ╛αñ« αñòαñ░αñ¿αÑç αñòαÑÇ αñòαÑÇ αñ£αñ╛ αñ░αñ╣αÑÇ αñ╣αÑê αñòαÑïαñ╢αñ┐αñ╢ αñëαñÜαÑìαñÜ αñºαñ╛αñ░αÑìαñ«αñ┐αñò αñ╕αÑìαñÑαñ╛αñ¿αÑïαñé αñ¬αñ░ αñ¼αÑêαñáαÑç αñ▓αÑïαñùαÑïαñé αñòαÑç αñªαÑìαñ╡αñ╛αñ░αñ╛αÑñ\n9:15\n9 minutes, 15 seconds\n18 αñ£αÑéαñ¿ αñòαÑï αñòαñ░αÑìαñ¿αñ╛αñƒαñòαñ╛ αñ╡αñ┐αñºαñ╛αñ¿ αñ¬αñ░αñ┐αñ╖αñª αñòαñ╛ αñÜαÑüαñ¿αñ╛αñ╡ αñ╣αÑïαñùαñ╛αÑñ αñ╕αÑç αñ╢αÑüαñ░αÑé αñ╣αÑüαñê αñ░αñ┐αñ╕αÑïαñ░αÑìαñƒ αñ¬αÑëαñ▓αñ┐αñƒαñ┐αñòαÑìαñ╕αÑñ\n9:20\n9 minutes, 20 seconds\nαñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñ¿αÑç αñ╡αñ┐αñºαñ╛αñ»αñòαÑïαñé αñòαÑï αñ░αñ┐αñ╕αÑïαñ░αÑìαñƒ αñ«αÑçαñé αñ░αñûαñ¿αÑç αñòαñ╛ αñ½αÑêαñ╕αñ▓αñ╛ αñ▓αñ┐αñ»αñ╛ αñ╣αÑêαÑñ\n9:27\n9 minutes, 27 seconds\nαñ¿αÑìαñ»αÑéαñ£αñ╝ αñ«αÑçαñé αñàαñ¼ αñ╡αñòαÑìαññ αñ╣αÑï αñÜαñ▓αñ╛ αñ╣αÑê αñªαÑçαñ╢ αñòαÑÇ αñ¼αñíαñ╝αÑÇ αñûαñ¼αñ░αÑïαñé αñòαñ╛αÑñ 21 αñ£αÑéαñ¿ αñòαÑï αñ╣αÑïαñ¿αÑç αñ╡αñ╛αñ▓αÑÇ αñªαÑïαñ¼αñ╛αñ░αñ╛ αñ¿αÑÇαñƒ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛ αñòαÑï αñ▓αÑçαñòαñ░ αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñòαÑç αññαñùαñíαñ╝αÑç αñçαñéαññαñ£αñ╛αñ« αñòαñ┐αñÅ αñ£αñ╛ αñ░αñ╣αÑç αñ╣αÑêαñéαÑñ αññαÑï αñ╡αñ╣αÑÇαñé αñ¿αÑÇαñƒ αñòαÑÇ αññαÑêαñ»αñ╛αñ░αÑÇ αñòαñ░\n9:35\n9 minutes, 35 seconds\nαñ░αñ╣αÑÇ αñªαÑï αñ¢αñ╛αññαÑìαñ░αÑïαñé αñ¿αÑç αñ╕αÑüαñ╕αñ╛αñçαñí αñòαñ░ αñ▓αñ┐αñ»αñ╛ αñ╣αÑêαÑñ αñëαñºαñ░ αñ░αñ╛αñ╣αÑüαñ▓ αñòαÑç αñ¢αñ╛αññαÑìαñ░αÑïαñé αñòαÑç αñ╕αñ╛αñÑ αñ╕αñéαñ╡αñ╛αñª αñòαñ╛αñ░αÑìαñ»αñòαÑìαñ░αñ« αñòαÑï αñ▓αÑçαñòαñ░ αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñ¿αÑç αñ¿αñ┐αñ╢αñ╛αñ¿αñ╛ αñ╕αñ╛αñºαñ╛ αñ╣αÑêαÑñ αñåαñ¬αñòαÑï αñªαñ┐αñûαñ╛ αñªαÑçαññαÑç αñ╣αÑêαñé αñ¬αÑéαñ░αñ╛ αñàαñ¬αñíαÑçαñƒ αñ½αñƒαñ╛αñ½αñƒαÑñ\n9:47\n9 minutes, 47 seconds\nαñ¬αÑçαñ¬αñ░ αñ▓αÑÇαñò αñôαñÅαñ╕αñÅαñ« αñ╕αñ┐αñ╕αÑìαñƒαñ« αñ¼αÑçαñ░αÑïαñ£αñùαñ╛αñ░αÑÇ αñòαñ╛ αñ«αÑüαñªαÑìαñªαñ╛ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñòαñ╛ αñªαÑçαñ╢αñ╡αÑìαñ»αñ╛αñ¬αÑÇ αñàαñ¡αñ┐αñ»αñ╛αñ¿ αñåαñ£ αñòαÑïαñƒαñ╛ αñ«αÑçαñé αñ░αñ╛αñ╣αÑüαñ▓ αñ¢αñ╛αññαÑìαñ░ αñ╕αñ«αÑìαñ«αÑçαñ▓αñ¿ αñ«αÑçαñé αñ╕αñéαñ¼αÑïαñºαñ┐αññ αñòαñ░αÑçαñéαñùαÑçαÑñ\n9:57\n9 minutes, 57 seconds\nαñòαÑïαñƒαñ╛ αñ«αÑçαñé αñòαñ╛αñ░αÑìαñ»αñòαÑìαñ░αñ« αñ╕αÑç αñ¬αñ╣αñ▓αÑç αñ╣αñƒαñ╛αñÅ αñùαñÅ αñ░αñ╛αñ╣αÑüαñ▓ αñùαñ╛αñéαñºαÑÇ αñòαÑç αñ¬αÑïαñ╕αÑìαñƒαñ░αÑìαñ╕ αñ¿αñùαñ░ αñ¿αñ┐αñùαñ« αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñ¼αñ┐αñ¿αñ╛ αñçαñ£αñ╛αñ£αññ αñòαÑç αñ╣αÑÇ αñ░αñ╛αñ╣αÑüαñ▓ αñùαñ╛αñéαñºαÑÇ αñòαÑç αñ¬αÑïαñ╕αÑìαñƒαñ░αÑìαñ╕ αñ▓αñùαñ╛ αñªαñ┐αñÅ αñùαñÅ αñÑαÑçαÑñ\n10:08\n10 minutes, 8 seconds\nαñ░αñ╛αñ╣αÑüαñ▓ αñòαÑç αñ¬αÑïαñ╕αÑìαñƒαñ░ αñ╣αñƒαñ╛αñ¿αÑç αñ¬αñ░ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñ╕αñ░αñòαñ╛αñ░ αñòαÑÇ αñàαñ¼ αñ¿αÑÇαñéαñª αñëαñíαñ╝ αñùαñê αñ╣αÑêαÑñ\n10:13\n10 minutes, 13 seconds\nαñùαñ╣αñ▓αÑïαññ αñ¿αÑç αñòαñ╣αñ╛ αñ¢αñ╛αññαÑìαñ░αÑïαñé αñòαÑç αñòαñ╛αñ░αÑìαñ»αñòαÑìαñ░αñ« αñ«αÑçαñé αñ£αñ╛αñ¿αÑç αñòαÑï αñ▓αÑçαñòαñ░ αñôαñ« αñ¼αñ┐αñ░αñ▓αñ╛ αñòαÑç αñæαñ½αñ┐αñ╕ αñ╕αÑç αñòαÑïαñÜαñ┐αñéαñù αñ╕αñéαñ╕αÑìαñÑαñ╛αñ¿αÑïαñé αñòαÑï αñªαÑÇ αñ£αñ╛ αñ░αñ╣αÑÇ αñ╣αÑê αñºαñ«αñòαÑÇαÑñ\n10:21\n10 minutes, 21 seconds\nαñòαñ╛αñ░αÑìαñ»αñòαÑìαñ░αñ« αñ╕αÑç αñ¬αñ╣αñ▓αÑç αñ£αñ»αñéαññαÑÇ αñòαÑç αñ¿αñ╛αñ« αñ░αñ╛αñ╣αÑüαñ▓ αñùαñ╛αñéαñºαÑÇ αñòαñ╛ αñ╕αñéαñªαÑçαñ╢αÑñ αñòαñ╣αñ╛ αñ»αÑüαñ╡αñ╛αñôαñé αñòαñ╛ αñ¡αñ╡αñ┐αñ╖αÑìαñ» αñ╕αÑüαñ░αñòαÑìαñ╖αñ┐αññ αñòαñ░αñ¿αñ╛ αñ╕αñ░αñòαñ╛αñ░ αñòαÑÇ αñ╣αÑê αñ£αñ┐αñ«αÑìαñ«αÑçαñªαñ╛αñ░αÑÇαÑñ\n10:27\n10 minutes, 27 seconds\nαñ▓αÑçαñòαñ┐αñ¿ αñ╕αñ░αñòαñ╛αñ░ αñ»αÑüαñ╡αñ╛αñôαñé αñòαÑç αñ╕αñ¬αñ¿αÑç αññαÑïαñíαñ╝ αñ░αñ╣αÑÇ αñ╣αÑêαÑñ\n10:33\n10 minutes, 33 seconds\nαñ¢αñ╛αññαÑìαñ░αÑïαñé αñòαÑç αñ╕αñéαñ╡αñ╛αñª αñòαñ╛αñ░αÑìαñ»αñòαÑìαñ░αñ« αñòαÑï αñ▓αÑçαñòαñ░ αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñ¿αÑç αñ░αñ╛αñ╣αÑüαñ▓ αñ¬αñ░ αñ╕αñ╛αñºαñ╛ αñ╣αÑê αñ¿αñ┐αñ╢αñ╛αñ¿αñ╛αÑñ αñªαÑîαñ░αÑç αñòαÑï αñ¼αññαñ╛αñ»αñ╛ αñ░αñ╛αñ£αñ¿αÑÇαññαñ┐αñò αñòαñ╛αñ░αÑìαñ»αñòαÑìαñ░αñ«αÑñ αñÿαñ¿αñ╢αÑìαñ»αñ╛αñ« αññαñ┐αñ╡αñ╛αñ░αÑÇ αñ¼αÑïαñ▓αÑç αñ¬αÑçαñ¬αñ░ αñ▓αÑÇαñò αñ¿αñ╣αÑÇαñé αñ╣αÑüαñåαÑñ\n10:43\n10 minutes, 43 seconds\nαñ¿αÑÇαñƒ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛ αñªαÑïαñ¼αñ╛αñ░αñ╛ αñòαñ░αñ╛αñ¿αÑç αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñ»αñ╛αñÜαñ┐αñòαñ╛αÑñ αñåαñ£ αñ╕αÑüαñ¬αÑìαñ░αÑÇαñ« αñòαÑïαñ░αÑìαñƒ αñ«αÑçαñé αñ╕αÑüαñ¿αñ╡αñ╛αñê αñ╣αÑïαñùαÑÇαÑñ αñòαñ╣αñ╛ αñùαñ»αñ╛ αñ╣αÑê αñòαñ┐ αñòαÑüαñ¢ αñ▓αÑïαñùαÑïαñé αñöαñ░ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛ αñòαÑçαñéαñªαÑìαñ░αÑïαñé αññαñò αñ╕αÑÇαñ«αñ┐αññ αñÑαÑÇ αñ»αñ╣ αñùαñíαñ╝αñ¼αñíαñ╝αÑÇαÑñ\n10:55\n10 minutes, 55 seconds\nαñ¿αÑÇαñƒ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛ αñòαÑï αñ▓αÑçαñòαñ░ αñÅαññαñ┐αñ»αñ╛αññαñ¿ αñƒαÑçαñ▓αÑÇαñùαÑìαñ░αñ╛αñ« αñ¬αñ░ αñòαñ╛αñ░αñ╡αñ╛αñê αñòαÑÇ αñùαñê αñ╣αÑêαÑñ αñòαñéαñ¬αñ¿αÑÇ αñòαÑç αñ╕αÑÇαñêαñô αñ¼αÑïαñ▓αÑç αñ½αÑêαñ╕αñ▓αÑç αñ╕αÑç αñ»αÑéαÑ¢αñ░αÑìαñ╕ αñ¬αñ░αÑçαñ╢αñ╛αñ¿αÑñ αñ¬αÑçαñ¬αñ░ αñ▓αÑÇαñò αñòαñ░αñ¿αÑç αñ╡αñ╛αñ▓αÑç αñàαñ¼ αñªαÑéαñ╕αñ░αÑç αñÅαñ¬αÑìαñ▓αÑÇαñòαÑçαñ╢αñ¿ αñòαñ╛ αñçαñ╕αÑìαññαÑçαñ«αñ╛αñ▓ αñòαñ░αÑçαñéαñùαÑçαÑñ\n11:08\n11 minutes, 8 seconds\nαñ«αñªαÑüαñ░αñê αñ«αÑçαñé αñ¿αÑÇαñƒ αñ¬αÑçαñ¬αñ░ αñ▓αÑç αñ£αñ╛ αñ░αñ╣αÑÇ αñùαñ╛αñíαñ╝αÑÇ αñ░αÑüαñòαñ¿αÑç αñ╕αÑç αñ╣αñíαñ╝αñòαñéαñ¬ αñ«αñÜ αñùαñ»αñ╛αÑñ αññαÑüαñ░αñéαññ αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñ¼αñ▓αÑïαñé αñ¿αÑç αñ«αÑïαñ░αÑìαñÜαñ╛ αñ╕αñéαñ¡αñ╛αñ▓αñ╛ αñöαñ░ αñ¬αÑüαñ▓αñ┐αñ╕ αñòαÑÇ αñùαñ╛αñíαñ╝αÑÇ αñ«αÑçαñé αñûαñ░αñ╛αñ¼αÑÇ αñòαÑç αñ¼αñ╛αñª αñ»αñ╣ αñòαñ╛αñ½αñ┐αñ▓αñ╛ αñ░αÑüαñò αñùαñ»αñ╛ αñÑαñ╛αÑñ\n11:20\n11 minutes, 20 seconds\nαñ░αñ╛αñ£αñ╕αÑìαñÑαñ╛αñ¿ αñòαÑç αñ╕αÑÇαñòαñ░ αñ«αÑçαñé αñ¿αÑÇαñƒ αñàαñ¡αÑìαñ»αñ░αÑìαñÑαÑÇ αñ¿αÑç αñåαññαÑìαñ«αñ╣αññαÑìαñ»αñ╛ αñòαñ░ αñ▓αÑÇαÑñ αñ½αÑìαñ▓αÑêαñƒ αñ«αÑçαñé αñ½αñéαñªαÑç αñ╕αÑç αñ▓αñƒαñòαñ╛ αñ╣αÑüαñå αñ«αñ┐αñ▓αñ╛ αñ╢αñ╡αÑñ αñ¬αñ░αñ┐αñ╡αñ╛αñ░ αñòαÑç αñ╕αñ╛αñÑ αñ░αñ╣αñòαñ░ αñòαñ░ αñ░αñ╣αñ╛ αñÑαñ╛ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛ αñòαÑÇ αññαÑêαñ»αñ╛αñ░αÑÇαÑñ\n11:32\n11 minutes, 32 seconds\nαñªαÑçαñ╣αñ░αñ╛αñªαÑéαñ¿ αñ«αÑçαñé αñ¿αÑÇαñƒ αñàαñ¡αÑìαñ»αñ░αÑìαñÑαÑÇ αñ¿αÑç αñ▓αñùαñ╛αñê αñ½αñ╛αñéαñ╕αÑÇαÑñ\n11:34\n11 minutes, 34 seconds\nαñ▓αñéαñ¼αÑç αñ╕αñ«αñ» αñ╕αÑç αñ¢αñ╛αññαÑìαñ░αñ╛ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛ αñòαÑÇ αññαÑêαñ»αñ╛αñ░αÑÇ αñòαñ░ αñ░αñ╣αÑÇ αñÑαÑÇαÑñ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛ αñ«αÑçαñé αñ╕αñ½αñ▓αññαñ╛ αñ¿αñ╣αÑÇαñé αñ«αñ┐αñ▓αñ¿αÑç αñ╕αÑç αñ¬αñ░αÑçαñ╢αñ╛αñ¿ αñÑαÑÇαÑñ\n11:42\n11 minutes, 42 seconds\nαñ»αÑéαñ¬αÑÇ αñ«αÑçαñé αñ¿αÑÇαñƒ αñàαñ¡αÑìαñ»αñ░αÑìαñÑαñ┐αñ»αÑïαñé αñòαÑï αñ¼αñ╕ αñòαñ┐αñ░αñ╛αñÅ αñ«αÑçαñé αñ«αñ┐αñ▓αÑçαñùαñ╛αÑñ αñàαñ¼ 50% αñòαñ╛ 50% αñòαÑÇ αñ¢αÑéαñƒ αñ«αñ┐αñ▓αÑçαñùαÑÇαÑñ\n11:48\n11 minutes, 48 seconds\nαñ»αÑïαñùαÑÇ αñ╕αñ░αñòαñ╛αñ░ αñ¿αÑç αñ▓αñ┐αñ»αñ╛ αñ¼αñíαñ╝αñ╛ αñ½αÑêαñ╕αñ▓αñ╛αÑñ 21 αñ£αÑéαñ¿ αñòαÑï αñ╣αÑïαñùαÑÇ αñ¿αÑÇαñƒ αñòαÑÇ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛αÑñ\n11:56\n11 minutes, 56 seconds\nαñ¼αñ┐αñ╣αñ╛αñ░ αñ«αÑçαñé αñ«αñºαÑìαñ» αñ¿αñ┐αñ╖αÑçαñº αñ╡αñ┐αñ¡αñ╛αñù αñòαÑÇ αñòαñ╛αñéαñ╕αÑìαñƒαÑçαñ¼αñ▓ αñ¡αñ░αÑìαññαÑÇ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛αÑñ αñÅαñùαÑìαñ£αñ╛αñ« αñòαñ╛ αñåαñ£ αñªαÑéαñ╕αñ░αñ╛ αñªαñ┐αñ¿ αñ╣αÑêαÑñ αñªαÑï αñ¬αñ╛αñ▓αñ┐αñ»αÑïαñé αñ«αÑçαñé αñ»αñ╣ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛ αñ╣αÑï αñ░αñ╣αÑÇ αñ╣αÑêαÑñ\n12:06\n12 minutes, 6 seconds\nαñ¼αñ┐αñ╣αñ╛αñ░ αñ«αÑçαñé αñ¢αñ╛αññαÑìαñ░αÑïαñé αñ¿αÑç αñ▓αñùαñ╛αñÅ αñ╣αÑêαñé αñàαñºαÑéαñ░αÑç αñçαñéαññαñ£αñ╛αñ« αñòαÑç αñåαñ░αÑïαñ¬ αñòαñ╣αñ╛ αñòαñ┐ αñƒαÑìαñ░αÑçαñ¿ αñ«αÑçαñé αñÿαÑüαñ╕αñ¿αÑç αññαñò αñòαÑÇ αñ£αñùαñ╣ αñ¿αñ╣αÑÇαñé αñÑαÑÇαÑñ αñàαñºαñ┐αñòαñ╛αñ░αÑÇ αñàαñºαñ┐αñòαñ╛αñ░αñ┐αñ»αÑïαñé αñ¿αÑç αñòαñ╣αñ╛ αñ╣αÑê αñòαñ┐ αñàαññαñ┐αñ░αñ┐αñòαÑìαññ αñƒαÑìαñ░αÑçαñ¿αÑçαñé αñÜαñ▓αñ╛αñê αñ£αñ╛ αñ░αñ╣αÑÇ αñ╣αÑêαÑñ\n12:18\n12 minutes, 18 seconds\nαñ¼αñ┐αñ╣αñ╛αñ░ αñ«αÑçαñé αñ¬αÑüαñ▓αñ┐αñ╕ αñ¡αñ░αÑìαññαÑÇ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛αñôαñé αñòαÑï αñ▓αÑçαñòαñ░ αñ░αÑçαñ▓αñ╡αÑç αñ╕αÑìαñƒαÑçαñ╢αñ¿ αñ¬αñ░ αñ¡αñ╛αñ░αÑÇ αñ¡αÑÇαñíαñ╝ αñ¬αÑìαñ▓αÑçαñƒαñ½αñ╛αñ░αÑìαñ« αñ¬αñ░ αñ¿αñ╣αÑÇαñé αñ¼αñÜαÑÇ αñ¬αñ╛αñéαñ╡ αñ░αñûαñ¿αÑç αññαñò αñòαÑÇ αñ£αñùαñ╣αÑñ\n12:23\n12 minutes, 23 seconds\nαñàαñ¡αÑìαñ»αñ░αÑìαñÑαñ┐αñ»αÑïαñé αñ¿αÑç αñƒαÑìαñ░αÑçαñ¿αÑïαñé αñòαÑÇ αñòαñ«αÑÇ αñöαñ░ αñàαñ╡αÑìαñ»αñ╡αñ╕αÑìαñÑαñ╛αñôαñé αñòαÑÇ αñ╢αñ┐αñòαñ╛αñ»αññ αñòαÑÇ αñ╣αÑêαÑñ\n12:30\n12 minutes, 30 seconds\nαñ«αñúαñ┐αñ¬αÑüαñ░ αñòαÑÇ αñ░αñ╛αñ£αñºαñ╛αñ¿αÑÇ αñçαñéαñ½αñ╛αñ▓ αñ«αÑçαñé αñ½αñ┐αñ░ αñ╕αÑç αññαñ¿αñ╛αñ╡ αñ╣αÑï αñùαñ»αñ╛αÑñ αñ¬αÑìαñ░αñªαñ░αÑìαñ╢αñ¿αñòαñ╛αñ░αñ┐αñ»αÑïαñé αñ¿αÑç αñ¬αÑìαñ░αñ«αÑüαñû αñ╕αÑìαñ╡αñ╛αñ╕αÑìαñÑαÑìαñ» αñ╕αñéαñ╕αÑìαñÑαñ╛αñ¿ αñ░αñ┐αñ«αÑìαñ╕ αñòαÑï αñÿαÑçαñ░αñ╛αÑñ αñàαñ╕αÑìαñ¬αññαñ╛αñ▓ αñ«αÑçαñé αññαÑÇαñ¿ αñòαÑüαñòαÑÇ αñ»αÑüαñ╡αñòαÑïαñé αñòαÑï αñ¡αñ░αÑìαññαÑÇ αñòαñ░αñ¿αÑç αñòαñ╛ αñ╡αñ┐αñ░αÑïαñº αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛αÑñ\n12:41\n12 minutes, 41 seconds\nαñçαñéαñ½αñ╛αñ▓ αñ«αÑçαñé αññαñ¿αñ╛αñ╡ αñ¼αñóαñ╝αññαñ╛ αñ╣αÑüαñå αñªαÑçαñû αñ¬αÑüαñ▓αñ┐αñ╕ αñ½αÑïαñ░αÑìαñ╕ αñòαÑÇ αññαÑêαñ¿αñ╛αññαÑÇαÑñ αñ¡αÑÇαñíαñ╝ αñòαÑï αñòαñ╛αñ¼αÑé αñòαñ░αñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñåαñ£ αñùαÑêαñ╕ αñòαÑç αñùαÑïαñ▓αÑç αñªαñ╛αñùαÑçαÑñ\n12:47\n12 minutes, 47 seconds\nαñ¬αÑìαñ░αñªαñ░αÑìαñ╢αñ¿αñòαñ╛αñ░αÑÇ αñòαñ░ αñ░αñ╣αÑç αñ«αñ╛αñ«αñ▓αÑç αñòαÑÇ αñ¿αñ┐αñ╖αÑìαñ¬αñòαÑìαñ╖ αñ£αñ╛αñéαñÜ αñòαÑÇ αñ«αñ╛αñéαñùαÑñ\n12:52\n12 minutes, 52 seconds\nαñ░αñ╛αñ« αñ╣αñ╛αñ╡αÑÇ αñòαÑï αñ▓αÑçαñòαñ░ αñÅαñ╕αñåαñêαñƒαÑÇ αñòαÑÇ αñ£αñ╛αñéαñÜ αñ▓αñùαñ╛αññαñ╛αñ░ αñ£αñ╛αñ░αÑÇ αñ╣αÑêαÑñ αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñ╕αñ┐αñ»αñ╛αñ╕αññ αñ¡αÑÇ αñ£αÑïαñ░αÑïαñé αñ¬αñ░ αñ╣αÑêαÑñ αñ¬αÑéαñ░αÑÇ αñûαñ¼αñ░ αñåαñ¬αñòαÑï αñªαñ┐αñûαñ╛ αñªαÑçαññαÑç αñ╣αÑêαñé αñ¿αÑîαñ╕αÑçαñ╕αñ┐αñò αñ¿αÑìαñ»αÑéαñ£αñ╝ αñ«αÑçαñé αñ½αñƒαñ╛αñ½αñƒαÑñ\n13:02\n13 minutes, 2 seconds\nαñ░αñ╛αñ« αñ«αñéαñªαñ┐αñ░ αñÜαñóαñ╝αñ╛αñ╡αñ╛ αñÜαÑïαñ░αÑÇ αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñÅαñ╕αñåαñêαñƒαÑÇ αñòαÑÇ αñ£αñ╛αñéαñÜ αñ£αñ╛αñ░αÑÇ αñ╣αÑêαÑñ αñ«αñéαñùαñ▓αñ╡αñ╛αñ░ αñòαÑï αñ«αñéαñªαñ┐αñ░ αñ¬αñ░αñ┐αñ╕αñ░ αñ«αÑçαñé 40 αñ╕αÑç αñàαñºαñ┐αñò αñ¼αÑêαñéαñò αñòαñ░αÑìαñ«αñ┐αñ»αÑïαñé αñ╕αÑç αñ¬αÑéαñ¢αññαñ╛αñ¢ αñòαÑÇ αñùαñêαÑñ αñ£αÑüαñƒαñ╛αñê αñ¬αÑêαñ╕αÑïαñé αñòαÑç αñ░αñûαñ░αñûαñ╛αñ╡ αñ£αÑüαñíαñ╝αÑÇ αñ£αñ╛αñ¿αñòαñ╛αñ░αÑÇαÑñ\n13:15\n13 minutes, 15 seconds\nαñÜαñóαñ╝αñ╛αñ╡αñ╛ αñÜαÑïαñ░αÑÇ αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñ╢αñ┐αñòαñ╛αñ»αññ αñªαÑçαñòαñ░ αñÅαñ½αñåαñêαñåαñ░ αñªαñ░αÑìαñ£ αñòαñ░αñ¿αÑç αñòαÑÇ αñ«αñ╛αñéαñùαÑñ αñ╕αñéαññαÑïαñ╖ αñªαÑüαñ¼αÑç αñ¿αñ╛αñ«αñò αñ╡αÑìαñ»αñòαÑìαññαñ┐ αñ¿αÑç αñªαÑÇ αñ╢αñ┐αñòαñ╛αñ»αññαÑñ αñòαñ╣αñ╛ αñÅαñ╕αñåαñêαñƒαÑÇ αñ¬αñ░ αñ¡αñ░αÑïαñ╕αñ╛ αñ¿αñ╣αÑÇαñé αñ╣αÑêαÑñ αñªαñ¼αñ╛αñ╡ αñ«αÑçαñé αñå αñ£αñ╛αñÅαñùαÑÇ αñƒαÑÇαñ«αÑñ\n13:28\n13 minutes, 28 seconds\nαñÜαñóαñ╝αñ╛αñ╡αñ╛ αñÜαÑïαñ░αÑÇ αñòαÑç αñ«αñ╛αñ«αñ▓αÑç αñ¬αñ░ αñàαñûαñ┐αñ▓αÑçαñ╢ αñ»αñ╛αñªαñ╡ αñ¼αÑïαñ▓αÑç αñ¬αÑìαñ░αñ¡αÑü αñ╢αÑìαñ░αÑÇ αñ░αñ╛αñ« αñòαÑç αñ░αñ╛αñ╕αÑìαññαÑç αñ¬αñ░ αñÜαñ▓αñ¿αÑç αñ╡αñ╛αñ▓αÑç αñ¼αñ╣αÑüαññ αñªαÑüαñûαÑÇ αñ╣αÑêαñéαÑñ αñ£αÑï αñ¡αñùαñ╡αñ╛αñ¿ αñòαÑÇ αñÅαñ½αñåαñêαñåαñ░ αñ▓αñ┐αñûαÑÇ αñ£αñ╛αñÅαñùαÑÇ αñëαñ╕αñòαñ╛ αñòαÑìαñ»αñ╛ αñòαñ░αÑïαñùαÑç αñåαñ¬?\n13:40\n13 minutes, 40 seconds\nαñ»αÑéαñ¬αÑÇ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñàαñºαÑìαñ»αñòαÑìαñ╖ αñàαñ£αñ» αñ░αñ╛αñ» αñ¿αÑç αñòαñ╣αñ╛ αñ¡αñùαñ╡αñ╛αñ¿ αñòαÑç αñ¿αñ╛αñ« αñ¬αñ░ αñ¬αñ╣αñ▓αÑç αñÜαÑïαñ░αÑÇ αñòαñ┐αñ»αñ╛ αñÜαñéαñªαñ╛αÑñ αñ╣αñ╛αñê αñòαÑïαñ░αÑìαñƒ αñòαÑç αñ╕αñ┐αñéαñù αñ£αñ£ αñ╕αÑç αñ╣αÑïαñ¿αñ╛ αñÜαñ╛αñ╣αñ┐αñÅ αñ╕αñ«αñ»αñ¼αñªαÑìαñº αñ£αñ╛αñéαñÜαÑñ\n13:52\n13 minutes, 52 seconds\n19 αñ£αÑéαñ¿ αñòαÑï αñ»αÑéαñ¬αÑÇ αñòαÑç αñ«αÑüαñûαÑìαñ»αñ«αñéαññαÑìαñ░αÑÇ αñ»αÑïαñùαÑÇ αñ£αñ╛ αñ╕αñòαññαÑç αñ╣αÑêαñé αñàαñ»αÑïαñºαÑìαñ»αñ╛αÑñ αñ»αÑéαñ¬αÑÇ αñòαÑç αñ«αñéαññαÑìαñ░αÑÇ αñôαñ¬αÑÇ αñ░αñ╛αñ£αñ¡αñ░ αñ¼αÑïαñ▓αÑç αñ╡αñ┐αñ¬αñòαÑìαñ╖ αñ╕αñ░αñòαñ╛αñ░ αñ¬αñ░ αñ▓αñùαñ╛ αñ░αñ╣αñ╛ αñåαñ░αÑïαñ¬αÑñ\n13:58\n13 minutes, 58 seconds\nαñƒαÑìαñ░αñ╕αÑìαñƒ αñòαÑÇ αñªαÑçαñûαñ░αÑçαñû αñ«αÑçαñé αñ╣αÑïαññαñ╛ αñ╣αÑê αñ«αñéαñªαñ┐αñ░ αñòαñ╛ αñòαñ╛αñ░αÑìαñ»αÑñ\n14:04\n14 minutes, 4 seconds\nαñ░αñ╛αñ« αñ«αñéαñªαñ┐αñ░ αñòαñ╛ αñÜαñóαñ╝αñ╛αñ╡αñ╛ αñÜαÑïαñ░αÑÇ αñòαÑï αñ▓αÑçαñòαñ░ αñ╕αÑüαñ░αÑìαñûαñ┐αñ»αÑïαñé αñ«αÑçαñé αñƒαñ┐αñ¿αÑìαñ¿αÑé αñ»αñ╛αñªαñ╡ αñòαñ╛ αñ¿αñ╛αñ« αñ¬αñ░αñ┐αñ╡αñ╛αñ░ αñ╡αñ╛αñ▓αÑç αñ¿αÑç αñåαñ░αÑïαñ¬αÑïαñé αñòαÑï αñ¼αññαñ╛αñ»αñ╛ αñ¿αñ┐αñ░αñ╛αñºαñ╛αñ░ αñòαñ╣αñ╛ αñòαñ┐ αñçαñ╕αñòαÑç αñ¬αÑÇαñ¢αÑç αñçαñ╕αñòαÑç αñ¬αÑÇαñ¢αÑç αñòαÑïαñê αñ╕αñ╛αñ£αñ┐αñ╢ αñ╣αÑêαÑñ\n14:20\n14 minutes, 20 seconds\nαñÜαñóαñ╝αñ╛αñ╡αñ╛ αñÜαÑïαñ░αÑÇ αñ¬αñ░ αñ¬αÑéαñ░αÑìαñ╡ αñ╕αñ╛αñéαñ╕αñª αñ╡αñ┐αñ¿αñ» αñòαñƒαñ┐αñ╣αñ╛αñ░ αñòαÑç αññαñ▓αÑìαñû αññαÑçαñ╡αñ░ αñ¿αñ£αñ░ αñå αñ░αñ╣αÑç αñ╣αÑêαñéαÑñ αñòαñ╣αñ╛ αñòαñ┐ αñÅαñ╕αñåαñêαñƒαÑÇ αñ£αñ╛αñéαñÜ αñ╕αÑç αñ╕αñ╛αñ½ αñ╣αÑï αñ£αñ╛αñÅαñùαÑÇ αñ¬αÑéαñ░αÑÇ αññαñ╕αÑìαñ╡αÑÇαñ░αÑñ\n14:34\n14 minutes, 34 seconds\nαñÜαñóαñ╝αñ╛αñ╡αñ╛ αñÜαÑïαñ░αÑÇ αñòαÑç αñ«αÑüαñªαÑìαñªαÑç αñ¬αñ░ αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñ╕αñ╛αñéαñ╕αñª αñòαñ░αñú αñ¡αÑéαñ╖αñú αñ╕αñ┐αñéαñ╣ αñ¿αÑç αñòαñ╣αñ╛ αñ░αñ╛αñ« αñ«αñéαñªαñ┐αñ░ αñ¼αñ¿αñ¿αÑç αñ«αÑçαñé αñ¡αñ▓αÑç αñ╣αÑÇ αñ╕αñ«αñ» αñ▓αñùαñ╛ αñ▓αÑçαñòαñ┐αñ¿ αñçαñ╕ αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñÅαñ½αñåαñêαñåαñ░ αñªαñ░αÑìαñ£ αñ╣αÑïαñ¿αÑç αñ«αÑçαñé αñ¿αñ╣αÑÇαñé αñ╣αÑïαñùαÑÇ αñòαÑïαñê αñªαÑçαñ░αÑÇαÑñ\n14:45\n14 minutes, 45 seconds\nαñ░αñ╛αñ« αñ«αñéαñªαñ┐αñ░ αñÜαñóαñ╝αñ╛αñ╡αÑç αñòαÑç αñÜαÑïαñ░αÑÇ αñ╣αÑïαñ¿αÑç αñòαÑç αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñàαñ»αÑïαñºαÑìαñ»αñ╛ αñ╕αÑç αñ╕αñ«αñ╛αñ£αñ╡αñ╛αñªαÑÇ αñ¬αñ╛αñ░αÑìαñƒαÑÇ αñòαÑç αñ╕αñ╛αñéαñ╕αñª αñàαñ╡αñªαÑçαñ╢ αñ¬αÑìαñ░αñ╕αñ╛αñª αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñ╕αÑüαñ¬αÑìαñ░αÑÇαñ« αñòαÑïαñ░αÑìαñƒ αñòαÑÇ αñ¿αñ┐αñùαñ░αñ╛αñ¿αÑÇ αñ«αÑçαñé αñ╣αÑïαñ¿αÑÇ αñÜαñ╛αñ╣αñ┐αñÅ αñ£αñ╛αñéαñÜαÑñ\n14:56\n14 minutes, 56 seconds\nαñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñ¿αÑçαññαñ╛ αñåαñºαÑÇ αñ░αñéαñ£αñ¿ αñÜαÑîαñºαñ░αÑÇ αñ¿αÑç αñòαñ╣αñ╛ αñ«αñéαñªαñ┐αñ░ αñòαÑç αñ¬αÑêαñ╕αÑïαñé αñ«αÑçαñé αñ╣αÑï αñ░αñ╣αÑÇ αñ╣αÑê αñùαñíαñ╝αñ¼αñíαñ╝αÑÇ αñòαÑìαñ»αñ╛ αñ¼αñÜαÑÇ αñòαñ╛αñ¿αÑéαñ¿ αñ╡αÑìαñ»αñ╡αñ╕αÑìαñÑαñ╛ αñòαÑÇ αñàαñ╣αñ«αñ┐αñ»αññ\n15:07\n15 minutes, 7 seconds\nαñöαñ░ αñåαñçαñÅ αñ¿αñ╛αñ╕αñ┐αñò αñ¿αÑìαñ»αÑéαñ£αñ╝ αñ«αÑçαñé αñ½αñƒαñ╛αñ½αñƒ αñåαñ¬αñòαÑï αñªαñ┐αñûαñ╛ αñªαÑçαññαÑç αñ╣αÑêαñé αñªαÑçαñ╢ αñòαÑç αñàαñ▓αñù-αñàαñ▓αñù αñ░αñ╛αñ£αÑìαñ»αÑïαñé αñ╕αÑç αñ£αÑüαñíαñ╝αÑÇ αñ¼αñíαñ╝αÑÇ αñûαñ¼αñ░αÑçαñéαÑñ\n15:15\n15 minutes, 15 seconds\nαñ«αñºαÑìαñ» αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñùαÑüαñ¿αñ╛ αñöαñªαÑìαñ»αÑïαñùαñ┐αñò αñòαÑìαñ╖αÑçαññαÑìαñ░ αñ«αÑçαñé αñ¬αñ╛αñçαñ¬ αñ½αÑêαñòαÑìαñƒαÑìαñ░αÑÇ αñ«αÑçαñé αñ¡αÑÇαñ╖αñú αñåαñù αñ▓αñù αñùαñêαÑñ Γé╣50 αñ▓αñ╛αñû αñ╕αÑç αñ£αÑìαñ»αñ╛αñªαñ╛ αñòαñ╛ αñ¿αÑüαñòαñ╕αñ╛αñ¿ αñ╣αÑüαñå αñ╣αÑêαÑñ αñ╢αÑëαñ░αÑìαñƒ αñ╕αñ░αÑìαñòαñ┐αñƒ αñòαÑç αñòαñ╛αñ░αñú αñåαñù αñ▓αñùαñ¿αÑç αñòαÑÇ αñåαñ╢αñéαñòαñ╛αÑñ\n15:26\n15 minutes, 26 seconds\nαñ¢αññαÑìαññαÑÇαñ╕αñùαñóαñ╝ αñòαÑç αñòαÑïαñ░αñ┐αñ»αñ╛ αñ«αÑçαñé αñÜαñ╛αñ░ αñ▓αÑïαñùαÑïαñé αñ«αÑçαñé αñòαÑï αñòαñ╛αñ░ αñ«αÑçαñé αñ¼αñéαñª αñòαñ░ αñåαñù αñ▓αñùαñ╛ αñªαÑÇ αñùαñêαÑñ αñÅαñò αñòαÑÇ αñ«αÑîαññ, αññαÑÇαñ¿ αñÿαñ╛αñ»αñ▓ αñ¼αññαñ╛αñÅ αñ£αñ╛ αñ░αñ╣αÑç αñ╣αÑêαñéαÑñ αñÜαñ╛αñ░ αñåαñ░αÑïαñ¬αÑÇ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░αÑñ αñ£αñ▓αññαÑÇ αñòαñ╛αñ░ αñ╕αÑç αñ¿αñ┐αñòαñ▓αñ¿αÑç αñòαÑÇ αñòαÑïαñ╢αñ┐αñ╢ αñòαÑç αñªαÑîαñ░αñ╛αñ¿ αñ¡αÑÇ αñåαñ░αÑïαñ¬αñ┐αñ»αÑïαñé αñ¿αÑç αñ╣αñ«αñ▓αñ╛ αñòαñ┐αñ»αñ╛ αñÑαñ╛αÑñ\n15:40\n15 minutes, 40 seconds\nαñëαññαÑìαññαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñ«αÑïαñªαÑÇαñ¬αÑüαñ░αñ« αñ«αÑçαñé αñÜαñ▓αññαÑÇ αñòαñ╛αñ░ αñ«αÑçαñé αñåαñù αñ▓αñù αñùαñêαÑñ αñòαñ╛αñ░ αñ╕αñ╡αñ╛αñ░ αñ▓αÑïαñùαÑïαñé αñ¿αÑç αñ╕αñ«αñ» αñ░αñ╣αññαÑç αñòαñ╛αñ░ αñ╕αÑç αñ¼αñ╛αñ╣αñ░ αñ¿αñ┐αñòαñ▓αñòαñ░ αñàαñ¬αñ¿αÑÇ αñ£αñ╛αñ¿ αñ¼αñÜαñ╛αñêαÑñ\n15:46\n15 minutes, 46 seconds\nαñ¬αñ▓αÑìαñ▓αñ╡αñ¬αÑüαñ░αñ« αñÑαñ╛αñ¿αñ╛ αñòαÑìαñ╖αÑçαññαÑìαñ░ αñòαÑÇ αñÿαñƒαñ¿αñ╛αÑñ\n15:52\n15 minutes, 52 seconds\nαñ╣αÑêαñªαñ░αñ╛αñ¼αñ╛αñª αñ«αÑçαñé αñêαñ╡αÑÇ αñ╡αÑçαñ»αñ░ αñ╣αñ╛αñëαñ╕ αñ«αÑçαñé αñ▓αñùαÑÇ αñ¡αÑÇαñ╖αñú αñåαñùαÑñ αñåαñù αñ¿αÑç αñòαÑüαñ¢ αñ╣αÑÇ αñªαÑçαñ░ αñ«αÑçαñé αñ¬αÑéαñ░αÑç αñ¬αñ░αñ┐αñ╕αñ░ αñòαÑï αñàαñ¬αñ¿αÑÇ αñÜαñ¬αÑçαñƒ αñ«αÑçαñé αñ▓αÑç αñ▓αñ┐αñ»αñ╛αÑñ αñ½αñ╛αñ»αñ░ αñ¼αÑìαñ░αñ┐αñùαÑçαñí αñ¿αÑç αñåαñù αñ¬αñ░ αñòαñ╛αñ¼αÑé αñ¬αñ╛αñ»αñ╛αÑñ αñ▓αñ╛αñûαÑïαñé αñòαñ╛ αñ╣αÑüαñå αñ╣αÑê αñ¿αÑüαñòαñ╕αñ╛αñ¿αÑñ\n16:04\n16 minutes, 4 seconds\nαñ«αñ╣αñ╛αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░ αñòαÑç αñ¬αÑüαñúαÑç αñ«αÑçαñé αñÜαñ╛αñ░ αñªαÑüαñòαñ╛αñ¿αÑïαñé αñ«αÑçαñé αñåαñù αñ▓αñùαñ¿αÑç αñ╕αÑç αñòαñ╛αñ½αÑÇ αñ¿αÑüαñòαñ╕αñ╛αñ¿ αñ¬αñ╣αÑüαñéαñÜαñ╛ αñ╣αÑêαÑñ αñ½αñ╛αñ»αñ░ αñ¼αÑìαñ░αñ┐αñùαÑçαñí αñ¿αÑç αñ«αÑüαñ╢αÑìαñòαñ┐αñ▓ αñ╕αÑç αñåαñù αñ¬αñ░ αñòαñ╛αñ¼αÑé αñ¬αñ╛αñ»αñ╛αÑñ\n16:16\n16 minutes, 16 seconds\nαñªαñ┐αñ▓αÑìαñ▓αÑÇ αñ«αÑçαñé αñ╢αñ╛αñ╕αÑìαññαÑìαñ░αÑÇ αñ¿αñùαñ░ αñ«αÑçαñƒαÑìαñ░αÑï αñ╕αÑìαñƒαÑçαñ╢αñ¿ αñòαÑç αñ¬αñ╛αñ╕ αñ▓αñòαñíαñ╝αÑÇ αñòαÑç αñùαÑïαñªαñ╛αñ« αñ«αÑçαñé αñåαñù αñ▓αñù αñùαñêαÑñ αñåαñ╕αñ¬αñ╛αñ╕ αñòαÑç αñòαñê αñÿαñ░ αñ¡αÑÇ αñçαñ╕αñòαÑÇ αñÜαñ¬αÑçαñƒ αñ«αÑçαñé αñå αñùαñÅαÑñ αñ½αñ╛αñ»αñ░ αñ¼αÑìαñ░αñ┐αñùαÑçαñí αñ¿αÑç αñÅαñò αñÿαñéαñƒαÑç αñòαÑÇ αñ«αñ╢αñòαÑìαñòαññ αñòαÑç αñ¼αñ╛αñª αñåαñù αñ¬αñ░ αñòαñ╛αñ¼αÑé αñ¬αñ╛αñ»αñ╛αÑñ\n16:27\n16 minutes, 27 seconds\nαñàαñ▓αÑìαñ«αÑïαñíαñ╝αñ╛ αñ«αÑçαñé αñûαñ╛αñê αñ«αÑçαñé αñùαñ┐αñ░αÑÇ αñ¼αÑïαñ▓αÑçαñ░αÑï αñùαñ╛αñíαñ╝αÑÇαÑñ\n16:29\n16 minutes, 29 seconds\nαñ╣αñ╛αñªαñ╕αÑç αñ«αÑçαñé αñÜαñ╛αñ░ αñ¼αñÜαÑìαñÜαÑïαñé αñ╕αñ«αÑçαññ 11 αñ▓αÑïαñù αñÿαñ╛αñ»αñ▓ αñ╣αÑï αñùαñÅαÑñ αññαÑÇαñ¿ αñÿαñ╛αñ»αñ▓αÑïαñé αñòαÑï αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛ αñ╣αÑê αñ╣αñ╛αñ»αñ░ αñ╕αÑçαñéαñƒαñ░ αñ░αÑçαñ½αñ░αÑñ αñ£αñ╛αñùαÑçαñ╢αÑìαñ╡αñ░ αñ«αñéαñªαñ┐αñ░ αñªαñ░αÑìαñ╢αñ¿ αñòαÑç αñ▓αñ┐αñÅ αñ£αñ╛ αñ░αñ╣αÑç αñÑαÑç αñ╕αñ¡αÑÇ αñ▓αÑïαñùαÑñ\n16:40\n16 minutes, 40 seconds\nαñ¿αÑêαñ¿αÑÇαññαñ╛αñ▓ αñ«αÑçαñé αñòαñ╛αñ▓αñ╛ αñ¥αÑüαñéαñùαÑÇ αñ░αÑïαñí αñ¬αñ░ αñ╣αñ╛αñªαñ╕αñ╛ αñ╣αÑüαñåαÑñ\n16:42\n16 minutes, 42 seconds\nαñàαñ¿αñ┐αñ»αñéαññαÑìαñ░αñ┐αññ αñ╣αÑïαñòαñ░ αñ╕αñ░αñ┐αñ»αñ╛αññαñ╛αñ▓ αñ¥αÑÇαñ▓ αñ«αÑçαñé αñùαñ┐αñ░αÑÇ αñòαñ╛αñ░αÑñ αñòαñ╛αñ░ αñ╕αñ╡αñ╛αñ░ αñ╕αñ¡αÑÇ αñÜαñ╛αñ░ αñ▓αÑïαñù αñ╕αÑüαñ░αñòαÑìαñ╖αñ┐αññ αñ¼αññαñ╛αñÅ αñ£αñ╛ αñ░αñ╣αÑç αñ╣αÑêαñéαÑñ\n16:51\n16 minutes, 51 seconds\nαñùαÑïαñ░αñûαñ¬αÑüαñ░ αñ«αÑçαñé αñ░αñ╛αÑìαññαÑÇ αñ¿αñªαÑÇ αñ«αÑçαñé αñ¿αñ╣αñ╛αñ¿αÑç αñùαñÅ αñªαÑï αñ¼αñÜαÑìαñÜαÑç αñíαÑéαñ¼αÑçαÑñ αñ¬αñ╛αñ¿αÑÇ αñ«αÑçαñé αñíαÑéαñ¼αñ¿αÑç αñ╕αÑç αñÅαñò αñ¼αñÜαÑìαñÜαÑç αñòαÑÇ αñ«αÑîαññ αñ╣αÑï αñùαñêαÑñ αñ¼αñÜαÑìαñÜαÑÇ αñòαÑÇ αññαñ▓αñ╛αñ╢ αñòαÑç αñ▓αñ┐αñÅ αñ╕αñ░αÑìαñÜ αñæαñ¬αñ░αÑçαñ╢αñ¿ αñÜαñ▓αñ╛αñ»αñ╛ αñ£αñ╛ αñ░αñ╣αñ╛ αñ╣αÑêαÑñ αñÿαñƒαñ¿αñ╛ αñòαÑç αñ¼αñ╛αñª αñ¬αñ░αñ┐αñ£αñ¿αÑïαñé αñ«αÑçαñé αñòαÑïαñ╣αñ░αñ╛αñ« αñ«αñÜαñ╛αÑñ\n17:03\n17 minutes, 3 seconds\nαñàαñéαñ¼αñ╛αñ▓αñ╛ αñòαÑÇ αñ¬αÑüαñ░αñ╛αñ¿αÑÇ αñ╕αñ¼αÑìαñ£αÑÇ αñ«αñéαñíαÑÇ αñ«αÑçαñé αñ¡αñ░αñ¡αñ░αñ╛ αñòαñ░ αñùαñ┐αñ░αñ╛ αñçαñ«αñ╛αñ░αññ αñòαñ╛ αñ¥αñ£αÑìαñ£αñ╛αÑñ αñ╕αÑéαñÜαñ¿αñ╛ αñòαÑç αñ¼αñ╛αñª αñ«αÑîαñòαÑç αñ¬αñ░ αñ¬αñ╣αÑüαñéαñÜαñ╛ αñ¬αÑìαñ░αñ╢αñ╛αñ╕αñ¿αÑñ αñ«αñ▓αñ¼αÑç αñ«αÑçαñé αñªαñ¼αÑç αñªαÑï αñ▓αÑïαñùαÑïαñé\n17:10\n17 minutes, 10 seconds\nαñòαÑï αñ¿αñ┐αñòαñ╛αñ▓αñ╛ αñùαñ»αñ╛ αñ¼αñ╛αñ╣αñ░αÑñ αñòαñ╛αñ½αÑÇ αñ╕αñ«αñ» αñ╕αÑç αñ£αñ£αñ░ αñ╣αñ╛αñ▓αññ αñ«αÑçαñé αñÑαÑÇ αñçαñ«αñ╛αñ░αññαÑñ\n17:17\n17 minutes, 17 seconds\nαñ£αñ╛αñ▓αñéαñºαñ░ αñ«αÑçαñé αñíαÑìαñ░αñù αññαñ╕αÑìαñòαñ░αÑÇ αñ╕αÑç αñ£αÑüαñíαñ╝αÑç αñ╡αÑÇαñ░αñªαñ╛ αñóαñ╛αñ¼αñ╛ αñ¬αñ░ αñ¼αÑüαñ▓αñíαÑïαñ£αñ░ αñÜαñ▓αñ╛αñ»αñ╛ αñ¿αñùαñ░ αñ¿αñ┐αñùαñ« αñöαñ░ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ╣αñƒαñ╛αñ»αñ╛ αñàαññαñ┐αñòαÑìαñ░αñ«αñúαÑñ αñ¬αÑìαñ░αÑëαñ¬αñ░αÑìαñƒαÑÇ αñ¬αñ░ αñ«αñ╛αñ▓αñ┐αñòαñ╛αñ¿αñ╛ αñ╣αñò αñòαÑï αñ▓αÑçαñòαñ░ αñ╕αñ╛αñ«αñ¿αÑç αñåαñ»αñ╛ αñÑαñ╛ αñ╡αñ┐αñ╡αñ╛αñªαÑñ\n17:29\n17 minutes, 29 seconds\nαñ«αÑüαñ░αñ╛αñªαñ╛αñ¼αñ╛αñª αñòαÑç αñ¡αñùαññαñ¬αÑüαñ░ αñòαÑìαñ╖αÑçαññαÑìαñ░ αñ«αÑçαñé αñàαñ╡αÑêαñº αñ«αñ╕αÑìαñ£αñ┐αñª αñ¬αñ░ αñÜαñ▓αñ╛ αñ¼αÑüαñ▓αñíαÑïαñ£αñ╝αÑñ αñ¼αÑüαñ▓αñíαÑïαñ£αñ░ αñ╕αÑç αñùαñ┐αñ░αñ╛αñê αñ«αñ╕αÑìαñ£αñ┐αñªαÑñ 300 αñ╡αñ░αÑìαñù αñ«αÑÇαñƒαñ░ αñ╕αñ░αñòαñ╛αñ░αÑÇ αñ£αñ«αÑÇαñ¿ αñ¬αñ░ αñ»αñ╣ αñ«αñ╕αÑìαñ£αñ┐αñª αñ¼αñ¿αÑÇ αñ╣αÑüαñê αñÑαÑÇαÑñ\n17:40\n17 minutes, 40 seconds\nαñ▓αñûαñ¿αñè αñ«αÑçαñé αñûαñ¿αñ¿ αñ«αñ╛αñ½αñ┐αñ»αñ╛ αñòαÑç αñ¼αÑÇαñÜ αñ½αñ╛αñ»αñ░αñ┐αñéαñù αñ╣αÑï αñùαñêαÑñ αñ¬αÑüαñ░αñ╛αñ¿αÑÇ αñ░αñéαñ£αñ┐αñ╢ αñòαÑï αñ▓αÑçαñòαñ░ αñ½αñ╛αñ»αñ░αñ┐αñéαñù αñòαÑÇ αñÿαñƒαñ¿αñ╛ αñ╕αñ╛αñ«αñ¿αÑç αñåαñêαÑñ αñ╕αÑüαñ╢αñ╛αñéαññ αñùαÑìαñ½ αñ╕αñ┐αñƒαÑÇ αñÑαñ╛αñ¿αñ╛ αñòαÑìαñ╖αÑçαññαÑìαñ░ αñòαÑç αñ╕αÑçαñ╡αñê αñÜαÑîαñòαÑÇ αñòαñ╛ αñ«αñ╛αñ«αñ▓αñ╛ αñ╣αÑêαÑñ αñ¢αñ╛αñ¿αñ¼αÑÇαñ¿ αñ«αÑçαñé αñ£αÑüαñƒαÑÇ αñ╣αÑê αñ¬αÑüαñ▓αñ┐αñ╕αÑñ\n17:53\n17 minutes, 53 seconds\nαñ¢αññαÑìαññαÑÇαñ╕αñùαñóαñ╝ αñòαÑç αñ╕αÑéαñ░αñ£αñ¬αÑüαñ░ αñ«αÑçαñé αñùαñ░αÑìαñ¡αñ╡αññαÑÇ αñ«αñ╣αñ┐αñ▓αñ╛ αñòαÑÇ αñ«αÑîαññ αñ¬αñ░ αñ╣αñéαñùαñ╛αñ«αñ╛ αñ╣αÑüαñåαÑñ αñ¬αñ░αñ┐αñ£αñ¿αÑïαñé αñ¿αÑç αñàαñ╕αÑìαñ¬αññαñ╛αñ▓ αñòαÑç αñíαÑëαñòαÑìαñƒαñ░αÑìαñ╕ αñ¬αñ░ αñ▓αñùαñ╛αñ»αñ╛ αñ▓αñ╛αñ¬αñ░αñ╡αñ╛αñ╣αÑÇ αñòαñ╛ αñåαñ░αÑïαñ¬αÑñ\n17:59\n17 minutes, 59 seconds\nαñ╕αÑìαñ╡αñ╛αñ╕αÑìαñÑαÑìαñ» αñ╡αñ┐αñ¡αñ╛αñù αñ¿αÑç αñùαñáαñ┐αññ αñòαÑÇ αñ£αñ╛αñéαñÜ αñòαÑÇαÑñ\n18:06\n18 minutes, 6 seconds\nαñ╕αñéαñ¡αñ▓ αñ«αÑçαñé αñ«αÑüαñ╣αñ░αÑìαñ░αñ« αñòαÑï αñ▓αÑçαñòαñ░ αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñ╡αÑìαñ»αñ╡αñ╕αÑìαñÑαñ╛ αññαñùαñíαñ╝αÑÇ αñòαñ░ αñªαÑÇ αñùαñê αñ╣αÑêαÑñ αñíαÑÇαñÅαñ« αñöαñ░ αñÅαñ╕αñ¬αÑÇ αñòαÑÇ αñàαñùαÑüαñ╡αñ╛αñê αñ«αÑçαñé αñ½αÑìαñ▓αÑêαñù αñ«αñ╛αñ░αÑìαñÜ αñ¡αÑÇ αñ¿αñ┐αñòαñ╛αñ▓αñ╛ αñùαñ»αñ╛αÑñ\n18:12\n18 minutes, 12 seconds\nαñ▓αÑïαñùαÑïαñé αñòαÑç αñ▓αÑïαñùαÑïαñé αñ╕αÑç αñ╢αñ╛αñéαññαñ┐ αñòαÑç αñ╕αñ╛αñÑ αñ«αÑüαñ╣αñ░αÑìαñ░αñ« αñ«αñ¿αñ╛αñ¿αÑç αñòαÑÇ αñàαñ¬αÑÇαñ▓ αñòαÑÇαÑñ\n18:20\n18 minutes, 20 seconds\nαñàαñ«αñ░αñ¿αñ╛αñÑ αñ»αñ╛αññαÑìαñ░αñ╛ αñòαÑï αñ▓αÑçαñòαñ░ αñ£αñ«αÑìαñ«αÑé αñòαñ╢αÑìαñ«αÑÇαñ░ αñ«αÑçαñé αñòαñíαñ╝αÑÇ αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛αÑñ αñòαñáαÑüαñå αñ«αÑçαñé αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñ¼αñ▓αÑïαñé αñ¿αÑç αñ£αñ╛αñéαñÜ αñòαÑÇαÑñ αñ░αÑçαñ▓αñ╡αÑç αñ╕αÑìαñƒαÑçαñ╢αñ¿ αñöαñ░ αñàαñ╣αñ« αñ£αñùαñ╣αÑïαñé αñòαñ╛ αñ¿αñ┐αñ░αÑÇαñòαÑìαñ╖αñú αñ¡αÑÇ αñòαñ┐αñ»αñ╛αÑñ\n18:30\n18 minutes, 30 seconds\nαñôαñ╕αñ╛ αñòαÑÇ αñ╡αñ┐αñ░αñ╛αñ╕αññ αñöαñ░ αñ¬αñ░αñéαñ¬αñ░αñ╛ αñ╕αÑç αñ£αÑüαñíαñ╝αñ╛ αñòαñ╛αñ░αÑìαñ»αñòαÑìαñ░αñ«αÑñ αñ░αñ╛αñ»αñùαñóαñ╝αñ╛ αñ«αÑçαñé αñ«αñ¿αñ╛αñ»αñ╛ αñùαñ»αñ╛ αñ½αÑçαñ╕αÑìαñƒαñ┐αñ╡αñ▓αÑñ αñëαñíαñ╝αñ┐αñ»αñ╛ αñ╡αñ┐αñ░αñ╛αñ╕αññ αñöαñ░ αñ¬αñ░αñéαñ¬αñ░αñ╛αñôαñé αñòαÑï αñ¼αñ¿αñ╛αñÅ αñ░αñûαñ¿αÑç αñòαÑÇ αñàαñ¬αÑÇαñ▓αÑñ\n18:43\n18 minutes, 43 seconds\nαñ¬αñéαñ£αñ╛αñ¼ αñòαÑç αñàαñ«αÑâαññαñ╕αñ░ αñ╕αÑç αñ«αñ╛αññαñ╛ αñ╡αÑêαñ╖αÑìαñúαÑï αñªαÑçαñ╡αÑÇ αñòαñƒαñ░αñ╛ αñòαÑç αñ▓αñ┐αñÅ αñ╡αñéαñªαÑç αñ¡αñ╛αñ░αññ αñƒαÑìαñ░αÑçαñ¿ αñòαÑÇ αñ╢αÑüαñ░αÑüαñåαññαÑñ αñ¬αñéαñ£αñ╛αñ¼ αñòαÑç αñòαñê αñ╢αñ╣αñ░αÑïαñé αñòαÑï αñ¬αñ╣αñ▓αÑÇ αñ¼αñ╛αñ░ αñ╡αñéαñªαÑç αñ¡αñ╛αñ░αññ αñƒαÑìαñ░αÑçαñ¿ αñòαÑÇ αñ╕αÑüαñ╡αñ┐αñºαñ╛ αñ«αñ┐αñ▓αÑçαñùαÑÇαÑñ\n18:54\n18 minutes, 54 seconds\nαñòαÑïαñ░αÑìαñƒαñª αñòαÑç αñ░αñ╛αñ«αñ▓αÑÇ αñùαñ╛αñéαñ╡ αñ«αÑçαñé αñÿαÑüαñ╕αñ╛ αñ╣αñ╛αñÑαÑÇαÑñ\n18:56\n18 minutes, 56 seconds\nαñùαÑìαñ░αñ╛αñ«αÑÇαñúαÑïαñé αñ«αÑçαñé αñ«αñÜαÑÇ αñàαñ½αñ░αñ╛αññαñ½αñ░αÑÇαÑñ αñ╢αÑïαñ░ αñ«αñÜαñ╛αñ¿αÑç αñ¬αñ░ αñ╣αñ╛αñÑαÑÇ αñ£αñéαñùαñ▓ αñòαÑÇ αññαñ░αñ½ αñ¡αñ╛αñù αñùαñ»αñ╛αÑñ αñ╡αñ¿ αñ╡αñ┐αñ¡αñ╛αñù αñ╕αÑç αñçαñ▓αñ╛αñòαÑç αñ«αÑçαñé αñùαñ╢αÑìαññ αñ¼αñóαñ╝αñ╛αñ¿αÑç αñòαÑÇ αñ«αñ╛αñéαñù αñòαÑÇ αñ£αñ╛ αñ░αñ╣αÑÇ αñ╣αÑêαÑñ\n19:06\n19 minutes, 6 seconds\nαñ¬αÑîαñ╕ αñ¿αÑìαñ»αÑéαñ£αñ╝ αñ«αÑçαñé αñàαñ¼ αñåαñ¬αñòαÑï αñªαñ┐αñûαñ╛ αñªαÑçαññαÑç αñ╣αÑêαñé αñ½αñƒαñ╛αñ½αñƒαÑñ αñàαñ¬αñ░αñ╛αñº αñ£αñùαññ αñòαÑÇ αñ¼αñíαñ╝αÑÇ αñûαñ¼αñ░αÑçαñéαÑñ αñ£αÑêαñ╕αñ▓αñ«αÑçαñ░ αñ«αÑçαñé αñåαñêαñÅαñ╕αñåαñê αñÅαñ£αÑçαñéαñƒ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░αÑñ\n19:14\n19 minutes, 14 seconds\nαñ¼αÑÇαñÅαñ╕αñÅαñ½ αñöαñ░ αñ╕αÑçαñ¿αñ╛ αñòαÑç αñ«αÑéαñ╡αñ«αÑçαñéαñƒ αñòαÑÇ αñ¡αÑçαñ£αññαñ╛ αñÑαñ╛ αñ£αñ╛αñ¿αñòαñ╛αñ░αÑÇαÑñ αñªαÑüαñòαñ╛αñ¿ αñòαÑÇ αñåαñíαñ╝ αñ«αÑçαñé αñòαñ░αññαñ╛ αñÑαñ╛ αñ¬αñ╛αñòαñ┐αñ╕αÑìαññαñ╛αñ¿ αñòαÑç αñ▓αñ┐αñÅ αñ£αñ╛αñ╕αÑéαñ╕αÑÇαÑñ\n19:23\n19 minutes, 23 seconds\nαñ»αÑéαñ¬αÑÇ αñòαÑç αñ¼αñíαñ╝αÑîαññ αñ«αÑçαñé αñƒαÑçαñéαñƒ αñòαñ╛αñ░αÑïαñ¼αñ╛αñ░αÑÇ αñöαñ░ αñëαñ¿αñòαÑç αñ¼αÑçαñƒαÑç αñòαÑÇ αñ╣αññαÑìαñ»αñ╛ αñòαñ╛ αñ«αñ╛αñ«αñ▓αñ╛αÑñ αñ╣αññαÑìαñ»αñ╛αñòαñ╛αñéαñí αñ«αÑçαñé αñ╢αñ╛αñ«αñ┐αñ▓αÑñ αñåαñ░αÑïαñ¬αÑÇ αñòαÑç αñ╕αñ╛αñÑ αñ¬αÑüαñ▓αñ┐αñ╕ αñòαÑÇ αñ«αÑüαñáαñ¡αÑçαñíαñ╝ αñ╣αÑï αñùαñêαÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñòαÑÇ αñùαÑïαñ▓αÑÇ αñ╕αÑç αñÿαñ╛αñ»αñ▓ αñ╣αÑüαñå αñ¼αñªαñ«αñ╛αñ╢αÑñ\n19:35\n19 minutes, 35 seconds\nαñëαññαÑìαññαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñ¼αñ╣αñ░αñ╛αñçαñÜ αñ«αÑçαñé αñ¬αÑçαñƒαÑìαñ░αÑïαñ▓ αñ¬αñéαñ¬ αñ¬αñ░ 95,000 αñòαÑÇ αñ▓αÑéαñƒ αñòαñ╛ αñ«αñ╛αñ«αñ▓αñ╛ αñ╕αñ╛αñ«αñ¿αÑç αñåαñ»αñ╛αÑñ αñ╕αñ╛αñ«αñ╛αñ¿ αñ▓αÑçαñ¿αÑç αñòαÑç αñ¼αñ╣αñ╛αñ¿αÑç αñ▓αÑüαñƒαÑçαñ░αÑç αñåαñÅ αñÑαÑçαÑñ\n19:42\n19 minutes, 42 seconds\nαñ¬αÑçαñƒαÑìαñ░αÑïαñ▓ αñ¬αñéαñ¬ αñ¬αñ░ αñ▓αñùαÑç αñ╕αÑÇαñ╕αÑÇαñƒαÑÇαñ╡αÑÇ αñòαÑêαñ«αñ░αÑç αñ«αÑçαñé αñòαÑêαñª αñ╣αÑüαñê αñ╡αñ╛αñ░αñªαñ╛αññαÑñ\n19:48\n19 minutes, 48 seconds\nαñ«αÑçαñ░αñá αñ«αÑçαñé αñ╕αñ░αñòαñ╛αñ░ αñòαÑï αñòαñ░αÑïαñíαñ╝αÑïαñé αñòαñ╛ αñÜαÑéαñ¿αñ╛ αñ▓αñùαñ╛αñ¿αÑç αñ╡αñ╛αñ▓αÑç αñ½αñ░αÑìαñ£αÑÇ αñ░αÑëαñ»αñ▓αÑìαñƒαÑÇ αñùαñ┐αñ░αÑïαñ╣αÑïαñé αñòαñ╛ αñ¬αñ░αÑìαñªαñ╛αñ½αñ╛αñ╢ αñ╣αÑüαñåαÑñ αñÅαñ╕αñƒαÑÇαñÅαñ½ αñ¿αÑç αñÜαñ╛αñ░ αñåαñ░αÑïαñ¬αñ┐αñ»αÑïαñé αñòαÑï αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛αÑñ αñûαñ¿αñ¿ αñªαñ╕αÑìαññαñ╛αñ╡αÑçαñ£αÑïαñé αñ«αÑçαñé αñ╣αÑçαñ░αñ╛αñ½αÑçαñ░αÑÇ αñòαñ╛ αñåαñ░αÑïαñ¬ αñ╣αÑêαÑñ\n20:01\n20 minutes, 1 second\nαñ£αÑïαñºαñ¬αÑüαñ░ αñ«αÑçαñé αñ¬αÑüαñ▓αñ┐αñ╕ αñÑαñ╛αñ¿αÑç αñ«αÑçαñé αñ¬αÑéαñ¢αññαñ╛αñ¢ αñòαÑç αñ▓αñ┐αñÅ αñ¼αÑüαñ▓αñ╛αñÅ αñùαñÅ αñ»αÑüαñ╡αñò αñòαÑÇ αñ«αÑîαññ αñ╣αÑï αñùαñêαÑñ αñ▓αñ╛αñ¬αññαñ╛ αñ«αñ╣αñ┐αñ▓αñ╛ αñòαÑç αñ╕αñ┐αñ▓αñ╕αñ┐αñ▓αÑç αñ«αÑçαñé αñ¬αÑéαñ¢αññαñ╛αñ¢ αñòαÑç αñ▓αñ┐αñÅ αñÑαñ╛αñ¿αÑç αñ¼αÑüαñ▓αñ╛αñ»αñ╛ αñùαñ»αñ╛ αñÑαñ╛ αñ»αÑüαñ╡αñò αñòαÑïαÑñ αñ¬αñ░αñ┐αñ£αñ¿αÑïαñé αñ¿αÑç αñ«αñ╛αñ«αñ▓αÑç αñòαÑÇ αñ£αñ╛αñéαñÜ αñòαÑÇ αñ«αñ╛αñéαñù αñòαÑÇαÑñ\n20:14\n20 minutes, 14 seconds\nαñ▓αÑüαñºαñ┐αñ»αñ╛αñ¿αñ╛ αñ«αÑçαñé αñªαñ¼αñéαñùαÑïαñé αñ¿αÑç αñÅαñò αñÿαñ░ αñ¬αñ░ αñ╣αñ«αñ▓αñ╛ αñ¼αÑïαñ▓αñ╛αÑñ αñÿαñ░ αñ¬αñ░ αñ¼αñ░αñ╕αñ╛αñê αñêαñéαñƒ αñ¬αññαÑìαñÑαñ░αÑñ αñ¼αñ╛αñ╣αñ░ αñûαñíαñ╝αÑç αñ╡αñ╛αñ╣αñ¿αÑïαñé αñ«αÑçαñé αñ¡αÑÇ αñ£αñ«αñòαñ░ αññαÑïαñíαñ╝αñ½αÑïαñíαñ╝ αñòαÑÇαÑñ αñªαÑïαñ¿αÑïαñé αñ¬αñòαÑìαñ╖αÑïαñé αñòαÑç αñ¼αÑÇαñÜ αñÜαñ▓αÑÇ αñå αñ░αñ╣αÑÇ αñ╣αÑê αñ¬αÑüαñ░αñ╛αñ¿αÑÇ αñ░αñéαñ£αñ┐αñ╢αÑñ\n20:27\n20 minutes, 27 seconds\nαñ╕αÑéαñ░αññ αñ«αÑçαñé αñ╕αÑìαñòαÑéαñ▓ αñòαÑç αñùαÑçαñƒ αñ¬αñ░ αñòαñòαÑìαñ╖αñ╛ αñ¢αñ╣ αñòαÑç αñ¢αñ╛αññαÑìαñ░ αñ¬αñ░ αñÜαñ╛αñòαÑé αñ╕αÑç αñ╣αñ«αñ▓αñ╛αÑñ αñ¬αñ░αñ┐αñ£αñ¿αÑïαñé αñ¿αÑç αñ¼αññαñ╛αñ»αñ╛ αñ¢αñ╛αññαÑìαñ░αÑïαñé αñòαÑç αñ¼αÑÇαñÜ αñòαÑüαñ¢ αñªαñ┐αñ¿ αñ¬αñ╣αñ▓αÑç αñ╡αñ┐αñ╡αñ╛αñª αñ╣αÑüαñå αñÑαñ╛αÑñ\n20:39\n20 minutes, 39 seconds\nαñùαñ╛αñ£αñ┐αñ»αñ╛αñ¼αñ╛αñª αñòαÑç αñûαÑïαñíαñ╝αñ╛ αñ«αÑçαñé αñªαÑï αñ╕αñùαÑÇ αñ¼αñ╣αñ¿αÑïαñé αñòαÑï αñùαÑïαñ▓αÑÇ αñ«αñ╛αñ░αñ¿αÑç αñòαñ╛ αñ«αñ╛αñ«αñ▓αñ╛αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ£αÑëαñ¿αÑÇ αñ¿αñ╛αñ« αñòαÑç αñåαñ░αÑïαñ¬αÑÇ αñòαÑï αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛αÑñ αñ╢αñ╛αñªαÑÇ αñòαñ╛ αñ░αñ┐αñ╢αÑìαññαñ╛ αñƒαÑéαñƒαñ¿αÑç αñòαÑÇ αñ╡αñ£αñ╣ αñ╕αÑç αñ¿αñ╛αñ░αñ╛αñ£ αñÑαñ╛ αñ»αÑüαñ╡αñòαÑñ\n20:52\n20 minutes, 52 seconds\nαñ«αñ╕αÑéαñ░αÑÇ αñòαÑç αñºαñ¿αÑîαñ▓αÑìαñƒαÑÇ αñ«αÑçαñé αñçαñ╕ αñ╣αÑïαñ« αñ╕αÑìαñƒαÑç αñ«αÑçαñé αñ«αñ┐αñ▓αñ╛αÑñ αñ«αñ╣αñ┐αñ▓αñ╛ αñòαñ╛ αñ╢αñ╡, αñ╕αÑëαñ½αÑìαñƒαñ╡αÑçαñ»αñ░ αñçαñéαñ£αÑÇαñ¿αñ┐αñ»αñ░ αñòαÑÇ αñ╕αñéαñªαñ┐αñùαÑìαñº αñ╕αÑìαñÑαñ┐αññαñ┐ αñ«αÑçαñé αñ«αÑîαññ αñ╣αÑï αñùαñêαÑñ αñ¬αñ░αñ┐αñ£αñ¿αÑïαñé αñ¿αÑç αñòαÑÇ αñ╣αÑê αñ¿αñ┐αñ╖αÑìαñ¬αñòαÑìαñ╖ αñ£αñ╛αñéαñÜ αñòαÑÇ αñ«αñ╛αñéαñùαÑñ αñ«αñ╛αñ«αñ▓αÑç αñòαÑÇ αñ£αñ╛αñéαñÜ αñ«αÑçαñé αñ£αÑüαñƒαÑÇ αñ╣αÑê αñ¬αÑüαñ▓αñ┐αñ╕αÑñ\n21:06\n21 minutes, 6 seconds\nαñ¬αñéαñ£αñ╛αñ¼ αñòαÑç αñ¡αñƒαñ┐αñéαñíαñ╛ αñ«αÑçαñé αñ£αñ╛αñ╕αÑéαñ╕αÑÇ αñòαÑç αñåαñ░αÑïαñ¬ αñ«αÑçαñé αñªαÑï αñ▓αÑïαñù αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñÅ αñùαñÅαÑñ αñ¬αñ╛αñòαñ┐αñ╕αÑìαññαñ╛αñ¿ αñòαÑç αñ▓αñ┐αñÅ αñ£αñ╛αñ╕αÑéαñ╕αÑÇ αñöαñ░ αñ╕αÑÇαñ╕αÑÇαñƒαÑÇαñ╡αÑÇ αñ½αÑüαñƒαÑçαñ£ αñ¡αÑçαñ£αñ¿αÑç αñòαñ╛ αñåαñ░αÑïαñ¬ αñ╣αÑêαÑñ\n21:17\n21 minutes, 17 seconds\nαñªαñ┐αñ▓αÑìαñ▓αÑÇ αñ«αÑçαñé αñ¬αñ╛αñòαñ┐αñ╕αÑìαññαñ╛αñ¿ αñ╕αñ«αñ░αÑìαñÑαñ┐αññ αñåαññαñéαñòαÑÇ αñ¿αÑçαñƒαñ╡αñ░αÑìαñò αñòαñ╛αñéαñíαñ╛αñ¬αÑïαñíαñ╝ αñ╣αÑüαñåαÑñ αñ╕αñ╛αññ αñåαñ░αÑïαñ¬αÑÇ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░αÑñ αñ¬αñ╛αñòαñ┐αñ╕αÑìαññαñ╛αñ¿ αñ«αÑçαñé αñ¼αÑêαñáαÑç αñ╢αñ╣αñ£αñ╛αñª αñ¡αñƒαÑìαñƒαÑÇ αñöαñ░ αñëαñ╕αñòαÑç αñ╕αñ╣αñ»αÑïαñùαÑÇ αñàαñ£αñ«αñ▓ αñùαÑüαñ░αÑìαñ£αñ░ αñòαÑç αñ¿αñ┐αñ░αÑìαñªαÑçαñ╢ αñ¬αñ░ αñÜαñ▓αñ╛αñ»αñ╛ αñ£αñ╛ αñ░αñ╣αñ╛ αñÑαñ╛ αñ»αñ╣ αñ¿αÑçαñƒαñ╡αñ░αÑìαñòαÑñ\n21:33\n21 minutes, 33 seconds\nαñùαÑüαñ░αÑüαñùαÑìαñ░αñ╛αñ« αñ«αÑçαñé αñòαÑìαñ░αñ╛αñçαñ« αñ¼αÑìαñ░αñ╛αñéαñÜ αñ¿αÑç 13 αñàαñ╡αÑêαñº αñ¼αñ╛αñéαñùαÑìαñ▓αñ╛αñªαÑçαñ╢αÑïαñé αñòαÑï αñ¬αñòαñíαñ╝αñ╛αÑñ αñòαñ╛αñ▓αñ┐αñ»αñ╛αñùαñéαñ£ αñ¼αÑëαñ░αÑìαñíαñ░ αñ╕αÑç αñÅαñ£αÑçαñéαñƒ αñòαÑÇ αñ«αñªαñª αñ╕αÑç αñÿαÑüαñ╕αÑç αñÑαÑç αñ¡αñ╛αñ░αññαÑñ αñ«αñ£αñªαÑéαñ░ αñ¼αñ¿αñòαñ░ αñ¥αÑüαñùαÑìαñùαñ┐αñ»αÑïαñé αñ«αÑçαñé αñ░αñ╣ αñ░αñ╣αÑç αñÑαÑç αñ¼αñ╛αñéαñùαÑìαñ▓αñ╛αñªαÑçαñ╢αÑÇ αñ¿αñ╛αñùαñ░αñ┐αñòαÑñ\n21:47\n21 minutes, 47 seconds\nαñùαñ╛αñ£αñ┐αñ»αñ╛αñ¼αñ╛αñª αñ«αÑçαñé αñ£αÑìαñ╡αÑçαñ▓αñ░αÑÇ αñ╢αÑïαñ░αÑéαñ« αñ«αÑçαñé αñÜαÑïαñ░αÑÇ αñòαñ░αñ¿αÑç αñ╡αñ╛αñ▓αÑç αññαÑÇαñ¿ αñåαñ░αÑïαñ¬αÑÇ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñÅ αñùαñÅαÑñ Γé╣3 αñòαñ░αÑïαñíαñ╝ αñòαÑç αñ£αÑçαñ╡αñ░αñ╛αññ αñ¡αÑÇ αñ¼αñ░αñ╛αñ«αñªαÑñ αñ╕αÑçαñ▓αÑìαñ╕αñ«αÑêαñ¿ αñ¿αÑç αñ£αñ¿αÑìαñ«αñªαñ┐αñ¿ αñ¬αñ╛αñ░αÑìαñƒαÑÇ αñ«αÑçαñé αñ░αñÜαÑÇ αñÑαÑÇ αñ╕αñ╛αñ£αñ┐αñ╢αÑñ\n21:58\n21 minutes, 58 seconds\nαñ¼αñªαñ╛αñ»αÑéαñé αñ«αÑçαñé αñ¬αññαÑìαñ¿αÑÇ αñòαÑç αñ░αÑÇαñ▓αÑìαñ╕ αñ¼αñ¿αñ╛αñ¿αÑç αñ╕αÑç αñ¬αñ░αÑçαñ╢αñ╛αñ¿αÑñ αñ¬αññαñ┐ αñ¿αÑç αñ½αñ╛αñéαñ╕αÑÇ αñ▓αñùαñ╛αñòαñ░ αñûαÑüαñªαñòαÑüαñ╢αÑÇ αñòαñ░ αñ▓αÑÇαÑñ αñ¬αñ░αñ┐αñ£αñ¿αÑïαñé αñòαñ╛ αñåαñ░αÑïαñ¬ αñ╣αÑê αñòαñ┐ αñ¬αññαÑìαñ¿αÑÇ αñòαÑç αñ╕αñ╛αñÑ αñ╡αñ┐αñ╡αñ╛αñª αñòαÑç αñ¼αñ╛αñª αñëαñáαñ╛αñ»αñ╛ αñûαññαñ░αñ¿αñ╛αñò αñòαñªαñ«αÑñ\n22:08\n22 minutes, 8 seconds\nαñ£αñ»αñ¬αÑüαñ░ αñ«αÑçαñé αñàαñ╡αÑêαñº αñ╕αñéαñ¼αñéαñº αñòαÑç αñ╢αñò αñ«αÑçαñé αñ¬αñíαñ╝αÑïαñ╕ αñòαÑÇ αñ«αñ╣αñ┐αñ▓αñ╛ αñ¼αñ¿αÑÇ αñ╣αÑêαñ╡αñ╛αñ¿αÑñ 5 αñ╕αñ╛αñ▓ αñòαÑÇ αñ«αñ╛αñ╕αÑéαñ« αñòαÑï αññαñ╛αñ░αñ╛ αñ«αÑîαññ αñòαÑç αñÿαñ╛αñƒαÑñ αñåαñ░αÑïαñ¬αÑÇ αñ«αñ╣αñ┐αñ▓αñ╛ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░αÑñ\n22:20\n22 minutes, 20 seconds\nαñ¼αÑçαñéαñùαñ▓αÑüαñ░αÑü αñ«αÑçαñé 22 αñ╕αñ╛αñ▓ αñòαÑÇ αñ»αÑüαñ╡αññαÑÇ αñòαÑÇ αñ«αÑîαññ αñòαñ╛ αñûαÑüαñ▓αñ╛αñ╕αñ╛ αñ╣αÑüαñåαÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ¬αÑìαñ░αÑçαñ«αÑÇ αñÜαñéαñªαñ¿ αñòαÑï αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛αÑñ αñªαÑïαñ¿αÑïαñé αñ¿αÑç αñ¬αñ░αñ┐αñ╡αñ╛αñ░ αñòαÑï αñ¼αñ┐αñ¿αñ╛ αñ¼αññαñ╛αñÅ αñòαñ░ αñ▓αÑÇ αñÑαÑÇ αñ╢αñ╛αñªαÑÇαÑñ\n22:33\n22 minutes, 33 seconds\nαñ░αñ╛αñ£αñ╕αÑìαñÑαñ╛αñ¿ αñòαÑç αñ¥αñ╛αñ▓αñ╛αñ╡αñ╛αñíαñ╝ αñ«αÑçαñé αñ¿αñ╢αñ╛ αññαñ╕αÑìαñòαñ░αÑïαñé αñöαñ░ αñëαñ¿αñòαÑç αñ«αñªαñªαñùαñ╛αñ░αÑïαñé αñòαÑÇ αñòαñ░αÑïαñíαñ╝αÑïαñé αñòαÑÇ αñ╕αñéαñ¬αññαÑìαññαñ┐ αñ╕αÑÇαñ£ αñòαÑÇ αñùαñêαÑñ αñÅαñ¿αñƒαÑÇαñ¬αÑÇαñÅαñ╕ αñÅαñòαÑìαñƒ αñòαÑç αññαñ╣αññ αñòαÑÇ αñùαñê αñòαñ╛αñ░αñ╡αñ╛αñêαÑñ\n22:42\n22 minutes, 42 seconds\nαñöαñ░ αñåαñçαñÅ αñàαñ¼ αñ¿αÑî αñ╕αÑç αñ¿αÑìαñ»αÑéαñ£αñ╝ αñ«αÑçαñé αñåαñ¬αñòαÑï αñªαñ┐αñûαñ╛ αñªαÑçαññαÑç αñ╣αÑêαñé αñªαÑçαñ╢ αñ¡αñ░ αñ«αÑçαñé αñ«αÑîαñ╕αñ« αñòαñ╛ αñ╣αñ╛αñ▓αÑñ\n22:50\n22 minutes, 50 seconds\nαñ░αñ╛αñ£αñ╕αÑìαñÑαñ╛αñ¿ αñòαÑç αñòαñê αñçαñ▓αñ╛αñòαÑïαñé αñ«αÑçαñé αñ¼αñªαñ▓αñ╛ αñ«αÑîαñ╕αñ« αñòαñ╛ αñ«αñ┐αñ£αñ╛αñ£αÑñ αñ£αÑêαñ╕αñ▓αñ«αÑçαñ░ αñòαÑç αñ░αñ╛αñ«αñùαñóαñ╝ αñ╕αñ«αÑçαññ αñ╕αÑÇαñ«αñ╛αñ╡αñ░αÑìαññαÑÇ αñçαñ▓αñ╛αñòαÑïαñé αñ«αÑçαñé αñ¼αñ╛αñ░αñ┐αñ╢ αñ╣αÑüαñêαÑñ αñ▓αÑïαñùαÑïαñé αñòαÑï αñùαñ░αÑìαñ«αÑÇ αñ╕αÑç αñÑαÑïαñíαñ╝αÑÇ αñ░αñ╛αñ╣αññ αñ«αñ┐αñ▓αÑÇαÑñ\n23:00\n23 minutes\nαñ»αÑéαñ¬αÑÇ αñòαÑç αñòαÑüαñ¢ αñçαñ▓αñ╛αñòαÑïαñé αñ«αÑçαñé αñ¡αÑÇαñ╖αñú αñùαñ░αÑìαñ«αÑÇ αñòαñ╛ αñòαñ╣αñ░αÑñ αñ¬αÑìαñ░αñ»αñ╛αñùαñ░αñ╛αñ£ αñ«αÑçαñé αñùαñ░αÑìαñ«αÑÇ αñòαÑÇ αñ╡αñ£αñ╣ αñ╕αÑç αñ£αñ¿αñ£αÑÇαñ╡αñ¿ αñàαñ╕αÑìαññ-αñ╡αÑìαñ»αñ╕αÑìαññ αñ╣αÑüαñåαÑñ αñ╕αñíαñ╝αñòαÑçαñé αñ╕αÑüαñ¿αÑÇ αñ¬αñíαñ╝αÑÇ αñ░αñ╣αÑÇαÑñ\n23:11\n23 minutes, 11 seconds\nαñ░αñ╛αñ£αñ╕αÑìαñÑαñ╛αñ¿ αñòαÑç αñ¼αÑÇαñòαñ╛αñ¿αÑçαñ░ αñ«αÑçαñé αñëαñáαñ╛ αñ░αÑçαññ αñòαñ╛ αñ¼αñ╡αñéαñíαñ░αÑñ αñòαÑüαñ¢ αñ╣αÑÇ αñªαÑçαñ░ αñ«αÑçαñé αñºαÑéαñ▓ αñ╕αÑç αñ¡αñ░ αñùαñ»αñ╛ αñ¬αÑéαñ░αñ╛ αñ╢αñ╣αñ░αÑñ αñºαÑéαñ▓ αñ¡αñ░αÑÇ αñåαñéαñºαÑÇ αñ╕αÑç αñ£αñ¿αñ£αÑÇαñ╡αñ¿ αñàαñ╕αÑìαññ-αñ╡αÑìαñ»αñ╕αÑìαññαÑñ\n23:21\n23 minutes, 21 seconds\nαñ╡αñ╛αñ░αñ╛αñúαñ╕αÑÇ αñ«αÑçαñé αñ¼αñ╛αñ░αñ┐αñ╢ αñòαÑç αñ▓αñ┐αñÅ αñùαñéαñùαñ╛ αñ¿αñªαÑÇ αñ«αÑçαñé αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛ αñ╡αñ┐αñ╢αÑçαñ╖ αñàαñ¿αÑüαñ╖αÑìαñáαñ╛αñ¿αÑñ αñºαñ╛αñ░αÑìαñ«αñ┐αñò αñàαñ¿αÑüαñ╖αÑìαñáαñ╛αñ¿ αñòαÑç αñ╕αñ╛αñÑ αñ╣αÑÇ αñ╕αñéαñùαÑÇαññ αñ╕αñ╛αñºαñ¿αñ╛ αñ¡αÑÇ αñòαÑÇ αñùαñêαÑñ\n23:32\n23 minutes, 32 seconds\n68 αñ╕αñ╛αñ▓ αñòαÑç αñ¿αñ┐αñÜαñ▓αÑç αñ╕αÑìαññαñ░ αñ¬αñ░ αñ¬αñ╣αÑüαñéαñÜαñ╛ αñ«αñªαÑüαñ░αñê αñòαÑç αñ¼αñ╛αñéαñº αñ«αÑçαñé αñ¬αñ╛αñ¿αÑÇαÑñ αññαñ«αñ┐αñ▓αñ¿αñ╛αñíαÑü αñòαÑç αñ¼αÑêαñù αñ¼αñ╛αñéαñº αñòαñ╛ αñ¼αñíαñ╝αñ╛ αñ╣αñ┐αñ╕αÑìαñ╕αñ╛ αñûαñ╛αñ▓αÑÇ αñ╣αÑê αñ¬αñ╛αñ¿αÑÇ αñ¬αÑÇαñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ αñöαñ░ αñ╕αñ¬αÑìαñ▓αñ╛αñê αñ¬αñ░ αñ¡αÑÇ αñçαñ╕αñòαñ╛ αñàαñ╕αñ░ αñ¬αñíαñ╝ αñ░αñ╣αñ╛ αñ╣αÑêαÑñ\n23:45\n23 minutes, 45 seconds\nαñÜαñ▓αññαÑç-αñÜαñ▓αññαÑç αñàαñ¼ αñ¿αÑîαñ╕αÑç αñ¿αÑìαñ»αÑéαñ£αñ╝ αñ«αÑçαñé αñåαñ¬αñòαÑï αñªαñ┐αñûαñ╛ αñªαÑçαññαÑç αñ╣αÑêαñé αñ╡αñ┐αñªαÑçαñ╢ αñòαÑÇ αñ¼αñíαñ╝αÑÇ αñûαñ¼αñ░αÑçαñéαÑñ\n23:52\n23 minutes, 52 seconds\nαñ¡αñ╛αñ░αññ αñ╕αÑç αñ╕αñéαñÜαñ╛αñ▓αñ┐αññ αñ╣αÑïαñ¿αÑç αñ╡αñ╛αñ▓αÑÇ αñ╡αñ┐αñ«αñ╛αñ¿ αñòαñéαñ¬αñ¿αñ┐αñ»αÑïαñé αñòαÑç αñ▓αñ┐αñÅ αñàαñ¡αÑÇ αñ¼αñéαñª αñ░αñ╣αÑçαñùαñ╛ αñ¬αñ╛αñòαñ┐αñ╕αÑìαññαñ╛αñ¿ αñòαñ╛ αñÅαñ»αñ░ αñ╕αÑìαñ¬αÑçαñ╕αÑñ αñ¬αñ╛αñòαñ┐αñ╕αÑìαññαñ╛αñ¿ αñ¿αÑç 23 αñ£αÑüαñ▓αñ╛αñê αññαñò αñàαñ¬αñ¿αñ╛ αñÅαñ»αñ░αñ╕αÑìαñ¬αÑçαñ╕ αñ¼αñéαñª αñ░αñûαñ¿αÑç αñòαñ╛ αñ½αÑêαñ╕αñ▓αñ╛ αñ▓αñ┐αñ»αñ╛αÑñ\n24:05\n24 minutes, 5 seconds\nαñ«αÑëαñ╕αÑìαñòαÑï αñ«αÑçαñé αñ░αñ╢αñ┐αñ»αñ╛ αñöαñ░ αññαÑüαñ░αÑìαñòαÑÇ αñòαÑÇ αñ╡αñ┐αñªαÑçαñ╢ αñ«αñéαññαÑìαñ░αñ┐αñ»αÑïαñé αñòαÑÇ αñ«αÑüαñ▓αñ╛αñòαñ╛αññαÑñ αññαÑüαñ░αÑìαñòαÑÇ αñ¿αÑç αñªαÑïαñ╣αñ░αñ╛αñê αñ»αÑéαñòαÑìαñ░αÑçαñ¿ αñ»αÑüαñªαÑìαñº αñ«αÑçαñé αñ«αñºαÑìαñ»αñ╕αÑìαñÑαñ╛ αñòαÑÇ αñ¬αÑçαñ╢αñòαñ╢αÑñ\n24:10\n24 minutes, 10 seconds\nαñ░αñ╢αñ┐αñ»αñ╛ αñ¿αÑç αñ»αÑéαñòαÑìαñ░αÑçαñ¿ αñòαÑÇ αñ»αÑéαñ░αÑïαñ¬αÑÇαñ» αñ»αÑéαñ¿αñ┐αñ»αñ¿ αñ«αÑçαñé αñÅαñéαñƒαÑìαñ░αÑÇ αñ¬αñ░ αñ╕αñ╡αñ╛αñ▓ αñëαñáαñ╛αñÅαÑñ\n24:15\n24 minutes, 15 seconds\nαñòαÑêαñ▓αñ┐αñ½αÑïαñ░αÑìαñ¿αñ┐αñ»αñ╛ αñòαÑÇ αñ░αñ┐αñ╡αñ░ αñ╕αñ╛αñçαñí αñòαñ╛αñëαñéαñƒαÑìαñ░αÑÇ αñ«αÑçαñé αññαÑçαñ£αÑÇ αñ╕αÑç αñ½αÑêαñ▓ αñ░αñ╣αÑÇ αñ╣αÑê αñ£αñéαñùαñ▓ αñ«αÑçαñé αñ▓αñùαÑÇ αñ╣αÑüαñê αñåαñùαÑñ\n24:19\n24 minutes, 19 seconds\nαñàαñ¼ αññαñò 2600 αñÅαñòαñíαñ╝ αñòαÑìαñ╖αÑçαññαÑìαñ░αÑñ αñçαñ╕αñòαÑÇ αñÜαñ¬αÑçαñƒ αñ«αÑçαñé αñåαñ»αñ╛αÑñ αñ½αñ╛αñ»αñ░ αñ½αñ╛αñçαñƒαñ░αÑìαñ╕ αñ▓αñùαñ╛αññαñ╛αñ░ αñòαñ░ αñ░αñ╣αÑÇ αñ╣αÑêαñé αñåαñù αñ¬αñ░ αñòαñ╛αñ¼αÑé αñ¬αñ╛αñ¿αÑç αñòαñ╛ αñ¬αÑìαñ░αñ»αñ╛αñ╕αÑñ\n24:27\n24 minutes, 27 seconds\nαñùαÑüαñ╡αñ╛αñƒαÑÇαñ«αñ╛αñ▓αñ╛ αñ«αÑçαñé αñàαñÜαñ╛αñ¿αñò αñåαñê αñ¼αñ╛αñóαñ╝ αñ¿αÑç αñ«αñÜαñ╛αñê αñ£αñ«αñòαñ░ αññαñ¼αñ╛αñ╣αÑÇαÑñ αññαÑçαñ£ αñ¼αñ╣αñ╛αñ╡ αñ«αÑçαñé αñ¼αñ╣ αñùαñÅ αñòαñê αñ╡αñ╛αñ╣αñ¿αÑñ\n24:32\n24 minutes, 32 seconds\nαñ¡αñ╛αñ░αÑÇ αñ¼αñ╛αñ░αñ┐αñ╢ αñòαÑç αñ¼αñ╛αñª αñ░αñ╛αñ╣αññ αñöαñ░ αñ¼αñÜαñ╛αñ╡ αñòαñ╛αñ░αÑìαñ» αñ£αñ╛αñ░αÑÇαÑñ\n24:38\n24 minutes, 38 seconds\nαñƒαÑçαñòαÑìαñ╕αñ╕ αñ«αÑçαñé αñ¡αñ╛αñ░αÑÇ αñ¼αñ╛αñ░αñ┐αñ╢ αñòαÑÇ αñ╡αñ£αñ╣ αñ╕αÑç αñ¼αñ╛αñóαñ╝ αñ£αÑêαñ╕αÑç αñ╣αñ╛αñ▓αñ╛αññ αñ¼αñ¿ αñùαñÅαÑñ αñæαñ╕αÑìαñƒαñ┐αñ¿ αñöαñ░ αñ╣αñ┐αñ▓ αñòαñéαñƒαÑìαñ░αÑÇ αñ«αÑçαñé αñ╣αÑüαñê αñ£αñ«αñòαñ░ αñ¼αñ╛αñ░αñ┐αñ╢αÑñ αññαñƒαÑÇαñ» αñçαñ▓αñ╛αñòαÑïαñé αñ«αÑçαñé αñ░αñ╣αñ¿αÑç αñ╡αñ╛αñ▓αÑç αñ▓αÑïαñùαÑïαñé αñòαÑï αñÅαññαñ┐αñ»αñ╛αññ αñ¼αñ░αññαñ¿αÑç αñòαÑç αñ¿αñ┐αñ░αÑìαñªαÑçαñ╢ αñªαñ┐αñÅ αñùαñÅ αñ╣αÑêαñéαÑñ\n24:58\n24 minutes, 58 seconds\nαñÅαñ¼αÑÇαñ¬αÑÇ αñ¿αÑìαñ»αÑéαñ£αñ╝ αñåαñ¬αñòαÑï αñ░αñûαÑç αñåαñùαÑçαÑñ	f	2026-06-17 12:27:12.209641
36	UCRWFSbif-RFENbBrSiez1DA	National	General	Transcript\nSearch transcript\n0:03\n3 seconds\nαñ½αÑìαñ░αñ╛αñéαñ╕ αñ«αÑçαñé αñåαñ£ αñ¬αÑÇαñÅαñ« αñ«αÑïαñªαÑÇ αñöαñ░ αñƒαÑìαñ░αñéαñ¬ αñòαÑÇ αñ«αÑüαñ▓αñ╛αñòαñ╛αññ αñ╣αÑïαñùαÑÇαÑñ αñªαÑïαñ¿αÑïαñé αñ¿αÑçαññαñ╛αñôαñé αñòαÑç αñ¼αÑÇαñÜ αñ╣αÑïαñùαÑÇ αñªαÑìαñ╡αñ┐αñ¬αñòαÑìαñ╖αÑÇαñ» αñ¼αñ╛αññαñÜαÑÇαññαÑñ αñ¡αñ╛αñ░αññ αñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñƒαÑìαñ░αÑçαñí αñíαÑÇαñ▓ αñ╣αÑïαñùαÑÇ αñ¼αñ╛αññαñÜαÑÇαññ αñòαñ╛ αñ«αÑüαñûαÑìαñ» αñÅαñ£αÑçαñéαñíαñ╛αÑñ\n0:15\n15 seconds\nαñ£αÑÇ7 αñ╕αñ«αÑìαñ«αÑçαñ▓αñ¿ αñ«αÑçαñé αñ¬αÑÇαñÅαñ« αñ«αÑïαñªαÑÇ αñ¿αÑç αñòαñ╣αñ╛ αñåαñ£ αñ╡αñ┐αñ╢αÑìαñ╡αñ╛αñ╕ αñòαÑÇ αñòαñ«αÑÇ αñ╕αÑç αñ£αÑéαñ¥ αñ░αñ╣αÑÇ αñ╣αÑê αñªαÑüαñ¿αñ┐αñ»αñ╛αÑñ\n0:19\n19 seconds\nαñ¼αñ╛αññαñÜαÑÇαññ αñòαÑç αñ£αñ░αñ┐αñÅ αñ╣αÑïαñ¿αñ╛ αñÜαñ╛αñ╣αñ┐αñÅ αññαñ¿αñ╛αñ╡αÑïαñé αñöαñ░ αñ»αÑüαñªαÑìαñºαÑïαñé αñòαñ╛ αñ╕αñ«αñ╛αñºαñ╛αñ¿αÑñ\n0:25\n25 seconds\nαñ¬αÑÇαñÅαñ« αñ«αÑïαñªαÑÇ αñ¿αÑç αñòαñ╣αñ╛ αñ¿αñ╛αñ╡αñ┐αñòαÑïαñé αñòαÑÇ αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñ╣αñ«αñ╛αñ░αñ╛ αñªαñ╛αñ»αñ┐αññαÑìαñ╡ αñ╣αÑêαÑñ αñ╕αÑüαñ¿αñ┐αñ╢αÑìαñÜαñ┐αññ αñòαñ░αñ¿αñ╛ αñ╣αÑïαñùαñ╛αÑñ\n0:29\n29 seconds\nαñ╕αñ«αÑüαñªαÑìαñ░αÑÇ αñ«αñ╛αñ░αÑìαñù αñ░αñ╣αÑçαñé αñ╕αÑüαñ░αñòαÑìαñ╖αñ┐αññ αñöαñ░ αñ¼αñ┐αñ¿αñ╛ αñíαñ░ αñòαÑç αñ¿αñ╛αñ╡αñ┐αñò αñòαñ░ αñ╕αñòαÑç αñòαñ╛αñ░αÑìαñ»αÑñ\n0:36\n36 seconds\nαñòαñ¿αñ╛αñíαñ╛ αñòαÑç αñ¬αÑìαñ░αñºαñ╛αñ¿αñ«αñéαññαÑìαñ░αÑÇ αñòαÑç αñ╕αñ╛αñÑ αñ¬αÑÇαñÅαñ« αñ«αÑïαñªαÑÇ αñòαÑÇ αñ╡αñ┐αñ¬αñòαÑìαñ╖αÑÇαñ» αñ¼αÑêαñáαñò αñ╣αÑüαñêαÑñ αñòαñ╣αñ╛ αñòαñ┐ αñèαñ░αÑìαñ£αñ╛ αñòαÑç αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñòαñ¿αñ╛αñíαñ╛ αñ╣αÑï αñ╕αñòαññαñ╛ αñ╣αÑê αñ¬αÑìαñ░αñ«αÑüαñû αñ¡αñ╛αñùαÑÇαñªαñ╛αñ░αÑñ αñòαñ¿αñ╛αñíαñ╛ αñòαÑç αñ¬αÑÇαñÅαñ« αñ¿αÑç αñòαñ╣αñ╛ αñàαñ¬αñ¿αÑç αñ╡αÑìαñ»αñ╛αñ¬αñ╛αñ░ αñòαÑï αñªαÑïαñùαÑüαñ¿αñ╛ αñòαñ░αñ¿αñ╛ αñ▓αñòαÑìαñ╖αÑìαñ» αñ╣αÑêαÑñ\n0:49\n49 seconds\nαñ½αÑìαñ░αñ╛αñéαñ╕ αñ«αÑçαñé αñ¬αÑÇαñÅαñ« αñ«αÑïαñªαÑÇ αñòαÑÇ αñ¼αÑìαñ░αñ┐αñƒαñ┐αñ╢ αñ¬αÑìαñ░αñºαñ╛αñ¿αñ«αñéαññαÑìαñ░αÑÇ αñòαÑç αñ╕αñ╛αñÑ αñ«αÑçαñé αñªαÑìαñ╡αñ┐αñ¬αñòαÑìαñ╖αÑÇαñ» αñ╡αñ╛αñ░αÑìαññαñ╛αÑñ αñ»αÑéαñÅαñê αñòαÑç αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ¬αññαñ┐ αñòαÑç αñ╕αñ╛αñÑ αñ¡αÑÇ αñ╣αÑüαñê αñªαÑìαñ╡αñ┐αñ¬αñòαÑìαñ╖αÑÇαñ» αñ¼αñ╛αññαñÜαÑÇαññαÑñ\n1:00\n1 minute\nαñ½αÑìαñ░αñ╛αñéαñ╕ αñ«αÑçαñé αñòαñê αñªαÑçαñ╢αÑïαñé αñòαÑç αñ¿αÑçαññαñ╛αñôαñé αñòαÑç αñ╕αñ╛αñÑ αñ¬αÑÇαñÅαñ« αñ«αÑïαñªαÑÇ αñòαÑÇ αñ«αÑüαñ▓αñ╛αñòαñ╛αññαÑñ αñ£αñ╛αñ¬αñ╛αñ¿, αñªαñòαÑìαñ╖αñ┐αñú αñòαÑïαñ░αñ┐αñ»αñ╛, αñòαÑçαñ¿αÑìαñ»αñ╛, αñ»αÑéαñÅαñê αñòαÑç αñ¿αÑçαññαñ╛αñôαñé αñòαÑç αñ╕αñ╛αñÑ αñ╣αÑüαñê αñ╡αñ┐αñ¬αñòαÑìαñ╖αÑÇαñ» αñ¼αÑêαñáαñò, αñ╡αÑìαñ»αñ╛αñ¬αñ╛αñ░ αñ╕αñ╣αñ┐αññ αñòαñê αñàαñ╣αñ« αñ«αÑüαñªαÑìαñªαÑïαñé αñ¬αñ░ αñÜαñ░αÑìαñÜαñ╛ αñ╣αÑüαñêαÑñ\n1:13\n1 minute, 13 seconds\nαñ½αÑìαñ░αñ╛αñéαñ╕ αñòαÑç αñåαñ»αñ╛αñ¿ αñ«αÑçαñé G7 αñ╢αñ┐αñûαñ░ αñ╕αñ«αÑìαñ«αÑçαñ▓αñ¿αÑñ αñ¬αÑÇαñÅαñ« αñ«αÑïαñªαÑÇ αñ¿αÑç αñ½αÑêαñ«αñ┐αñ▓αÑÇ αñ½αÑïαñƒαÑï αñ«αÑçαñé αñ╣αñ┐αñ╕αÑìαñ╕αñ╛ αñ▓αñ┐αñ»αñ╛αÑñ\n1:18\n1 minute, 18 seconds\nαñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ¬αññαñ┐ αñƒαÑìαñ░αñéαñ¬ αñòαÑï αñ╕αñ╣αñ╛αñ░αñ╛ αñªαÑçαññαÑç [αñ╕αñéαñùαÑÇαññ] αñ¿αñ£αñ░ αñåαñÅαÑñ\n1:22\n1 minute, 22 seconds\nαñöαñ░ αñ«αÑçαñé αññαÑçαñ▓ αñƒαÑêαñéαñòαñ░αÑìαñ╕ αñòαÑÇ αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñòαÑç αñ▓αñ┐αñÅ αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñòαñ╛ αñ¿αñ»αñ╛ αñ¬αÑìαñ▓αñ╛αñ¿αÑñ αñôαñ«αñ╛αñ¿ αñöαñ░ αñ»αÑéαñÅαñê αñòαÑç αññαñƒ αñòαÑç αñ¬αñ╛αñ╕ αñ¼αñíαñ╝αÑç αññαÑçαñ▓ αñƒαÑêαñéαñòαñ░αÑìαñ╕ αñ«αÑçαñé αññαÑçαñ▓ αñƒαÑìαñ░αñ╛αñéαñ╕αñ½αñ░ αñòαñ░αññαÑç αñ╣αÑêαñé αñ¢αÑïαñƒαÑç αññαÑçαñ▓ αñƒαÑêαñéαñòαñ░αÑñ αñêαñ░αñ╛αñ¿ αñòαÑç αñàαñºαñ┐αñòαñ╛αñ░ αñòαÑìαñ╖αÑçαññαÑìαñ░ αñ╕αÑç αñ¼αñ╛αñ╣αñ░ αñ░αñ╣αñòαñ░ αñ╣αÑï αñ░αñ╣αñ╛ αñ╣αÑê αñòαñ╛αñ░αÑìαñ»αÑñ\n1:34\n1 minute, 34 seconds\nαñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñòαÑç αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ¬αññαñ┐ αñíαÑëαñ¿αñ▓αÑìαñí αñƒαÑìαñ░αñéαñ¬ αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñêαñ░αñ╛αñ¿ αñòαÑç αñ¬αñ╛αñ╕ αñ¿αñ╣αÑÇαñé αñ╣αÑïαñéαñùαÑç αñ¬αñ░αñ«αñ╛αñúαÑü αñ╣αñÑαñ┐αñ»αñ╛αñ░αÑñ αñ╕αñ«αñ¥αÑîαññαÑç αñòαÑç 60 αñªαñ┐αñ¿ αñòαÑç αñ¼αñ╛αñª αñ¡αÑÇ αñ╡αñ╣ αñ¼αñùαÑêαñ░ αñòαñ┐αñ╕αÑÇ αñ½αÑÇαñ╕ αñòαÑç αñûαÑïαñ▓ αñªαÑçαñùαñ╛ αñ╣αÑëαñ░αÑìαñ«αÑïαñ╕αÑñ\n1:45\n1 minute, 45 seconds\nαñ╣αÑëαñ░αÑìαñ«αÑïαñ╕ αñòαÑï αñ▓αÑçαñòαñ░ αñêαñ░αñ╛αñ¿ αñòαñ╛ αñ¼αñíαñ╝αñ╛ αñ¼αñ»αñ╛αñ¿αÑñ αñòαñ╣αñ╛ αñòαñ┐ αñ╕αÑìαñƒαÑçαñƒ αñöαñ░ αñ½αÑëαñ░αñ«αÑüαñ╕ αñ¬αñ░ αñàαñ¬αñ¿αñ╛ αñ¿αñ┐αñ»αñéαññαÑìαñ░αñú αñ¼αñ¿αñ╛αñÅ αñ░αñûαÑçαñùαñ╛ αññαÑçαñ╣αñ░αñ╛αñ¿αÑñ αñ╣αÑëαñ░αÑìαñ«αÑéαñ╕ αñ╕αÑç αñêαñ░αñ╛αñ¿ αñòαÑÇ αñ¿αñ┐αñùαñ░αñ╛αñ¿αÑÇ αñ«αÑçαñé αñ╣αÑÇ αñùαÑüαñ£αñ░αÑçαñéαñùαÑç αñ£αñ╣αñ╛αñ£αÑñ\n1:55\n1 minute, 55 seconds\nαñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñçαñéαñƒαÑçαñ▓αñ┐αñ£αÑçαñéαñ╕ αñ░αñ┐αñ¬αÑïαñ░αÑìαñƒαÑìαñ╕ αñòαÑç αñ╣αñ╡αñ╛αñ▓αÑç αñ╕αÑç αñ£αñ╛αñ¿αñòαñ╛αñ░αÑÇαÑñ αñêαñ░αñ╛αñ¿ αñ¿αÑç αñ»αñ╣ αñªαñ┐αñûαñ╛ αñªαñ┐αñ»αñ╛ αñòαñ┐ αñ╡αÑï αñ£αñ¼ αñÜαñ╛αñ╣αÑç αñ╕αÑìαñƒαÑçαñƒ αñæαñ½ αñ╣αÑëαñ░αÑìαñ«αÑéαñ╕ αñòαÑï αñàαñ╕αñ░αñªαñ╛αñ░ αññαñ░αÑÇαñòαÑç αñ╕αÑç\n2:02\n2 minutes, 2 seconds\nαñ¼αñéαñª αñòαñ░ αñ╕αñòαññαñ╛ αñ╣αÑêαÑñ [αñ╕αñéαñùαÑÇαññ] αññαÑçαñ╣αñ░αñ╛αñ¿ αñòαÑï αñ«αñ┐αñ▓αñ╛ αñùαÑìαñ▓αÑïαñ¼αñ▓ αñçαñòαÑëαñ¿αñ«αÑÇ αñ¬αñ░ αñªαñ¼αñ╛αñ╡ αñ¼αñ¿αñ╛αñ¿αÑç αñòαñ╛ αñÅαñò αñ¿αñ»αñ╛ αñ£αñ░αñ┐αñ»αñ╛αÑñ\n2:09\n2 minutes, 9 seconds\nαñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñçαñéαñƒαÑçαñ▓αñ┐αñ£αÑçαñéαñ╕ αñ░αñ┐αñ¬αÑïαñ░αÑìαñƒαÑìαñ╕ αñ«αÑçαñé αñªαñ╛αñ╡αñ╛ αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛ αñ╣αÑê αñòαñ┐ αñêαñ░αñ╛αñ¿ αñòαÑç αñ¬αñ╛αñ╕ αñàαñ¼ αñ¡αÑÇ αñ¼αñíαñ╝αÑÇ αñ╕αñéαñûαÑìαñ»αñ╛ αñ«αÑçαñé αñ«αñ┐αñ╕αñ╛αñçαñ▓αÑçαñé αñ╣αÑêαñéαÑñ αñíαÑìαñ░αÑïαñ¿ αñöαñ░ αñ¿αÑîαñ╕αÑêαñ¿αñ┐αñò αñ╕αñéαñ╕αñ╛αñºαñ¿ αñ¡αÑÇ αñ«αÑîαñ£αÑéαñª αñ╣αÑêαñéαÑñ αñ╕αñ«αÑüαñªαÑìαñ░αÑÇ αñ«αñ╛αñ░αÑìαñùαÑïαñé αñòαÑç αñ▓αñ┐αñÅ αñ½αñ┐αñ░ αñ¼αñ¿ αñ╕αñòαññαñ╛ αñ╣αÑê αñûαññαñ░αñ╛αÑñ\n2:22\n2 minutes, 22 seconds\nαñ£αñ▓αÑìαñª αñ╕αñ╛αñ«αñ¿αÑç αñåαñÅαñùαñ╛ αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñêαñ░αñ╛αñ¿ αñíαÑÇαñ▓ αñòαñ╛ αñíαÑìαñ░αñ╛αñ½αÑìαñƒαÑñ αñíαÑëαñ¿αÑìαñí αñƒαÑìαñ░αñéαñ¬ αñ¼αÑïαñ▓αÑç αñ╡αÑï αñûαÑüαñª αñ╣αÑÇ αñ£αñ╛αñ░αÑÇ αñòαñ░αÑçαñéαñùαÑç αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñêαñ░αñ╛αñ¿ αñíαÑÇαñ▓ αñòαñ╛ αñíαÑìαñ░αñ╛αñ½αÑìαñƒαÑñ αñòαñ╣αñ╛ αñòαñ┐ αñíαÑÇαñ▓ αñòαñ╛ αñÅαñò-αñÅαñò αñ╢αñ¼αÑìαñª αñ¬αñóαñ╝αñòαñ░ αñ╕αÑüαñ¿αñ╛αñèαñéαñùαñ╛αÑñ\n2:30\n2 minutes, 30 seconds\nαñ¼αñ╣αÑüαññ αñàαñÜαÑìαñ¢αÑÇ αññαñ░αñ╣ αñ╕αÑç αñ¼αñ¿ αñ░αñ╣αñ╛ αñ╣αÑê αñÅαñ«αñôαñ»αÑéαÑñ\n2:34\n2 minutes, 34 seconds\nαñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ¬αññαñ┐ αñíαÑïαñ¿αñ╛αñ▓αÑìαñí αñƒαÑìαñ░αñéαñ¬ αñ¿αÑç αñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑÇ αñòαñ╛αñ░αñ╡αñ╛αñ╣αÑÇ αñòαÑï αñ▓αÑçαñòαñ░ αñ¿αñ╛αñ░αñ╛αñ£αñùαÑÇ αñ£αññαñ╛αñêαÑñ\n2:38\n2 minutes, 38 seconds\nαñòαñ╣αñ╛ αñòαñ┐ αñ╕αñ«αñ¥αÑîαññαÑç αñ╕αÑç 2 αñÿαñéαñƒαÑç αñ¬αñ╣αñ▓αÑç αñ¼αÑêαñ░αÑéαññ αñ«αÑçαñé αñçαñ£αñ░αñ╛αñçαñ▓ αñòαñ╛ αñ╣αñ«αñ▓αñ╛ αñ╣αÑïαñ¿αñ╛ αñëαñ¿αÑìαñ╣αÑçαñé αñàαñÜαÑìαñ¢αñ╛ αñ¿αñ╣αÑÇαñé αñ▓αñùαñ╛αÑñ\n2:47\n2 minutes, 47 seconds\nαñíαÑïαñ¿αñ▓αÑìαñí αñƒαÑìαñ░αñéαñ¬ αñ¿αÑç αñ¿αÑçαññ αñ»αñ╛αñ╣αÑé αñ¬αñ░ αñòαñ╕αñ╛ αññαñéαñ£ αñòαñ╣αñ╛ αñòαñ┐ αñ╣αñ¼αÑìαÑüαñ▓αñ╛ αñòαÑç αñÅαñò αñ¿αÑçαññαñ╛ αñòαÑï αñûαÑïαñ£αñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ αñ¬αÑéαñ░αÑç αñàαñ¬αñ╛αñ░αÑìαñƒαñ«αÑçαñéαñƒ αñòαÑï αñëαñíαñ╝αñ╛αñ¿αñ╛ αñ╕αñ╣αÑÇ αñ¿αñ╣αÑÇαñé αñ╣αÑêαÑñ\n2:53\n2 minutes, 53 seconds\nαñ£αñ░αÑéαñ░αÑÇ αñ¿αñ╣αÑÇαñé αñçαñ«αñ╛αñ░αññ αñ«αÑçαñé αñ░αñ╣αñ¿αÑç αñ╡αñ╛αñ▓αÑç αñ╕αñ¡αÑÇ αñ▓αÑïαñù αñ╣αñ┐αñ£αñ¼αÑüαñ▓αÑìαñ▓αñ╛ αñ╕αÑç αñ£αÑüαñíαñ╝αÑç αñ╣αÑüαñÅ αñ╣αÑêαñéαÑñ\n2:59\n2 minutes, 59 seconds\nαñíαÑëαñ¿αñ▓αÑìαñí αñƒαÑìαñ░αñéαñ¬ αñòαÑÇ αñ¿αÑçαññαñ¿αÑìαñ»αñ╛ αñòαÑï αñ╣αñ┐αñªαñ╛αñ»αññ αñòαñ╣αñ╛ αñòαñ┐ αñ¿αÑçαññαñ¿ αñ»αñ╛αÑé αñòαÑï αñ▓αÑçαñ¼αñ¿αñ╛αñ¿ αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñ╣αÑïαñ¿αñ╛ αñÜαñ╛αñ╣αñ┐αñÅ αñ£αÑìαñ»αñ╛αñªαñ╛ αñ£αñ┐αñ«αÑìαñ«αÑçαñªαñ╛αñ░αÑñ αñêαñ░αñ╛αñ¿ αñíαÑÇαñ▓ αñ¬αñ░ αñ¬αñíαñ╝ αñ░αñ╣αñ╛ αñ╣αÑê αñ▓αÑçαñ¼αñ¿αñ╛αñ¿ αñ╣αñ«αñ▓αÑïαñé αñòαñ╛ αñ¿αñòαñ╛αñ░αñ╛αññαÑìαñ«αñò αñàαñ╕αñ░αÑñ\n3:10\n3 minutes, 10 seconds\nαñêαñ░αñ╛αñ¿ αñòαÑç αñ╡αñ┐αñªαÑçαñ╢ αñ«αñéαññαÑìαñ░αÑÇ αñàαñ¼αÑìαñ¼αñ╛αñ╕ αñ░αñ╛αñòαÑìαñ╖αñ╢αÑÇ αñòαñ╛ αñ¼αñ»αñ╛αñ¿αÑñ αñòαñ╣αñ╛ αñòαñ┐ αñ»αÑüαñªαÑìαñº αññαñ¼ αññαñò αñûαññαÑìαñ« αñ¿αñ╣αÑÇαñé αñ╣αÑïαñùαñ╛ αñ£αñ¼ αññαñò αñçαñ£αñ░αñ╛αñçαñ▓ αñ╕αÑçαñ¿αñ╛ αñ▓αÑçαñ¼αñ¿αñ╛αñ¿ αñ«αÑçαñé αñòαñ¼αÑìαñ£αÑç αñ╡αñ╛αñ▓αÑç αñòαÑìαñ╖αÑçαññαÑìαñ░ αñ╕αÑç αñ╡αñ╛αñ¬αñ╕ [αñ╕αñéαñùαÑÇαññ] αñ¿αñ╣αÑÇαñé αñ╣αñƒ αñ£αñ╛αññαÑÇαÑñ\n3:19\n3 minutes, 19 seconds\nαñêαñ░αñ╛αñ¿ αñ¿αÑç αñªαÑÇ αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñòαÑï αñÜαÑçαññαñ╛αñ╡αñ¿αÑÇαÑñ αñêαñ░αñ╛αñ¿αÑÇ αñ╡αñ┐αñªαÑçαñ╢ αñ«αñéαññαÑìαñ░αÑÇ αñàαñ¼αÑìαñ¼αñ╛αñ╕ αñ░αñ╛αñòαÑìαñ╖αÑÇ αñòαñ╛ αñ¼αñ»αñ╛αñ¿αÑñ αñòαñ╣αñ╛ αñ▓αÑçαñ¼αñ¿αñ╛αñ¿ αñ¬αñ░ αñçαñ£αñ░αñ╛αñçαñ▓ αñòαñ╛ αñòαÑïαñê αñ¡αÑÇ αñ╣αñ«αñ▓αñ╛ αñ╕αñ«αñ¥αÑîαññαÑç αñòαñ╛ αñ╣αÑïαñùαñ╛ αñëαñ▓αÑìαñ▓αñéαñÿαñ¿αÑñ\n3:27\n3 minutes, 27 seconds\nαñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñêαñ░αñ╛αñ¿ αñ╕αñ«αñ¥αÑîαññαÑç αñòαÑï αñ▓αÑçαñòαñ░ αñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑÇ αñÜαñ┐αñéαññαñ╛ αñ¼αñóαñ╝αÑÇαÑñ αñ░αñ┐αñ¬αÑïαñ░αÑìαñƒ αñòαÑç αñàαñ¿αÑüαñ╕αñ╛αñ░ αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñ¿αÑç αñÅαñ«αñôαñ»αÑé αñòαñ╛ αñ¬αÑéαñ░αñ╛ αñ«αñ╕αÑîαñªαñ╛ αñ╕αñ╛αñ¥αñ╛ αñòαñ░αñ¿αÑç αñ╕αÑç [αñ╕αñéαñùαÑÇαññ] αñçαñéαñòαñ╛αñ░ αñòαñ┐αñ»αñ╛αÑñ αñçαñ£αñ░αñ╛αñçαñ▓ αñ¿αÑç αñòαÑÇ αñÑαÑÇ αñ╕αñ«αñ¥αÑîαññαÑç αñòαñ╛ αñ¬αÑéαñ░αñ╛ αñ«αñ╕αÑîαñªαñ╛ αñªαÑçαñûαñ¿αÑç αñòαÑÇ αñ«αñ╛αñéαñùαÑñ\n3:38\n3 minutes, 38 seconds\nαñêαñ░αñ╛αñ¿ αñòαÑç αñ╕αñ╛αñÑ αñ╕αñ«αñ¥αÑîαññαñ╛ αñ▓αñ╛αñùαÑé αñ╣αÑïαñ¿αÑç αñòαÑç αñ¼αñ╛αñª αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñ▓αñùαñ╛ αñ╕αñòαññαñ╛ αñ╣αÑê αñ░αñ╢αñ┐αñ»αñ╛ αññαÑçαñ▓ αñ╢αñ┐αñ¬αñ«αÑçαñéαñƒ αñ¬αñ░ αñÅαñò αñ¼αñ╛αñ░ αñ½αñ┐αñ░ αñ╕αÑç αñ¬αÑìαñ░αññαñ┐αñ¼αñéαñºαÑñ αñíαÑëαñ¿αÑìαñí αñƒαÑìαñ░αñéαñ¬ αñ¿αÑç αñ╕αñéαñòαÑçαññ αñªαñ┐αñÅαÑñ αñòαñ╣αñ╛ αñ╣αÑëαñ░αÑìαñ«αÑïαñ╕ αñ╕αÑç αñåαñ╡αñ╛αñ£αñ╛αñ╣αÑÇ αñ╕αñ╛αñ«αñ╛αñ¿αÑìαñ» αñ╣αÑïαññαÑç αñ╣αÑÇ αñ▓αÑç αñ╕αñòαññαÑç αñ╣αÑêαñé αñ½αÑêαñ╕αñ▓αÑçαÑñ\n3:50\n3 minutes, 50 seconds\nαñòαññαñ░ αñ¿αÑç αñ£αññαñ╛αñ»αñ╛ αñ¡αñ░αÑïαñ╕αñ╛αÑñ αñòαñ╣αñ╛ αñòαñ┐ αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñêαñ░αñ╛αñ¿ αñíαÑÇαñ▓ αñòαÑç αñ¼αñ╛αñª αñûαÑüαñ▓ αñ£αñ╛αñÅαñùαñ╛ αñ╕αÑìαñƒαÑçαñƒ αñæαñ½ αñ╣αÑëαñ░αÑìαñ«αÑïαñ╕αÑñ\n3:54\n3 minutes, 54 seconds\nαñèαñ░αÑìαñ£αñ╛ αñåαñ¬αÑéαñ░αÑìαññαñ┐ αñ╕αñ╛αñ«αñ╛αñ¿αÑìαñ» [αñ╕αñéαñùαÑÇαññ] αñ╣αÑïαñ¿αÑç αñòαÑÇ αñ£αññαñ╛αñê αñëαñ«αÑìαñ«αÑÇαñªαÑñ\n3:59\n3 minutes, 59 seconds\nαñªαñòαÑìαñ╖αñ┐αñúαÑÇ αñ▓αÑçαñ¼αñ¿αñ╛αñ¿ αñ«αÑçαñé αñçαñ£αñ░αñ╛αñçαñ▓αÑÇ αñ╕αÑçαñ¿αñ╛ αñòαÑç αñ╣αñ╡αñ╛αñê αñ╣αñ«αñ▓αÑç αñ£αñ╛αñ░αÑÇ αñ╣αÑêαñéαÑñ αñÜαñ╛αñ░αÑïαñé αñòαÑÇ αñ«αÑîαññ, αñòαñê αñÿαñ╛αñ»αñ▓αÑñ\n4:04\n4 minutes, 4 seconds\nαñçαñ£αñ░αñ╛αñçαñ▓αÑÇ αñ╕αÑçαñ¿αñ╛ αñ¿αÑç αñÅαñò αñòαÑç αñ¼αñ╛αñª αñÅαñò αñòαñ░αÑç αñ╣αñ╡αñ╛αñê αñ╣αñ«αñ▓αÑçαÑñ\n4:08\n4 minutes, 8 seconds\nαñªαñòαÑìαñ╖αñ┐αñúαÑÇ αñ▓αÑçαñ¼αñ¿αñ╛αñ¿ αñ«αÑçαñé αñ╣αÑ¢αñ¼αÑüαñ▓αñ╛ αñòαÑÇ αñ░αÑëαñòαÑçαñƒ αñ▓αÑëαñ¿αÑìαñÜαñ┐αñéαñù αñ╕αñ╛αñçαñƒ αñ¬αñ░ αñåαñêαñ£αÑÇαñÅαñ½ αñòαñ╛ αñ╣αñ«αñ▓αñ╛αÑñ αñòαÑç αñ╣αñ«αñ▓αÑïαñé αñòαÑç αñ£αñ╡αñ╛αñ¼ αñ«αÑçαñé αñçαñ£αñ░αñ╛αñçαñ▓αÑÇ αñ╕αÑçαñ¿αñ╛ αñòαñ╛ αñ¬αñ▓αñƒαñ╡αñ╛αñ░αÑñ\n4:17\n4 minutes, 17 seconds\nαñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑç αñ╣αñ«αñ▓αÑïαñé αñ╕αÑç αññαñ¼αñ╛αñ╣ αñ╣αÑüαñå αñªαñòαÑìαñ╖αñ┐αñúαÑÇ αñ▓αÑçαñ¼αñ¿αñ╛αñ¿ αñòαñ╛ αñ¿αñ╡αñ╛αñ¼αÑÇ αñ╢αñ╣αñ░αÑñ αñçαñ«αñ╛αñ░αññαÑçαñé, αñ¼αñ╛αñ£αñ╛αñ░, αñ¼αÑüαñ¿αñ┐αñ»αñ╛αñªαÑÇ αñóαñ╛αñéαñÜαÑç, αñûαñéαñíαñ░ αñ«αÑçαñé αññαñ¼αÑìαñªαÑÇαñ▓αÑñ [αñ╕αñéαñùαÑÇαññ] αñÿαñ░ αñ▓αÑîαñƒ αñ░αñ╣αÑç αñ▓αÑïαñùαÑïαñé αñ¿αÑç αñ¼αñ»αñ╛αñé αñòαñ┐αñ»αñ╛ αñàαñ¬αñ¿αñ╛ αñªαñ░αÑìαñªαÑñ\n4:27\n4 minutes, 27 seconds\nαñàαñ«αÑçαñ░αñ┐αñòαñ╛, αñêαñ░αñ╛αñ¿ αñ╢αñ╛αñéαññαñ┐ αñ╕αñ«αñ¥αÑîαññαÑç αñòαñ╛ αñ╕αñ┐αñ░αÑìαñ½ αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░ αñ¿αÑç αñ╕αÑìαñ╡αñ╛αñùαññ αñòαñ┐αñ»αñ╛αÑñ αñ»αÑéαñÅαñ¿ αñ¿αÑç αñ¼αññαñ╛αñ»αñ╛ αñ«αñ£αñ┐αñª αñ¬αÑéαñ░αÑìαñ╡ αñòαÑç αñ▓αñ┐αñÅ αñàαñ╣αñ« αñ╡αÑïαñƒαÑñ αñ»αñ«αñ¿ αñ«αÑçαñé αñ╢αñ╛αñéαññαñ┐ αñ¬αÑìαñ░αñ»αñ╛αñ╕αÑïαñé αñòαÑï αñ¡αÑÇ αñ«αñ┐αñ▓ αñ╕αñòαññαÑÇ αñ╣αÑê αñ░αñ½αÑìαññαñ╛αñ░αÑñ\n4:36\n4 minutes, 36 seconds\nαññαÑüαñ░αÑìαñòαÑÇ αñ¿αÑç αñçαñ£αñ░αñ╛αñçαñ▓ αñ¬αñ░ αñ▓αñùαñ╛αñ»αñ╛ αñ╢αñ╛αñéαññαñ┐ αñ╕αñ«αñ¥αÑîαññαÑç αñ«αÑçαñé αñ¼αñ╛αñºαñ╛ αñíαñ╛αñ▓αñ¿αÑç αñòαñ╛ αñåαñ░αÑïαñ¬αÑñ αñ╡αñ┐αñªαÑçαñ╢ αñ«αñéαññαÑìαñ░αÑÇ αñ╣αñ╕αñ╛αñ¿ αñûαÑüαñªαñ╛αñ¿ αñ¼αÑïαñ▓αÑç αñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñ╕αñ╛αñ¥αñ╛ αñòαÑéαñƒαñ¿αÑÇαññαñ┐αñò αñ░αÑüαñû αñàαñ¬αñ¿αñ╛αñ¿αÑç αñòαÑÇ αñ£αñ░αÑéαñ░αññ [αñ╕αñéαñùαÑÇαññ] αñ╣αÑêαÑñ\n4:46\n4 minutes, 46 seconds\nαñ»αÑéαñÅαñ¿ αñòαñ╛ αñªαñ╛αñ╡αñ╛ αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñêαñ░αñ╛αñ¿ αñòαÑç αñ¼αÑÇαñÜ αñ╣αÑïαñ¿αÑç αñ£αñ╛ αñ░αñ╣αÑç αñ╢αñ╛αñéαññαñ┐ αñ╕αñ«αñ¥αÑîαññαÑç αñòαÑç αñ¼αñ╛αñª αñ▓αÑçαñ¼αñ¿αñ╛ αñ«αÑçαñé αñ╕αñéαñÿαñ░αÑìαñ╖ αñ«αÑçαñé αñåαñê αñ╣αÑê αñòαñ«αÑÇαÑñ αñ╣αñ╡αñ╛αñê αñëαñ▓αÑìαñ▓αñéαñÿαñ¿ αñöαñ░ αñ«αñ┐αñ╕αñ╛αñçαñ▓ αñ╣αñ«αñ▓αÑïαñé αñòαÑÇ αñÿαñƒαñ¿αñ╛αñÅαñé αñ¡αÑÇ αñòαñ« αñ╣αÑüαñê αñ╣αÑêαÑñ\n4:58\n4 minutes, 58 seconds\nαñ»αñ«αñ¿ αñòαÑÇ αñ░αñ╛αñ£αñºαñ╛αñ¿αÑÇ αñ╕αñ¿αñ╛ αñ«αÑçαñé αñ▓αÑïαñùαÑïαñé αñòαñ╛ αñ¬αÑìαñ░αñªαñ░αÑìαñ╢αñ¿ αñ╣αÑüαñåαÑñ αñ½αñ┐αñ▓αñ┐αñ╕αÑìαññαÑÇαñ¿ αñ▓αÑçαñ¼αñ¿αñ╛αñ¿ αñòαÑç αñ╕αñ«αñ░αÑìαñÑαñ¿ αñ¬αÑìαñ░αñªαñ░αÑìαñ╢αñ¿ αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñ¿αñ╛αñ░αÑçαñ¼αñ╛αñ£αÑÇ\n5:06\n5 minutes, 6 seconds\nαñ¬αÑÇαñô αñöαñ░ αñ£αÑçαñòαÑç αñ«αÑçαñé αñ¬αÑìαñ░αñªαñ░αÑìαñ╢αñ¿ αñòαÑç αñ¼αÑÇαñÜ αñ░αñ╛αñ╢αñ¿ αñ╕αñ¬αÑìαñ▓αñ╛αñê αñ░αÑïαñòαñ¿αÑç αñòαñ╛ αñåαñ░αÑïαñ¬ αñ¬αñéαñ£αñ╛αñ¼ αñ╣αñ╛αñêαñ╡αÑç αñòαñéαñƒαÑìαñ░αÑïαñ▓ αñ¬αÑüαñ▓αñ┐αñ╕ αñöαñ░ αñ░αÑçαñéαñ£αñ░αÑìαñ╕ αñ¿αÑç αñ╢αñ╣αñ░αÑïαñé αñòαÑÇ αñ╕αÑÇαñ«αñ╛ αñ¬αñ░\n5:13\n5 minutes, 13 seconds\nαñ░αÑïαñòαÑÇ αñòαñê αñùαñ╛αñíαñ╝αñ┐αñ»αñ╛αñé αñ╕αñ░αñòαñ╛αñ░ αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñÜαñ▓ αñ░αñ╣αÑç αñåαñéαñªαÑïαñ▓αñ¿ αñòαÑï αñòαÑüαñÜαñ▓αñ¿αÑç αñòαÑÇ αñòαÑïαñ╢αñ┐αñ╢αÑñ\n5:19\n5 minutes, 19 seconds\nαñ¡αñ╛αñ░αññ αñ«αÑçαñé αñ╕αñéαñÜαñ╛αñ▓αñ┐αññ αñ╣αÑïαñ¿αÑç αñ╡αñ╛αñ▓αÑÇ αñ╡αñ┐αñ«αñ╛αñ¿ αñòαñéαñ¬αñ¿αñ┐αñ»αÑïαñé αñòαÑç αñ▓αñ┐αñÅ αñàαñ¡αÑÇ αñ¼αñéαñª αñ░αñ╣αÑçαñùαñ╛ αñ¬αñ╛αñò αñòαñ╛ αñÅαñ»αñ░ αñ╕αÑìαñ¬αÑçαñ╕αÑñ αñ¬αñ╛αñòαñ┐αñ╕αÑìαññαñ╛αñ¿ αñ¿αÑç 23 αñ£αÑüαñ▓αñ╛αñê αññαñò αñàαñ¬αñ¿αñ╛ αñÅαñ»αñ░ αñ╕αÑìαñ¬αÑçαñ╕ αñ¼αñéαñª αñ░αñûαñ¿αÑç αñòαñ╛ αñ½αÑêαñ╕αñ▓αñ╛ αñ▓αñ┐αñ»αñ╛αÑñ\n5:29\n5 minutes, 29 seconds\nαñ╕αñ╛αñéαñ╕αñªαÑïαñé αñòαÑç αñƒαÑéαñƒαñ¿αÑç αñòαÑÇ αñûαñ¼αñ░αÑïαñé αñòαÑç αñ¼αÑÇαñÜ αñëαñªαÑìαñºαñ╡ αñ¿αÑç αñ¼αÑüαñ▓αñ╛αñê αñ╡αñ┐αñºαñ╛αñ»αñòαÑïαñé αñòαÑÇ αñ¼αÑêαñáαñòαÑñ 22 αñ£αÑéαñ¿ αñòαÑï αñ╢αñ╛αñ« 4:00 αñ¼αñ£αÑç αñ«αÑüαñéαñ¼αñê αñ«αÑçαñé αñ╣αÑïαñùαÑÇ αñ«αÑÇαñƒαñ┐αñéαñùαÑñ\n5:38\n5 minutes, 38 seconds\nαñ╢αñ┐αñ╡αñ╕αÑçαñ¿αñ╛ αñëαñªαÑìαñºαñ╡ αñùαÑüαñá αñ«αÑçαñé αñƒαÑéαñƒ αñòαÑÇ αñÜαñ░αÑìαñÜαñ╛αñÅαñéαÑñ\n5:40\n5 minutes, 40 seconds\nαñ╕αÑéαññαÑìαñ░αÑïαñé αñòαÑç αñàαñ¿αÑüαñ╕αñ╛αñ░ αñ╢αñ┐αñéαñª αñòαÑÇ αñ╢αñ┐αñ╡αñ╕αÑçαñ¿αñ╛ αñòαÑç αñ╕αñéαñ¬αñ░αÑìαñò αñ«αÑçαñé αñëαñªαÑìαñºαñ╡ αñòαÑç αñ¢αñ╣ αñ╕αñ╛αñéαñ╕αñª αñ¬αñ╣αÑüαñéαñÜαÑç αñ╣αÑêαñé αñªαñ┐αñ▓αÑìαñ▓αÑÇαÑñ αñåαñ£ αñ╢αÑìαñ░αÑÇαñòαñ╛αñéαññ αñ╢αñ┐αñéαñª αñòαÑç αñåαñ╡αñ╛αñ╕ αñ¬αñ░ αñòαñ░αÑçαñéαñùαÑç αñ¼αÑêαñáαñòαÑñ\n5:48\n5 minutes, 48 seconds\nαñåαñ£ αñªαñ┐αñ▓αÑìαñ▓αÑÇ αñ«αÑçαñé αñ╕αÑüαñ¼αñ╣ 8:30 αñ¼αñ£αÑç αñ«αÑÇαñƒαñ┐αñéαñù αñòαñ░ αñ░αñ╣αÑç αñ╣αÑïαñéαñùαÑçαÑñ αñëαñªαÑìαñºαñ╡ αñòαÑç αñ¼αñ╛αñùαÑÇ αñ╕αñ╛αñéαñ╕αñªαÑñ αñ▓αÑïαñòαñ╕αñ¡αñ╛ αñ«αÑçαñé αñ╕αÑìαñ¬αÑÇαñòαñ░ αñ╕αÑç αñ«αÑüαñ▓αñ╛αñòαñ╛αññ αñòαñ░ αñàαñ▓αñù αñùαÑüαñƒ αñòαñ╛ αñªαñ╛αñ╡αñ╛\n5:54\n5 minutes, 54 seconds\nαñòαñ░αÑçαñéαñùαÑç αñöαñ░ αñ¼αñ╛αñª αñ«αÑçαñé αñ╢αñ┐αñéαñª αñ╡αñ╛αñ▓αÑç αñùαÑüαñƒ αñ«αÑçαñé αñ╡αñ┐αñ▓αñ» αñòαñ░αÑçαñéαñùαÑçαÑñ\n6:01\n6 minutes, 1 second\nαñƒαÑéαñƒ αñòαÑÇ αñÜαñ░αÑìαñÜαñ╛αñôαñé αñòαÑç αñ¼αÑÇαñÜ αñ╢αñ┐αñ╡αñ╕αÑçαñ¿αñ╛ αñëαñªαÑìαñºαñ╡ αñùαÑüαñƒ αñ¿αÑç αñ▓αÑïαñòαñ╕αñ¡αñ╛ αñàαñºαÑìαñ»αñòαÑìαñ╖ αñòαÑï αñ╕αÑîαñéαñ¬αÑÇ αñÜαñ┐αñƒαÑìαñáαÑÇαÑñ αñòαñ╣αñ╛ αñÅαñòαñ«αñ╛αññαÑìαñ░ αñåαñºαñ┐αñòαñ╛αñ░αñ┐αñò αñªαñ▓ αñòαÑç αñ░αÑéαñ¬ αñ«αÑçαñé αñ╕αñéαñ╕αñª αñ«αÑçαñé αñªαÑÇ αñ£αñ╛αñÅ αñ«αñ╛αñ¿αÑìαñ»αññαñ╛αÑñ\n6:11\n6 minutes, 11 seconds\nαñ╢αñ┐αñ╡αñ╕αÑçαñ¿αñ╛ αñ╢αñ┐αñéαñª αñùαÑüαñƒ αñòαÑç αñ¿αÑçαññαñ╛ αñòαÑâαñ¬αñ╛αñ▓ αññαÑïαñ«αñ╛αñ¿αÑÇ αñòαñ╛ αñªαñ╛αñ╡αñ╛ αñ╣αñ«αñ╛αñ░αÑç αñ╕αñéαñ¬αñ░αÑìαñò αñ«αÑçαñé 16 αñ╡αñ┐αñºαñ╛αñ»αñò αñöαñ░ αñ╕αñ╛αññ αñ╕αñ╛αñéαñ╕αñª αñ╣αÑêαñéαÑñ αñ«αñ╛αñ¿αñ╕αÑéαñ¿ αñ╕αññαÑìαñ░ αñ╕αÑç αñ¬αñ╣αñ▓αÑç αñ╣αñ«αñ╛αñ░αÑÇ αñ¬αñ╛αñ░αÑìαñƒαÑÇ αñ«αÑçαñé αñ╢αñ╛αñ«αñ┐αñ▓ αñ╣αÑïαñéαñùαÑçαÑñ\n6:20\n6 minutes, 20 seconds\nαñ╢αñ┐αñ╡αñ╕αÑçαñ¿αñ╛ αñ»αÑéαñ¼αÑÇαñƒαÑÇ αñ╕αñ╛αñéαñ╕αñª αñ╕αñéαñ£αñ» αñ░αñ╛αñëαññ αñòαñ╛ αñ¼αñíαñ╝αñ╛ αñªαñ╛αñ╡αñ╛αÑñ αñ╕αñ╛αñéαñ╕αñªαÑïαñé αñòαÑï αñªαñ┐αñÅ αñ£αñ╛ αñ░αñ╣αÑç αñ╣αÑêαñé 15-15 αñòαñ░αÑïαñíαñ╝αÑñ αñ»αñ╣ αñ¼αÑçαñ╣αñª αñÜαÑîαñéαñòαñ╛αñ¿αÑç [αñ╕αñéαñùαÑÇαññ] αñ╡αñ╛αñ▓αÑÇ αñÿαÑâαñúαñ┐αññ αñ£αñ╛αñ¿αñòαñ╛αñ░αÑÇαÑñ\n6:29\n6 minutes, 29 seconds\nαñëαñªαÑìαñºαñ╡ αñùαÑüαñƒ αñòαÑç αñòαÑüαñ¢ αñ╕αñ╛αñéαñ╕αñªαÑïαñé αñòαÑç αñ¬αñ╛αñ▓αñ╛ αñ¼αñªαñ▓αñ¿αÑç αñòαÑÇαÑñ αñëαñªαÑìαñºαñ╡ αñáαñ╛αñòαñ░αÑç αñ¼αÑïαñ▓αÑç αñàαñùαñ░ αñ£αñ╛αñ¿αñ╛ αñ╣αÑê αññαÑï αñûαÑüαñ╢αÑÇ-αñûαÑüαñ╢αÑÇ αñ£αñ╛αñÅαÑñ\n6:36\n6 minutes, 36 seconds\nαñ«αñ«αññαñ╛ αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñ¿αÑç αñ¡αñ╡αñ╛αñ¿αÑÇαñ¬αÑüαñ░ αñ╕αÑÇαñƒ αñòαÑç αñ¿αÑÇαññαÑÇαñ£αÑïαñé αñòαÑï αñÜαÑüαñ¿αÑîαññαÑÇ αñªαÑÇ αñ╣αÑêαÑñ αñòαÑïαñ▓αñòαñ╛αññαñ╛ αñ╣αñ╛αñê αñòαÑïαñ░αÑìαñƒ αñ«αÑçαñé αñªαñ╛αñûαñ┐αñ▓ αñòαÑÇ αñ»αñ╛αñÜαñ┐αñòαñ╛ αñ¬αñòαÑìαñ╖αñ¬αñ╛αññ αñòαÑÇ αñåαñ╢αñéαñòαñ╛ αñ£αññαñ╛αñê αñ╣αÑêαÑñ\n6:45\n6 minutes, 45 seconds\nαñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ╕αÑç αñàαñ▓αñù αñ╣αÑüαñÅ αñùαÑüαñƒ αñòαÑï αñ«αñ╛αñ¿αÑìαñ»αññαñ╛ αñªαÑçαñ¿αÑç αñòαñ╛ αñ«αñ╛αñ«αñ▓αñ╛αÑñ αñ╕αÑéαññαÑìαñ░αÑïαñé αñòαÑç αñàαñ¿αÑüαñ╕αñ╛αñ░ αñªαÑïαñ¿αÑïαñé αñùαÑüαñƒαñòαñ╛ αñ¬αñòαÑìαñ╖ αñÜαÑüαñ¿αÑçαñéαñùαÑç αñôαñ« αñ¼αñ┐αñ░αñ▓αñ╛ αñ«αñ«αññαñ╛ αñòαÑç αñùαÑüαñƒ αñòαÑï αñêαñ«αÑçαñ▓ αñ¡αÑçαñ£αñòαñ░ αñ«αñ╛αñéαñùαñ╛ αñ¬αñòαÑìαñ╖\n6:54\n6 minutes, 54 seconds\nαñ¬αÑçαñ¬αñ░ αñ▓αÑÇαñò αñôαñÅαñ╕αñÅαñ« αñ╕αñ┐αñ╕αÑìαñƒαñ« αñ¼αÑçαñ░αÑïαñ£αñùαñ╛αñ░αÑÇ αñòαñ╛ αñ«αÑüαñªαÑìαñªαñ╛ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñòαñ╛ αñªαÑçαñ╢αñ╡αÑìαñ»αñ╛αñ¬αÑÇ αñàαñ¡αñ┐αñ»αñ╛αñ¿ αñåαñ£ αñòαÑïαñƒαñ╛ αñ«αÑçαñé αñ░αñ╛αñ╣αÑüαñ▓ αñ¢αñ╛αññαÑìαñ░ αñ╕αñ«αÑìαñ«αÑçαñ▓αñ¿ [αñ╕αñéαñùαÑÇαññ] αñòαÑï αñòαñ░αÑçαñéαñùαÑç αñ╕αñéαñ¼αÑïαñºαñ┐αññ\n7:02\n7 minutes, 2 seconds\nαñòαÑïαñƒαñ╛ αñ«αÑçαñé αñòαñ╛αñ░αÑìαñ»αñòαÑìαñ░αñ« αñ╕αÑç αñ¬αñ╣αñ▓αÑç αñ╣αñƒαñ╛αñÅ αñùαñÅ αñ░αñ╛αñ╣αÑüαñ▓ αñùαñ╛αñéαñºαÑÇ αñòαÑç [αñ╕αñéαñùαÑÇαññ] αñ¬αÑïαñ╕αÑìαñƒαñ░αÑìαñ╕ αñ¿αñùαñ░ αñ¿αñ┐αñùαñ« αñ¿αÑç αñòαñ╣αñ╛ αñ¼αñ┐αñ¿αñ╛ αñçαñ£αñ╛αñ£αññ αñ▓αñùαñ╛ αñªαñ┐αñÅ αñùαñÅ αñÑαÑç αñ¬αÑïαñ╕αÑìαñƒαñ░αÑìαñ╕\n7:10\n7 minutes, 10 seconds\nαñ░αñ╛αñ╣αÑüαñ▓ αñòαÑç αñ¬αÑïαñ╕αÑìαñƒαñ░ αñ╣αñƒαñ╛αñ¿αÑç αñ¬αñ░ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñ╕αñ░αñòαñ╛αñ░ αñòαÑÇ αñ¿αÑÇαñéαñª αñùαñ╣αñ▓αÑïαññ αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñ¢αñ╛αññαÑìαñ░αÑïαñé αñòαÑç αñòαñ╛αñ░αÑìαñ»αñòαÑìαñ░αñ« αñ«αÑçαñé [αñ╕αñéαñùαÑÇαññ] αñ£αñ╛αñ¿αÑç αñòαÑï αñôαñ« αñ¼αñ┐αñ░αñ▓αñ╛ αñòαÑç αñæαñ½αñ┐αñ╕ αñ╕αÑç αñòαÑïαñÜαñ┐αñéαñù αñ╕αñéαñ╕αÑìαñÑαñ╛αñ¿αÑïαñé αñòαÑï αñªαÑÇ αñ£αñ╛ αñ░αñ╣αÑÇ αñ╣αÑê αñºαñ«αñòαÑÇαÑñ\n7:21\n7 minutes, 21 seconds\nαñ¢αñ╛αññαÑìαñ░αÑïαñé αñòαÑç αñ╕αñéαñ╡αñ╛αñª αñòαñ╛αñ░αÑìαñ»αñòαÑìαñ░αñ« αñòαÑï αñ▓αÑçαñòαñ░ αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñ¿αÑç αñ░αñ╛αñ╣αÑüαñ▓ αñ¬αñ░ αñ¿αñ┐αñ╢αñ╛αñ¿αñ╛ αñ╕αñ╛αñºαñ╛αÑñ αñªαÑîαñ░αÑç αñ╕αÑç αñ¼αññαñ╛αñ»αñ╛ αñ░αñ╛αñ£αñ¿αÑÇαññαñ┐αñò αñòαñ╛αñ░αÑìαñ»αñòαÑìαñ░αñ« αñÿαñ¿αñ╢αÑìαñ»αñ╛αñ« αññαñ┐αñ╡αñ╛αñ░αÑÇ αñ¼αÑïαñ▓αÑç [αñ╕αñéαñùαÑÇαññ] αñ¬αÑçαñ¬αñ░ αñ▓αÑÇαñò αñ¿αñ╣αÑÇαñé αñ╣αÑüαñåαÑñ\n7:31\n7 minutes, 31 seconds\nαñ░αñ╛αñ« αñ«αñéαñªαñ┐αñ░ αñÜαñóαñ╝αñ╛αñ╡αñ╛ αñÜαÑïαñ░αÑÇ αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñÅαñ╕αñåαñêαñƒαÑÇ αñòαÑÇ αñ£αñ╛αñéαñÜ αñ£αñ╛αñ░αÑÇ αñ╣αÑêαÑñ αñ«αñéαñùαñ▓αñ╡αñ╛αñ░ αñòαÑï αñ«αñéαñªαñ┐αñ░ αñ¬αñ░αñ┐αñ╕αñ░ αñ«αÑçαñé 40 αñ╕αÑç αñàαñºαñ┐αñò αñ¼αÑêαñéαñò αñòαñ░αÑìαñ«αñ┐αñ»αÑïαñé αñ╕αÑç αñ¬αÑéαñ¢αññαñ╛αñ¢ αñ╣αÑüαñêαÑñ αñ£αÑüαñƒαñ╛αñê [αñ╕αñéαñùαÑÇαññ] αñ¬αÑêαñ╕αÑç αñòαÑç αñ░αñûαñ░αñûαñ╛αñ╡ αñ£αÑüαñíαñ╝αÑÇ αñ£αñ╛αñ¿αñòαñ╛αñ░αÑÇαÑñ\n7:42\n7 minutes, 42 seconds\nαñÜαñóαñ╝αñ╛αñ╡αñ╛ αñÜαÑïαñ░αÑÇ αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñ╢αñ┐αñòαñ╛αñ»αññ αñªαÑçαñòαñ░ αñÅαñ½αñåαñêαñåαñ░ αñªαñ░αÑìαñ£ αñòαñ░αñ¿αÑç αñòαÑÇ αñ«αñ╛αñéαñùαÑñ αñ╕αñéαññαÑïαñ╖ αñªαÑüαñ¼αÑç αñ¿αñ╛αñ«αñò αñ╡αÑìαñ»αñòαÑìαññαñ┐ αñ¿αÑç αñ╢αñ┐αñòαñ╛αñ»αññ αñòαÑÇαÑñ αñòαñ╣αñ╛ αñ╣αÑê αñÅαñ╕αñåαñêαñƒαÑÇ αñ¬αñ░ αñ¡αñ░αÑïαñ╕αñ╛ αñ¿αñ╣αÑÇαñé αñ╣αÑêαÑñ αñªαñ¼αñ╛αñ╡ [αñ╕αñéαñùαÑÇαññ] αñ«αÑçαñé αñå αñ£αñ╛αñÅαñùαÑÇ αñƒαÑÇαñ«αÑñ\n7:52\n7 minutes, 52 seconds\nαñÜαñóαñ╝αñ╛αñ╡αñ╛ αñÜαÑïαñ░αÑÇ αñòαÑç αñ«αñ╛αñ«αñ▓αÑç αñ¬αñ░ αñàαñûαñ┐αñ▓αÑçαñ╢ αñ»αñ╛αñªαñ╡ αñ¼αÑïαñ▓αÑç αñ¬αÑìαñ░αñ¡αÑü αñ╢αÑìαñ░αÑÇ αñ░αñ╛αñ« αñòαÑç αñ░αñ╛αñ╕αÑìαññαÑç αñ¬αñ░ αñÜαñ▓αñ¿αÑç αñ╡αñ╛αñ▓αÑç αñ¼αñ╣αÑüαññ αñªαÑüαñûαÑÇ αñ╣αÑêαñéαÑñ αñ£αÑï αñ¡αñùαñ╡αñ╛αñ¿ αñòαÑÇ αñÅαñ½αñåαñêαñåαñ░ [αñ╕αñéαñùαÑÇαññ] αñ▓αñ┐αñûαÑÇ αñ£αñ╛αñÅαñùαÑÇ αñëαñ╕αñòαñ╛ αñòαÑìαñ»αñ╛ αñòαñ░αÑçαñéαñùαÑç αñåαñ¬?\n8:02\n8 minutes, 2 seconds\nαñ»αÑéαñ¬αÑÇ αñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñàαñºαÑìαñ»αñòαÑìαñ╖ αñàαñ£αñ» αñ░αñ╛αñ» αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñ¡αñùαñ╡αñ╛αñ¿ αñòαÑç αñ¿αñ╛αñ« αñ¬αñ░ αñÜαÑïαñ░αÑÇ αñòαñ┐αñ»αñ╛ αñÜαñéαñªαñ╛αÑñ αñ╣αñ╛αñê αñòαÑïαñ░αÑìαñƒ αñòαÑç αñ╕αñ┐αñéαñù αñ£αñ£ [αñ╕αñéαñùαÑÇαññ] αñ╕αÑç αñ╣αÑïαñ¿αÑÇ αñÜαñ╛αñ╣αñ┐αñÅ αñ╕αñ«αñ»αñ¼αñªαÑìαñº αñ£αñ╛αñéαñÜαÑñ\n8:11\n8 minutes, 11 seconds\n19 αñ£αÑéαñ¿ αñòαÑï αñ»αÑéαñ¬αÑÇ αñòαÑç αñ«αÑüαñûαÑìαñ»αñ«αñéαññαÑìαñ░αÑÇ αñ»αÑïαñùαÑÇ αñ£αñ╛ αñ╕αñòαññαÑç αñ╣αÑêαñé αñàαñ»αÑïαñºαÑìαñ»αñ╛αÑñ αñ»αÑéαñ¬αÑÇ αñòαÑç αñ«αñéαñªαñ┐αñ░ αñ«αñéαññαÑìαñ░αÑÇ αñôαñ¬αÑÇ αñ░αñ╛αñ£αñ¡αñ░ αñ¼αÑïαñ▓αÑç αñ╡αñ┐αñ¬αñòαÑìαñ╖ αñ╕αñ░αñòαñ╛αñ░ αñ¬αñ░ αñ▓αñùαñ╛ αñ░αñ╣αñ╛ αñ╣αÑê αñåαñ░αÑïαñ¬ αñƒαÑìαñ░αñ╕αÑìαñƒ αñòαÑÇ αñªαÑçαñûαñ░αÑçαñû αñ«αÑçαñé αñ╣αÑïαññαñ╛ αñ╣αÑê\n8:20\n8 minutes, 20 seconds\nαñ«αñéαñªαñ┐αñ░ αñòαñ╛ αñòαñ╛αñ░αÑìαñ» αñ░αñ╛αñ« αñ«αñéαñªαñ┐αñ░ αñòαñ╛ αñÜαñóαñ╝αñ╛αñ╡αñ╛ αñÜαÑïαñ░αÑÇ αñòαÑç αñ«αñ╛αñ«αñ▓αÑç αñ╕αÑç αñ╕αÑüαñ░αÑìαñûαñ┐αñ»αÑïαñé αñ«αÑçαñé αñåαñÅ αñ░αñ«αñ╛αñ╢αñéαñòαñ░ αñ»αñ╛αñªαñ╡ αñöαñ░ αñ¬αñ░ αñƒαñ┐αñ¿αÑé αñ»αñ╛αñªαñ╡ αñòαÑÇ αñ╕αñ½αñ╛αñê αñàαñ¬αñ¿αÑÇ αñòαñ«αñ╛αñê αñ╕αÑç αñûαñ░αÑÇαñªαÑÇ [αñ╕αñéαñùαÑÇαññ]\n8:29\n8 minutes, 29 seconds\nαñ╕αñéαñ¬αññαÑìαññαñ┐ αñ╕αñ╛αñ░αÑç αñåαñ░αÑïαñ¬ αñ¿αñ┐αñ░αñ╛αñºαñ╛αñ░ αñ╣αÑê αñÜαñóαñ╝αñ╛αñ╡αñ╛ αñÜαÑïαñ░αÑÇ αñ¬αñ░ αñ¬αÑéαñ░αÑìαñ╡ αñ╕αñ╛αñéαñ╕αñª αñ╡αñ┐αñ¿αñ» αñòαñƒαñ┐αñ╣αñ╛αñ░ αñòαÑç αññαñ▓αñûαññαÑçαñ╡αñ░ αñòαñ╣αñ╛ αñòαñ┐ αñÅαñ╕αñåαñê αñòαÑÇ αñ£αñ╛αñéαñÜ αñ╕αÑç αñ╕αñ╛αñ½ αñ╣αÑï\n8:36\n8 minutes, 36 seconds\nαñ£αñ╛αñÅαñùαÑÇ αñ¬αÑéαñ░αÑÇ αññαñ╕αÑìαñ╡αÑÇαñ░ αñÜαñóαñ╝αñ╛αñ╡αñ╛ αñÜαÑïαñ░αÑÇ αñòαÑç αñ«αÑüαñªαÑìαñªαÑç αñ¬αñ░ αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñ╕αñ╛αñéαñ╕αñª αñòαñ░αñú αñ¡αÑéαñ╖αñú αñ╕αñ┐αñéαñ╣ αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñ░αñ╛αñ« αñ«αñéαñªαñ┐αñ░ αñ¼αñ¿αñ¿αÑç\n8:45\n8 minutes, 45 seconds\nαñ«αÑçαñé αñ¡αñ▓αÑç αñ╣αÑÇ αñ╕αñ«αñ» αñ▓αñùαñ╛ αñ▓αÑçαñòαñ┐αñ¿ αñçαñ╕ αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñÅαñ½αñåαñêαñåαñ░ αñªαñ░αÑìαñ£ αñ╣αÑïαñ¿αÑç αñ«αÑçαñé αñ¿αñ╣αÑÇαñé αñ╣αÑïαñùαÑÇ αñòαÑïαñê αñªαÑçαñ░αÑÇαÑñ αñ░αñ╛αñ« αñ«αñéαñªαñ┐αñ░ αñòαÑç αñÜαñóαñ╝αñ╛αñ╡αñ╛ αñòαÑÇ αñÜαÑïαñ░αÑÇ αñòαñ╛ αñåαñ░αÑïαñ¬αÑñ\n8:53\n8 minutes, 53 seconds\nαñàαñ»αÑïαñºαÑìαñ»αñ╛ αñ╕αñ«αñ╛αñ£αñ╡αñ╛αñªαÑÇ αñ¬αñ╛αñ░αÑìαñƒαÑÇ αñòαÑç αñ╕αñ╛αñéαñ╕αñª αñàαñ╡αñºαÑçαñ╢ αñ¬αÑìαñ░αñ╕αñ╛αñª αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñ╕αÑüαñ¬αÑìαñ░αÑÇαñ« αñòαÑïαñ░αÑìαñƒ αñòαÑÇ αñ¿αñ┐αñùαñ░αñ╛αñ¿αÑÇ αñ«αÑçαñé αñ╣αÑï αñ£αñ╛αñéαñÜαÑñ\n9:01\n9 minutes, 1 second\nαñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñ¿αÑçαññαñ╛ αñåαñºαñ┐ αñ░αñéαñ£αñ¿ αñÜαÑîαñºαñ░αÑÇ αñ¿αÑç αñòαñ╣αñ╛ αñ«αñéαñªαñ┐αñ░ αñòαÑç αñ¬αÑêαñ╕αÑç αñ«αÑçαñé αñ╣αÑï αñ░αñ╣αÑÇ αñ╣αÑê αñùαñíαñ╝αñ¼αñíαñ╝αÑÇαÑñ αñòαÑìαñ»αñ╛ αñ¼αñÜαÑÇ αñòαñ╛αñ¿αÑéαñ¿ αñ╡αÑìαñ»αñ╡αñ╕αÑìαñÑαñ╛ αñòαÑÇ αñàαñ╣αñ«αñ┐αñ»αññ?\n9:10\n9 minutes, 10 seconds\nαñ¬αñéαñ£αñ╛αñ¼ αñ«αÑçαñé αñºαñ╛αñ░αÑìαñ«αñ┐αñò αñ«αÑüαñªαÑìαñªαÑïαñé αñ¬αñ░ αñùαñ░αÑìαñ«αñ╛αñê αñ░αñ╛αñ£αñ¿αÑÇαññαñ┐αÑñ αñ¡αñùαñ╡αñéαññ αñ«αñ╛αñ¿ αñ¿αÑç αñòαñ╣αñ╛ αñòαñ┐ αñ╕αñ┐αñ»αñ╛αñ╕αÑÇ αñåαñ╕αÑìαñÑαñ╛αñôαñé αñòαÑç αñçαñ╢αñ╛αñ░αÑç αñ¬αñ░ αñ¼αñªαñ¿αñ╛αñ« αñòαñ░αñ¿αÑç αñòαÑÇ αñòαÑïαñ╢αñ┐αñ╢ αñòαÑÇ αñ£αñ╛ αñ░αñ╣αÑÇ αñ╣αÑêαÑñ αñëαñÜαÑìαñÜ αñºαñ╛αñ░αÑìαñ«αñ┐αñò αñ╕αÑìαñÑαñ╛αñ¿αÑïαñé αñ¬αñ░ αñ¼αÑêαñáαÑç αñ▓αÑïαñù αñÉαñ╕αñ╛ αñòαñ░ αñ░αñ╣αÑç αñ╣αÑêαñéαÑñ\n9:22\n9 minutes, 22 seconds\nαñ¥αñ╛αñ░αñûαñéαñí αñ«αÑçαñé αñ░αñ╛αñ£αÑìαñ»αñ╕αñ¡αñ╛ αñòαÑÇ αñªαÑï αñ╕αÑÇαñƒαÑïαñé αñ¬αñ░ 18 αñ£αÑéαñ¿ αñòαÑï αñÜαÑüαñ¿αñ╛αñ╡αÑñ αñÅαñ¿αñíαÑÇαñÅ αñòαÑç αñ╡αñ┐αñªαÑìαñ»αñ╛αñ░αÑìαñÑαñ┐αñ»αÑïαñé αñòαÑï αñ░αñ╛αñéαñÜαÑÇ αñòαÑç αñ╣αÑïαñƒαñ▓ [αñ╕αñéαñùαÑÇαññ] αñ«αÑçαñé αñ╢αñ┐αñ½αÑìαñƒ αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛αÑñ αñ╣αÑçαñ«αñéαññ αñ╕αÑïαñ░αÑçαñ¿ αñòαÑÇ αñàαñºαÑìαñ»αñòαÑìαñ╖αññαñ╛ αñ«αÑçαñé αñçαñéαñíαñ┐αñ»αñ╛ αñ¼αÑìαñ▓αÑëαñò αñòαÑÇ αñ¼αÑêαñáαñò αñ╣αÑüαñêαÑñ\n9:32\n9 minutes, 32 seconds\n18 αñ£αÑéαñ¿ αñòαÑï αñòαñ░αÑìαñ¿αñ╛αñƒαñò αñ╡αñ┐αñºαñ╛αñ¿ αñ¬αñ░αñ┐αñ╖αñª αñòαÑÇ αñÜαÑüαñ¿αñ╛αñ╡ αñ╣αÑïαñùαñ╛αÑñ αñ½αñ┐αñ░ αñ╢αÑüαñ░αÑé αñ╣αÑüαñê αñ░αñ┐αñ╕αÑïαñ░αÑìαñƒ αñ¬αÑëαñ▓αñ┐αñƒαñ┐αñòαÑìαñ╕αÑñ\n9:36\n9 minutes, 36 seconds\nαñòαñ╛αñéαñùαÑìαñ░αÑçαñ╕ αñ¿αÑç αñ╡αñ┐αñºαñ╛αñ»αñòαÑïαñé αñòαÑï αñ░αñ┐αñ╕αÑïαñ░αÑìαñƒ αñ«αÑçαñé αñ░αñûαñ¿αÑç αñòαñ╛ αñ½αÑêαñ╕αñ▓αñ╛ αñòαñ┐αñ»αñ╛αÑñ\n9:40\n9 minutes, 40 seconds\nαñåαñ£ αñ╕αñ«αñ╛αñ£αñ╡αñ╛αñªαÑÇ αñ¬αñ╛αñ░αÑìαñƒαÑÇ αñòαÑç αñæαñ½αñ┐αñ╕ αñ«αÑçαñé αñ¼αÑìαñ░αñ╛αñ╣αÑìαñ«αñú αñ╕αñ«αñ╛αñ£ αñòαÑç αñ¿αÑçαññαñ╛αñôαñé αñòαÑÇ αñ¼αÑêαñáαÑÇ αñ¼αÑêαñáαñò αñ╣αÑïαñùαÑÇαÑñ αñ╕αñ¡αÑÇ αñ╡αñ┐αñºαñ╛αñ»αñò, αñ¬αÑéαñ░αÑìαñ╡ αñ╡αñ┐αñºαñ╛αñ»αñò, αñ╕αñ╛αñéαñ╕αñª αñöαñ░ αñ¬αÑéαñ░αÑìαñ╡ αñ╕αñ╛αñéαñ╕αñª αñ╢αñ╛αñ«αñ┐αñ▓ αñ╣αÑïαñéαñùαÑçαÑñ αñ£αñ¿αÑçαñ╢αÑìαñ╡αñ░ αñ«αñ┐αñ╢αÑìαñ░ αñ£αñ»αñéαññαÑÇ αñòαÑç αñ£αñ░αñ┐αñÅ αñ╕αñéαñªαÑçαñ╢ αñªαÑçαñ¿αÑç αñòαÑÇ αññαÑêαñ»αñ╛αñ░αÑÇ αñ╣αÑêαÑñ\n9:52\n9 minutes, 52 seconds\nαñ«αñ╣αñ┐αñ▓αñ╛αñôαñé αñ¬αñ░ αñàαññαÑìαñ»αñ╛αñÜαñ╛αñ░, αñ¼αÑçαñ░αÑïαñ£αñùαñ╛αñ░αÑÇ αñöαñ░ αñ«αñ╣αñéαñùαñ╛αñê αñòαñ╛ αñ╡αñ┐αñ░αÑïαñºαÑñ αñ¼αñ┐αñ╣αñ╛αñ░ αñ«αÑçαñé αñåαñ£ αñåαñ░αñ£αÑçαñíαÑÇ αñòαñ░αÑçαñùαÑÇ αñ░αñ╛αñ£αÑìαñ»αñ╡αÑìαñ»αñ╛αñ¬αÑÇ αñ¬αÑìαñ░αñªαñ░αÑìαñ╢αñ¿αÑñ\n10:01\n10 minutes, 1 second\nαñ¼αñ┐αñ╣αñ╛αñ░ αñòαÑêαñ¼αñ┐αñ¿αÑçαñƒ αñòαÑÇ αñ¼αÑêαñáαñò αñ╣αÑïαñ¿αÑÇ αñ╣αÑêαÑñ αñåαñ£ αñ¬αñƒαñ¿αñ╛ αñ«αÑçαñé αñ╕αÑÇαñÅαñ« αñ╕αñ«αÑìαñ░αñ╛αñƒ αñÜαÑîαñºαñ░αÑÇ αñòαÑÇ αñàαñºαÑìαñ»αñòαÑìαñ╖αññαñ╛ αñ«αÑçαñé αñ«αÑÇαñƒαñ┐αñéαñù αñ╣αÑïαñùαÑÇαÑñ αñòαñê αñàαñ╣αñ« αñ½αÑêαñ╕αñ▓αÑïαñé αñ¬αñ░ αñ▓αñù αñ╕αñòαññαÑÇ αñ╣αÑê αñ«αÑüαñ░αÑñ\n10:09\n10 minutes, 9 seconds\nαñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ¿αÑçαññαñ╛ αñ£αñ╣αñ╛αñéαñùαÑÇαñ░ αñòαÑÇ αñ░αñ┐αñ╣αñ╛αñê αñòαÑç αñ▓αñ┐αñÅ αñ╕αñ«αñ░αÑìαñÑαñòαÑïαñé αñòαÑç αñ╕αñ╛αñÑ αñÑαñ╛αñ¿αÑç αñ¬αñ╣αÑüαñéαñÜαÑÇ αñ¬αññαÑìαñ¿αÑÇαÑñ\n10:13\n10 minutes, 13 seconds\nαñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñ¼αñ▓αÑïαñé αñ╕αÑç αñ╣αÑüαñê αñ¥αñíαñ╝αñ¬αÑñ αñ¡αñ╛αñùαññαÑç αñ╕αñ«αñ» αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñ¼αñ▓αÑïαñé αñ╕αÑç αñ¼αñÜαñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ αññαñ╛αñ▓αñ╛αñ¼ αñ«αÑçαñé αñ▓αÑïαñù αñòαÑéαñª αñùαñÅαÑñ\n10:19\n10 minutes, 19 seconds\nαñ¿αÑÇαñƒ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛ αñòαÑï αñ▓αÑçαñòαñ░ αñÅαññαñ┐αñ»αñ╛αññαñ¿ αñƒαÑçαñ▓αÑÇαñùαÑìαñ░αñ╛αñ« αñ¬αñ░ αñòαñ╛αñ░αñ╡αñ╛αñêαÑñ αñòαñéαñ¬αñ¿αÑÇ αñòαÑç αñ╕αÑÇαñêαñô αñ¼αÑïαñ▓αÑç αñ½αÑêαñ╕αñ▓αÑç αñ╕αÑç αñ»αÑéαñ£αñ╝αñ░αÑìαñ╕ αñ¬αñ░αÑçαñ╢αñ╛αñ¿ αñ╣αÑï αñ░αñ╣αÑç αñ╣αÑêαñéαÑñ αñ¬αÑçαñ¬αñ░ αñ▓αÑÇαñò αñòαñ░αñ¿αÑç αñ╡αñ╛αñ▓αÑç αñàαñ¼ αñªαÑéαñ╕αñ░αÑç αñÅαñ¬αÑìαñ▓αÑÇαñòαÑçαñ╢αñ¿ αñ╕αÑç αñ▓αÑÇαñò αñòαñ░αÑçαñéαñùαÑçαÑñ\n10:31\n10 minutes, 31 seconds\nαñ«αñªαÑüαñ░αñê αñ«αÑçαñé αñ¿αÑÇαñƒ αñ¬αÑçαñ¬αñ░ αñ▓αÑç αñ£αñ╛ αñ░αñ╣αÑÇ αñùαñ╛αñíαñ╝αÑÇ αñ░αÑüαñòαñ¿αÑç αñ╕αÑç αñ╣αñíαñ╝αñòαñéαñ¬ αñ«αñÜαñ╛αÑñ αññαÑüαñ░αñéαññ αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñ¼αñ▓αÑïαñé αñ¿αÑç αñ╕αñéαñ¡αñ╛αñ▓αñ╛ αñ«αÑïαñ░αÑìαñÜαñ╛αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñòαÑÇ αñùαñ╛αñíαñ╝αÑÇ αñ«αÑçαñé αñûαñ░αñ╛αñ¼αÑÇ αñòαÑç αñ¼αñ╛αñª αñòαñ╛αñ½αñ┐αñ▓αñ╛ αñ░αÑüαñòαñ╛ αñÑαñ╛αÑñ\n10:40\n10 minutes, 40 seconds\nαñ¿αÑÇαñƒ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛ αñªαÑïαñ¼αñ╛αñ░αñ╛ αñòαñ░αñ╛αñ¿αÑç αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñ»αñ╛αñÜαñ┐αñòαñ╛αÑñ αñåαñ£ αñ╕αÑüαñ¬αÑìαñ░αÑÇαñ« αñòαÑïαñ░αÑìαñƒ αñ«αÑçαñé αñ╕αÑüαñ¿αñ╡αñ╛αñê αñ╣αÑïαñùαÑÇαÑñ αñòαñ╣αñ╛ αñòαÑüαñ¢ αñ▓αÑïαñùαÑïαñé αñöαñ░ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛ αñòαÑçαñéαñªαÑìαñ░αÑïαñé αññαñò αñ╕αÑÇαñ«αñ┐αññ [αñ╕αñéαñùαÑÇαññ] αñÑαÑÇ αñùαñíαñ╝αñ¼αñíαñ╝αÑÇαÑñ\n10:50\n10 minutes, 50 seconds\nαñ░αñ╛αñ£αñ╕αÑìαñÑαñ╛αñ¿ αñòαÑç αñ╕αÑÇαñòαñ░ αñ«αÑçαñé αñ¿αÑÇαñƒ αñàαñ¡αÑìαñ»αñ░αÑìαñÑαÑÇ αñ¿αÑç αñåαññαÑìαñ«αñ╣αññαÑìαñ»αñ╛ αñòαñ░ αñ▓αÑÇαÑñ αñ½αÑìαñ▓αÑêαñƒ αñ«αÑçαñé αñ½αñéαñªαÑç αñ╕αÑç αñ▓αñƒαñòαñ╛ αñ«αñ┐αñ▓αñ╛ αñ╢αñ╡αÑñ αñ¬αñ░αñ┐αñ╡αñ╛αñ░ αñòαÑç αñ╕αñ╛αñÑ αñ░αñ╣αñòαñ░ αñòαñ░ αñ░αñ╣αñ╛ αñÑαñ╛ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛ αñòαÑÇ αññαÑêαñ»αñ╛αñ░αÑÇαÑñ\n11:00\n11 minutes\nαñªαÑçαñ╣αñ░αñ╛αñªαÑéαñ¿ αñ«αÑçαñé αñ¿αÑÇαñƒ αñàαñ¡αÑìαñ»αñ░αÑìαñÑαÑÇ αñ¿αÑç αñ▓αñùαñ╛αñê αñ½αñ╛αñéαñ╕αÑÇαÑñ αñ▓αñéαñ¼αÑç αñ╕αñ«αñ» αñ╕αÑç αññαÑêαñ»αñ╛αñ░αÑÇ αñòαñ░ αñ░αñ╣αÑÇ αñÑαÑÇ αñ¢αñ╛αññαÑìαñ░αñ╛αÑñ\n11:03\n11 minutes, 3 seconds\nαñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛ αñ«αÑçαñé αñ╕αñ½αñ▓αññαñ╛ αñ¿αñ╣αÑÇαñé αñ«αñ┐αñ▓αñ¿αÑç αñ╕αÑç αñ¬αñ░αÑçαñ╢αñ╛αñ¿ αñÑαÑÇαÑñ\n11:08\n11 minutes, 8 seconds\nαñëαññαÑìαññαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢ αñ«αÑçαñé αñ¿αÑÇαñƒ αñàαñ¡αÑìαñ»αñ░αÑìαñÑαñ┐αñ»αÑïαñé αñòαÑï αñ¼αñ╕ αñòαñ┐αñ░αñ╛αñÅ αñ«αñ┐αñ▓αÑçαñùαÑÇ 50% αñòαÑÇ αñ¢αÑéαñƒαÑñ αñ╕αÑÇαñÅαñ« αñ»αÑïαñùαÑÇ αñ¿αÑç αñòαñ╣αñ╛ αñ«αÑüαñ╣αñ░αÑìαñ░αñ« αñ«αñ╛αññαñ« αñòαñ╛ αñàαñ╡αñ╕αñ░ [αñ╕αñéαñùαÑÇαññ] αñ╢αñòαÑìαññαñ┐ αñ¬αÑìαñ░αñªαñ░αÑìαñ╢αñ¿ αñòαñ╛ αñ¿αñ╣αÑÇαñéαÑñ\n11:18\n11 minutes, 18 seconds\nαñ¼αñ┐αñ╣αñ╛αñ░ αñ«αÑçαñé αñ«αñºαÑìαñ» αñ¿αñ┐αñ╖αÑçαñº αñ╡αñ┐αñ¡αñ╛αñù αñòαÑÇ αñòαñ╛αñéαñ╕αÑìαñƒαÑçαñ¼αñ▓ αñ¡αñ░αÑìαññαÑÇ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛αÑñ αñÅαñùαÑìαñ£αñ╛αñ« αñòαñ╛ αñåαñ£ αñªαÑéαñ╕αñ░αñ╛ αñªαñ┐αñ¿ αñ╣αÑêαÑñ αñªαÑï αñ¬αñ╛αñ▓αñ┐αñ»αÑïαñé αñ«αÑçαñé αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛ αñ╣αÑïαñùαÑÇαÑñ\n11:26\n11 minutes, 26 seconds\nαñ¼αñ┐αñ╣αñ╛αñ░ αñ«αÑçαñé αñ¢αñ╛αññαÑìαñ░αÑïαñé αñ¿αÑç αñ▓αñùαñ╛αñÅ αñàαñºαÑéαñ░αÑç αñçαñéαññαñ£αñ╛αñ« αñòαÑç αñåαñ░αÑïαñ¬αÑñ αñòαñ╣αñ╛ αñòαñ┐ αñƒαÑìαñ░αÑçαñ¿ αñ«αÑçαñé αñ¿αñ╣αÑÇαñéαÑñ αñàαñºαñ┐αñòαñ╛αñ░αÑÇ αñ¼αÑïαñ▓αÑç αñÜαñ▓αñ╛αñê αñ£αñ╛ αñ░αñ╣αÑÇ αñ╣αÑê αñàαññαñ┐αñ░αñ┐αñòαÑìαññ αñƒαÑìαñ░αÑçαñ¿αÑñ\n11:34\n11 minutes, 34 seconds\nαñ£αÑêαñ╕αñ▓αñ«αÑçαñ░ αñ«αÑçαñé αñåαñêαñÅαñ╕αñåαñê αñÅαñ£αÑçαñéαñƒ αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░αÑñ\n11:36\n11 minutes, 36 seconds\nαñ¼αÑÇαñÅαñ╕αñÅαñ½ αñöαñ░ αñ╕αÑçαñ¿αñ╛ αñòαÑç αñ«αÑéαñ╡αñ«αÑçαñéαñƒαÑìαñ╕ αñòαÑÇ αñ¡αÑçαñ╖ αñ£αñ╛αñ¿αñòαñ╛αñ░αÑÇαÑñ αñªαÑüαñòαñ╛αñ¿ αñòαÑÇ αñåαñíαñ╝ αñ«αÑçαñé αñòαñ░αññαñ╛ αñÑαñ╛ αñ¬αñ╛αñòαñ┐αñ╕αÑìαññαñ╛αñ¿ αñòαÑç αñ▓αñ┐αñÅ αñ£αñ╛αñ╕αÑéαñ╕αÑÇαÑñ\n11:43\n11 minutes, 43 seconds\nαñ¢αññαÑìαññαÑÇαñ╕αñùαñóαñ╝ αñòαÑç αñòαñê αñ£αñ┐αñ▓αÑïαñé αñ«αÑçαñé αñêαñíαÑÇ αñòαÑÇ αñ░αÑçαñí, αñ░αñ╛αñ»αñ¬αÑüαñ░, αñªαÑüαñ░αÑìαñù, αñºαñ«αñòαñ░αÑÇ αñöαñ░ αñòαÑïαñ░αñ╡αñ╛ αñ╕αñ«αÑçαññ αñ¿αÑî αñ£αñùαñ╣αÑïαñé αñ¬αñ░ αñ¢αñ╛αñ¬αñ╛αñ«αñ╛αñ░ αñòαñ╛αñ░αñ╡αñ╛αñê αñ╣αÑüαñêαÑñ αñíαÑÇαñÅαñ«αñÅαñ½ αñöαñ░\n11:50\n11 minutes, 50 seconds\nαñ¡αñ╛αñ░αññαñ«αñ╛αñ▓αñ╛ αñÿαÑïαñƒαñ╛αñ▓αÑç αñòαÑï αñ▓αÑçαñòαñ░ αñ£αñ╛αñéαñÜαÑñ αñ░αñ╛αñ¿αÑé αñ╕αñ╛αñ╣αÑé αñòαÑç αñòαñ░αÑÇαñ¼αñ┐αñ»αÑïαñé αñòαÑç αñÿαñ░ αñ¡αÑÇ αñ¬αñ╣αÑüαñéαñÜαÑÇ αñêαñíαÑÇ αñòαÑÇ αñƒαÑÇαñ«αÑñ\n11:55\n11 minutes, 55 seconds\nαñ¼αñíαñ╝αÑîαñª αñ«αÑçαñé αñƒαÑçαñéαñƒ αñòαñ╛αñ░αÑïαñ¼αñ╛αñ░αÑÇ αñöαñ░ αñëαñ¿αñòαÑç αñ¼αÑçαñƒαÑç αñòαÑÇ αñ╣αññαÑìαñ»αñ╛ αñòαñ╛ αñ«αñ╛αñ«αñ▓αñ╛αÑñ αñ╣αññαÑìαñ»αñ╛αñòαñ╛αñéαñí αñ«αÑçαñé αñ╢αñ╛αñ«αñ┐αñ▓αÑñ\n11:59\n11 minutes, 59 seconds\nαñåαñ░αÑïαñ¬αÑÇ αñòαÑç αñ╕αñ╛αñÑ αñ¬αÑüαñ▓αñ┐αñ╕ αñòαÑÇ αñ«αÑüαñáαñ¡αÑçαñíαñ╝αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñòαÑÇ αñùαÑïαñ▓αÑÇ αñ╕αÑç αñÿαñ╛αñ»αñ▓ [αñ╕αñéαñùαÑÇαññ] αñ╣αÑüαñå αñ¼αñªαñ«αñ╛αñ╢αÑñ\n12:04\n12 minutes, 4 seconds\nαñ¼αñ╣αñ░αñ╛αñçαñÜ αñ«αÑçαñé αñ¬αÑçαñƒαÑìαñ░αÑïαñ▓ αñ¬αñéαñ¬ αñ¬αñ░ Γé╣5,000 αñòαÑÇ αñ▓αÑéαñƒ αñ╕αñ╛αñ«αñ╛αñ¿ αñ▓αÑçαñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ αñ▓αÑüαñƒαÑçαñ░αÑç αñ¬αñ╣αÑüαñéαñÜαÑç αñÑαÑçαÑñ\n12:10\n12 minutes, 10 seconds\nαñ¬αÑçαñƒαÑìαñ░αÑïαñ▓ αñ¬αñéαñ¬ αñ¬αñ░ αñ▓αñùαÑç αñ╕αÑÇαñ╕αÑÇαñƒαÑÇαñ╡αÑÇ αñòαÑêαñ«αñ░αÑç αñ«αÑçαñé αñëαñ¿αñòαÑÇ αñ»αñ╣ αñ╡αñ╛αñ░αñªαñ╛αññ [αñ╕αñéαñùαÑÇαññ] αñòαÑêαñª αñ╣αÑüαñêαÑñ\n12:15\n12 minutes, 15 seconds\nαñ«αÑçαñ░αñá αñ«αÑçαñé αñ╕αñ░αñòαñ╛αñ░ αñòαÑï αñòαñ░αÑïαñíαñ╝αÑïαñé αñòαñ╛ αñÜαÑéαñ¿αñ╛ αñ▓αñùαñ╛αñ¿αÑç αñ╡αñ╛αñ▓αÑç αñ½αñ░αÑìαñ£αÑÇαÑñ αñ░αÑëαñ»αñ▓αÑìαñƒαÑÇ αñùαñ┐αñ░αÑïαñ╣ αñòαñ╛ αñ¬αñ░αÑìαñªαñ╛αñ½αñ╛αñ╢ αñ╣αÑüαñå αñ╣αÑêαÑñ αñÅαñ╕αñƒαÑÇαñÅαñ½ αñ¿αÑç αñÜαñ╛αñ░ αñåαñ░αÑïαñ¬αñ┐αñ»αÑïαñé αñòαÑï αñàαñ░αÑçαñ╕αÑìαñƒ αñòαñ┐αñ»αñ╛ αñ╣αÑêαÑñ αñûαñ¿αñ¿ αñªαñ╕αÑìαññαñ╛αñ╡αÑçαñ£αÑïαñé αñ«αÑçαñé αñ╣αÑçαñ░αñ╛αñ½αÑçαñ░αÑÇ αñòαñ╛ αñåαñ░αÑïαñ¬ αñ╣αÑêαÑñ\n12:25\n12 minutes, 25 seconds\nαñ£αÑïαñºαñ¬αÑüαñ░ αñ«αÑçαñé αñ¬αÑüαñ▓αñ┐αñ╕ αñÑαñ╛αñ¿αÑç αñ«αÑçαñé αñ¬αÑéαñ¢αññαñ╛αñ¢ αñòαÑç αñ▓αñ┐αñÅ αñ¼αÑüαñ▓αñ╛αñÅ αñùαñÅ αñ»αÑüαñ╡αñò αñòαÑÇ αñ«αÑîαññ αñ╣αÑï αñùαñêαÑñ αñ▓αñ╛αñ¬αññαñ╛αÑñ αñ«αñéαñíαñ╛ αñòαÑç αñ╕αñ┐αñ▓αñ╕αñ┐αñ▓αÑç αñ«αÑçαñé αñ¬αÑéαñ¢αññαñ╛αñ¢ αñòαÑç αñ▓αñ┐αñÅ αñÑαñ╛αñ¿αÑç αñ¼αÑüαñ▓αñ╛αñ»αñ╛ αñùαñ»αñ╛ αñÑαñ╛ αñ»αÑüαñ╡αñò αñòαÑïαÑñ αñ¬αñ░αñ┐αñ£αñ¿αÑïαñé [αñ╕αñéαñùαÑÇαññ] αñ¿αÑç αñ«αñ╛αñ«αñ▓αÑç\n12:33\n12 minutes, 33 seconds\nαñòαÑÇ αñ£αñ╛αñéαñÜ αñòαÑÇ αñ«αñ╛αñéαñù αñòαÑÇαÑñ αñùαÑïαñéαñíαñ╛ αñ«αÑçαñé αñ¬αÑüαñ▓αñ┐αñ╕ αñÜαÑîαñòαÑÇ αñ«αÑçαñé αñªαÑï αñ»αÑüαñ╡αñòαÑïαñé αñòαÑÇ αñ¬αñ┐αñƒαñ╛αñê αñòαñ╛ αñ«αñ╛αñ«αñ▓αñ╛αÑñ αñ╡αÑÇαñíαñ┐αñ»αÑï αñ╡αñ╛αñ»αñ░αñ▓ αñ╣αÑïαñ¿αÑç αñ¬αñ░ αñÅαñ╕αñ¬αÑÇ αñ¿αÑç αñòαñ╛αñ░αñ╡αñ╛αñê αñòαÑÇαÑñ αñªαÑï αñòαñ╛αñéαñ╕αÑìαñƒαÑçαñ¼αñ▓ αñ╕αñ«αÑçαññ\n12:41\n12 minutes, 41 seconds\n[αñ╕αñéαñùαÑÇαññ]\n12:41\n12 minutes, 41 seconds\nαññαÑÇαñ¿ αñ¬αÑüαñ▓αñ┐αñ╕αñòαñ░αÑìαñ«αÑÇ αñ▓αñ╛αñçαñ¿ αñ╣αñ╛αñ£αñ┐αñ░ αñòαñ┐αñÅ αñùαñÅαÑñ\n12:45\n12 minutes, 45 seconds\nαñ▓αÑüαñºαñ┐αñ»αñ╛αñ¿αñ╛ αñ«αÑçαñé αñªαñ¼αñéαñùαÑïαñé αñ¿αÑç αñ¼αÑïαñ▓αñ╛ αñÅαñò αñÿαñ░ αñ¬αñ░ αñ╣αñ«αñ▓αñ╛αÑñ αñÿαñ░ αñ¬αñ░ αñ¼αñ░αñ╕αñ╛αñÅ αñùαñê αñêαñéαñƒ αñ¬αññαÑìαñÑαñ░αÑñ αñ¼αñ╛αñ╣αñ░ αñûαñíαñ╝αÑç αñ╡αñ╛αñ╣αñ¿αÑïαñé αñ«αÑçαñé αñ¡αÑÇ αññαÑïαñíαñ╝αñ½αÑïαñíαñ╝ αñòαÑÇ αñùαñêαÑñ αñªαÑïαñ¿αÑïαñé αñ¬αñòαÑìαñ╖αÑïαñé αñòαÑç αñ¼αÑÇαñÜ αñÜαñ▓αÑÇ αñå αñ░αñ╣αÑÇ αñ¬αÑüαñ░αñ╛αñ¿αÑÇ αñ░αñéαñ£αñ┐αñ╢αÑñ\n12:55\n12 minutes, 55 seconds\nαñ▓αÑüαñºαñ┐αñ»αñ╛αñ¿αñ╛ αñ«αÑçαñé αñ╣αÑïαñƒαñ▓ αñ«αñ╛αñ▓αñ┐αñò αñ¬αñ░ αñòαÑéαñ░αñ┐αñ»αñ░ αñòαñéαñ¬αñ¿αÑÇ αñòαÑÇ αñ«αñ╣αñ┐αñ▓αñ╛ αñòαñ░αÑìαñ«αÑÇ αñòαÑÇ αñ¬αñ┐αñƒαñ╛αñê αñòαñ╛ αñåαñ░αÑïαñ¬ αñ╣αÑêαÑñ αñ¬αñ╛αñ░αÑìαñ╕αñ▓ αñªαÑçαñ¿αÑç αñòαÑç [αñ╕αñéαñùαÑÇαññ] αñ▓αñ┐αñÅ αñùαñê αñÑαÑÇ αñ«αñ╣αñ┐αñ▓αñ╛αÑñ\n13:02\n13 minutes, 2 seconds\nαñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ«αñ╛αñ«αñ▓αñ╛ αñªαñ░αÑìαñ£ αñòαñ░ αñ£αñ╛αñéαñÜ αñ╢αÑüαñ░αÑé αñòαÑÇαÑñ\n13:06\n13 minutes, 6 seconds\nαñùαñ╛αñ£αñ┐αñ»αñ╛αñ¼αñ╛αñª αñòαÑç αñûαÑïαñíαñ╝αñ╛ αñ«αÑçαñé αñªαÑï αñ╕αñùαÑÇ αñ¼αñ╣αñ¿αÑïαñé αñòαÑï αñùαÑïαñ▓αÑÇ αñ«αñ╛αñ░αñ¿αÑç αñòαñ╛ αñ«αñ╛αñ«αñ▓αñ╛αÑñ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ£αÑëαñ¿αÑÇ αñ¿αñ╛αñ« αñòαÑç αñåαñ░αÑïαñ¬αÑÇ αñòαÑï αñùαñ┐αñ░αñ½αÑìαññαñ╛αñ░ αñòαñ┐αñ»αñ╛αÑñ αñ╢αñ╛αñªαÑÇ αñòαñ╛ αñ░αñ┐αñ╢αÑìαññαñ╛ αñƒαÑéαñƒαñ¿αÑç αñòαÑÇ αñ╡αñ£αñ╣ αñ╕αÑç αñ¿αñ╛αñ░αñ╛αñ£ αñÑαñ╛ αñ»αÑüαñ╡αñòαÑñ\n13:15\n13 minutes, 15 seconds\nαñ«αñ╕αÑéαñ░αÑÇ αñòαÑç αñºαñ¿αÑîαñ▓αñƒαÑÇ αñ«αÑçαñé αñ╣αÑïαñ« αñ╕αÑìαñƒαÑç αñ«αÑçαñé αñ«αñ┐αñ▓αñ╛ αñ«αñ╣αñ┐αñ▓αñ╛ αñòαñ╛ αñ╢αñ╡αÑñ αñ╕αÑëαñ½αÑìαñƒαñ╡αÑçαñ»αñ░ αñçαñéαñ£αÑÇαñ¿αñ┐αñ»αñ░ αñòαÑÇ αñºαñ╛αñ░αñ╛ αñ╕αÑç αñ«αÑîαññ αñ╣αÑï αñùαñêαÑñ αñ¬αñ░αñ┐αñ£αñ¿αÑïαñé αñ¿αÑç αñòαÑÇ αñ¿αñ┐αñ╖αÑìαñ¬αñòαÑìαñ╖ αñ£αñ╛αñéαñÜ αñòαÑÇ αñ«αñ╛αñéαñùαÑñ αñ«αñ╛αñ«αñ▓αÑç αñòαÑÇ αñ£αñ╛αñéαñÜ αñòαñ░ αñ░αñ╣αÑÇ αñ╣αÑê αñ¬αÑüαñ▓αñ┐αñ╕αÑñ\n13:24\n13 minutes, 24 seconds\nαñàαñ▓αÑìαñ«αÑïαñíαñ╝αñ╛ αñ«αÑçαñé αñûαñ╛αñê αñ«αÑçαñé αñùαñ┐αñ░αÑÇ αñ¼αÑüαñ▓αÑçαñ░αÑï αñùαñ╛αñíαñ╝αÑÇαÑñ\n13:26\n13 minutes, 26 seconds\nαñ╣αñ╛αñªαñ╕αÑç αñ«αÑçαñé αñÜαñ╛αñ░ αñ¼αñÜαÑìαñÜαÑïαñé αñ╕αñ«αÑçαññ 11 αñ▓αÑïαñù αñÿαñ╛αñ»αñ▓ αñ╣αÑï αñùαñÅαÑñ αññαÑÇαñ¿ αñÿαñ╛αñ»αñ▓αÑïαñé αñòαÑï αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛ αñ╣αñ╛αñ»αñ░ αñ╕αÑçαñéαñƒαñ░ αñ░αÑçαñ½αñ░αÑñ αñ£αñ╛αñùαÑçαñ╢αÑìαñ╡αñ░ αñ«αñéαñªαñ┐αñ░ αñªαñ░αÑìαñ╢αñ¿ αñòαÑç αñ▓αñ┐αñÅ αñ£αñ╛ αñ░αñ╣αÑç αñÑαÑç αñòαñ╛αñ░ [αñ╕αñéαñùαÑÇαññ] αñ╕αñ╡αñ╛αñ░αÑñ\n13:34\n13 minutes, 34 seconds\nαñ¿αÑêαñ¿αÑÇαññαñ╛αñ▓ αñ«αÑçαñé αñòαñ╛αñ▓αñ╛ αñóαñéαñùαÑÇ αñ░αÑïαñí αñ¬αñ░ αñ╣αñ╛αñªαñ╕αñ╛ αñàαñ¿αñ┐αñ»αñéαññαÑìαñ░αñ┐αññ αñ╣αÑïαñòαñ░ αñ╕αñ░αñ┐αñ»αñ╛αññαñ╛αñ▓ αñ¥αÑÇαñ▓ αñ«αÑçαñé αñùαñ┐αñ░αÑÇ αñòαñ╛αñ░αÑñ αñòαñ╛αñ░ αñ╕αñ╡αñ╛αñ░ αñ╕αñ¡αÑÇ αñÜαñ╛αñ░ [αñ╕αñéαñùαÑÇαññ] αñ▓αÑïαñù αñ╕αÑüαñ░αñòαÑìαñ╖αñ┐αññ αñ╣αÑêαñéαÑñ\n13:43\n13 minutes, 43 seconds\nαñùαÑïαñ░αñûαñ¬αÑüαñ░ αñ«αÑçαñé αñ░αñ╛ αñ¿αñªαÑÇ αñ«αÑçαñé αñ¿αñ╣αñ╛αñ¿αÑç αñùαñÅ αñªαÑï αñ¼αñÜαÑìαñÜαÑç αñíαÑéαñ¼αÑçαÑñ αñ¬αñ╛αñ¿αÑÇ αñ«αÑçαñé αñíαÑéαñ¼αñ¿αÑç αñ╕αÑç αñÅαñò αñ¼αñÜαÑìαñÜαÑç αñòαÑÇ αñ«αÑîαññ αñ╣αÑï αñùαñêαÑñ αñ¼αñÜαÑìαñÜαÑÇ αñòαÑÇ αññαñ▓αñ╛αñ╢ αñòαÑç αñ▓αñ┐αñÅ αñ╕αñ░αÑìαñÜ αñæαñ¬αñ░αÑçαñ╢αñ¿ αñ£αñ╛αñ░αÑÇαÑñ αñÿαñƒαñ¿αñ╛ [αñ╕αñéαñùαÑÇαññ] αñòαÑç αñ¼αñ╛αñª αñ¬αñ░αñ┐αñ£αñ¿αÑïαñé αñ«αÑçαñé αñòαÑïαñ╣αñ«αñ░αñ╛αñ«αÑñ\n13:53\n13 minutes, 53 seconds\nαñ£αñ╛αñ▓αñéαñºαñ░ αñ«αÑçαñé αñíαÑìαñ░αñù αññαñ╕αÑìαñòαñ░αÑÇ αñ╕αÑç αñ£αÑüαñíαñ╝αÑç αñ╡αÑÇαñ░αñªαñ╛ αñóαñ╛αñ¼αñ╛ αñ¬αñ░ αñÜαñ▓αñ╛ αñ¼αÑüαñ▓αñíαÑïαñ£αñ░αÑñ αñ¿αñùαñ░ αñ¿αñ┐αñùαñ« αñöαñ░ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ╣αññαñ╛αñ»αñ╛ αñàαññαñ┐αñòαÑìαñ░αñ«αñúαÑñ αñ¬αÑìαñ░αÑëαñ¬αñ░αÑìαñƒαÑÇ αñ¬αñ░ αñ«αñ╛αñ▓αñ┐αñòαñ╛αñ¿αñ╛ αñ╣αñò αñòαÑï αñ▓αÑçαñòαñ░ αñ╕αñ╛αñ«αñ¿αÑç αñåαñ»αñ╛ αñÑαñ╛ αñ╡αñ┐αñ╡αñ╛αñªαÑñ\n14:03\n14 minutes, 3 seconds\nαñ«αÑüαñ░αñ╛αñªαñ╛αñ¼αñ╛αñª αñòαÑç αñ¡αñùαññαñ¬αÑüαñ░ αñòαÑìαñ╖αÑçαññαÑìαñ░ αñ«αÑçαñé αñàαñ╡αÑêαñº αñ«αñ╕αÑìαñ£αñ┐αñª αñ¬αñ░ αñ¼αÑüαñ▓αñíαÑïαñ£αñ░ αñÜαñ▓αñ╛ αñ¼αÑüαñ▓αñíαÑïαñ£αñ░ αñ«αÑçαñé αñùαñ┐αñ░αñ╛αñê αñùαñê αñ«αñ╕αÑìαñ£αñ┐αñªαÑñ 300 αñ╡αñ░αÑìαñù αñ«αÑÇαñƒαñ░ αñ╕αñ░αñòαñ╛αñ░αÑÇ αñ£αñ«αÑÇαñ¿ αñ¬αñ░ αñ»αñ╣ αñ«αñ╕αÑìαñ£αñ┐αñª αñ¼αñ¿αÑÇ αñ╣αÑüαñê αñÑαÑÇαÑñ\n14:12\n14 minutes, 12 seconds\nαñ▓αñûαñ¿αñè αñ«αÑçαñé αñûαñ¿αñ¿ αñ«αñ╛αñ½αñ┐αñ»αñ╛ αñòαÑç αñ¼αÑÇαñÜ αñ½αñ╛αñ»αñ░αñ┐αñéαñù αñ╣αÑï αñùαñêαÑñ αñ¬αÑüαñ░αñ╛αñ¿αÑÇ αñ░αñéαñ£αñ┐αñ╢ αñòαÑï αñ▓αÑçαñòαñ░ αñ½αñ╛αñ»αñ░αñ┐αñéαñùαÑñ αñ╕αÑüαñ╢αñ╛αñéαññ αñ¬αÑïαñ▓ αñ╕αñ┐αñƒαÑÇ αñÑαñ╛αñ¿αñ╛ αñòαÑìαñ╖αÑçαññαÑìαñ░ αñòαÑç αñ╕αÑçαñ╡αñê αñÜαÑîαñòαÑÇ αñòαñ╛ αñ«αñ╛αñ«αñ▓αñ╛αÑñ αñ¢αñ╛αñ¿αñ¼αÑÇαñ¿ αñ«αÑçαñé αñ£αÑüαñƒαÑÇ αñ¬αÑüαñ▓αñ┐αñ╕αÑñ\n14:22\n14 minutes, 22 seconds\nαñ¢αññαÑìαññαÑÇαñ╕αñùαñóαñ╝ αñòαÑç αñ╕αÑéαñ░αñ£αñ¬αÑüαñ░ αñ«αÑçαñé αñùαñ░αÑìαñ¡αñ╡αññαÑÇ αñ«αñ╣αñ┐αñ▓αñ╛ αñòαÑÇ αñ«αÑîαññ αñ¬αñ░ αñ╣αñéαñùαñ╛αñ«αñ╛αÑñ αñ¬αñ░αñ┐αñ£αñ¿ αñàαñ╕αÑìαñ¬αññαñ╛αñ▓ αñòαÑç αñíαÑëαñòαÑìαñƒαñ░αÑìαñ╕ αñòαÑï αñ▓αñùαñ╛ αñ▓αñ╛αñ¬αñ░αñ╡αñ╛αñ╣αÑÇ αñòαñ╛ αñåαñ░αÑïαÑñ αñ╕αÑìαñ╡αñ╛αñ╕αÑìαñÑαÑìαñ» αñ╡αñ┐αñ¡αñ╛αñù αñ¿αÑç αñùαñáαñ┐αññ αñòαÑÇ αñ£αñ╛αñéαñÜ αñòαÑÇαÑñ\n14:31\n14 minutes, 31 seconds\nαñ¼αñ┐αñ╣αñ╛αñ░ αñ«αÑçαñé αñ¬αÑüαñ▓αñ┐αñ╕ αñ¡αñ░αÑìαññαÑÇ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛αñôαñé αñòαÑï αñ▓αÑçαñòαñ░ αñ░αÑçαñ▓αñ╡αÑç αñ╕αÑìαñƒαÑçαñ╢αñ¿ αñ¬αÑìαñ░αñ¡αñ╛αñ░αÑÇ αñ¡αÑÇ αñ¬αÑìαñ▓αÑçαñƒαñ½αñ╛αñ░αÑìαñ« αñ¬αñ░ αñ¿αñ╣αÑÇαñé αñ¼αñÜαÑÇ αñ¬αñ╛αñéαñ╡ αñ░αñûαñ¿αÑç αññαñò αñòαÑÇ αñ£αñùαñ╣αÑñ\n14:36\n14 minutes, 36 seconds\nαñàαñ¡αÑìαñ»αñ░αÑìαñÑαñ┐αñ»αÑïαñé αñ¿αÑç αñƒαÑìαñ░αÑçαñ¿αÑïαñé αñòαÑÇ αñòαñ«αÑÇ αñöαñ░ αñàαñ╡αÑìαñ»αñ╡αñ╕αÑìαñÑαñ╛αñôαñé αñòαÑÇ αñ╢αñ┐αñòαñ╛αñ»αññ αñòαÑÇαÑñ\n14:41\n14 minutes, 41 seconds\nαñ╕αñéαñ¡αñ▓ αñ«αÑçαñé αñ«αÑüαñ╣αñ░αÑìαñ░αñ« αñòαÑï αñ▓αÑçαñòαñ░ αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñ╡αÑìαñ»αñ╡αñ╕αÑìαñÑαñ╛ αñòαñíαñ╝αÑÇ αñ╣αÑï αñùαñê αñ╣αÑêαÑñ αñíαÑÇαñÅαñ« αñöαñ░ αñÅαñ╕αñ¬αÑÇ αñòαÑÇ αñàαñùαÑüαñ╡αñ╛αñê αñ«αÑçαñé αñ¿αñ┐αñòαñ▓αñ╛ αñ½αÑìαñ▓αÑêαñù αñ«αñ╛αñ░αÑìαñÜαÑñ αñ▓αÑïαñùαÑïαñé αñòαÑç αñ╢αñ╛αñéαññαñ┐ αñòαÑç αñ╕αñ╛αñÑ αñ«αÑüαñ╣αñ░αÑìαñ░αñ« αñ«αñ¿αñ╛αñ¿αÑç αñòαÑÇ αñàαñ¬αÑÇαñ▓αÑñ\n14:50\n14 minutes, 50 seconds\nαñ«αñúαñ┐αñ¬αÑüαñ░ αñòαÑÇ αñ░αñ╛αñ£αñºαñ╛αñ¿αÑÇ αñ»αñ«αñ¬αñ╛αñ▓ αñ«αÑçαñé αñ½αñ┐αñ░ αñ╕αÑç αññαñ¿αñ╛αñ╡ αñ¬αÑìαñ░αñªαñ░αÑìαñ╢αñ¿αñòαñ╛αñ░αñ┐αñ»αÑïαñé αñ¿αÑç αñ¬αÑìαñ░αñ«αÑüαñû αñ╕αÑìαñ╡αñ╛αñ╕αÑìαñÑαÑìαñ» αñ╕αñéαñ╕αÑìαñÑαñ╛ αñåαñ░αñåαñêαñÅαñ«αñÅαñ╕ αñòαÑï αñÿαÑçαñ░αñ╛αÑñ αñàαñ╕αÑìαñ¬αññαñ╛αñ▓ αñ«αÑçαñé αññαÑÇαñ¿\n14:57\n14 minutes, 57 seconds\nαñòαÑüαñòαÑÇ αñ»αÑüαñ╡αñòαÑïαñé αñòαÑï αñ¡αñ░αÑìαññαÑÇ αñòαñ░αñ¿αÑç αñòαñ╛ αñ╡αñ┐αñ░αÑïαñº αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛αÑñ αñ╣αñéαñùαñ╛αñ«αñ╛ αñ¼αñóαñ╝αñ¿αÑç αñ¬αñ░ αñªαÑéαñ╕αñ░αÑç αñàαñ╕αÑìαñ¬αññαñ╛αñ▓ αñ«αÑçαñé αñ╢αñ┐αñ½αÑìαñƒ αñòαñ┐αñÅ αñùαñÅ αñ»αÑüαñ╡αñòαÑñ\n15:03\n15 minutes, 3 seconds\nαñ«αñºαÑìαñ» αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñùαÑüαñ¿αñ╛ αñåαñºαÑüαñ¿αñ┐αñò αñòαÑìαñ╖αÑçαññαÑìαñ░ αñ«αÑçαñé αñ¬αñ╛αñçαñ¬ αñ½αÑêαñòαÑìαñƒαÑìαñ░αÑÇ αñ«αÑçαñé αñ▓αñùαÑÇ αñ¡αÑÇαñ╖αñú αñåαñùαÑñ 50 αñ▓αñ╛αñû αñ╕αÑç αñ£αÑìαñ»αñ╛αñªαñ╛ αñòαñ╛ αñ╕αñ╛αñ«αñ╛αñ¿ αñ£αñ▓αñòαñ░ αñ╣αÑüαñå αñ░αñ╛αñûαÑñ αñ╢αÑëαñ░αÑìαñƒ [αñ╕αñéαñùαÑÇαññ] αñ╕αñ░αÑìαñòαñ┐αñƒ αñòαÑç αñòαñ╛αñ░αñú αñåαñù αñ▓αñùαñ¿αÑç αñòαÑÇ αñåαñ╢αñéαñòαñ╛αÑñ\n15:15\n15 minutes, 15 seconds\nαñ╣αÑêαñªαñ░αñ╛αñ¼αñ╛αñª αñ«αÑçαñé αñêαñ╡αÑÇ αñ╡αÑçαñ»αñ░ αñ╣αñ╛αñëαñ╕ αñ«αÑçαñé αñ▓αñùαÑÇ αñ¡αÑÇαñ╖αñú αñåαñùαÑñ αñåαñù αñ¿αÑç αñòαÑüαñ¢ αñ╣αÑÇ αñªαÑçαñ░ αñ«αÑçαñé αñ¬αÑéαñ░αÑç αñ¬αñ░αñ┐αñ╕αñ░ αñòαÑï αñàαñ¬αñ¿αÑÇ αñÜαñ¬αÑçαñƒ αñ«αÑçαñé αñ▓αñ┐αñ»αñ╛αÑñ αñ½αñ╛αñ»αñ░ αñ¼αÑìαñ░αñ┐αñùαÑçαñí αñ¿αÑç αñåαñù αñ¬αñ░ αñòαñ╛αñ¼αÑé αñ¬αñ╛αñ»αñ╛αÑñ αñ▓αñ╛αñûαÑïαñé αñòαñ╛ αñ¿αÑüαñòαñ╕αñ╛αñ¿αÑñ\n15:24\n15 minutes, 24 seconds\nαñ«αÑïαñªαÑÇαñ¬αÑüαñ░αñ« αñ«αÑçαñé αñÜαñ▓αññαÑÇ αñòαñ╛αñ░ αñ«αÑçαñé αñåαñù αñ▓αñù αñùαñêαÑñ αñòαñ╛αñ░ αñ╕αñ╡αñ╛αñ░ αñ▓αÑïαñùαÑïαñé αñ¿αÑç αñ╕αñ«αñ» αñ░αñ╣αññαÑç αñòαñ╛αñ░ αñ╕αÑç αñ¼αñ╛αñ╣αñ░ αñ¿αñ┐αñòαñ▓ αñòαñ░ αñ£αñ╛αñ¿ αñ¼αñÜαñ╛αñêαÑñ αñ¬αñ▓αÑìαñ▓αñ╡αñ¬αÑüαñ░αñ« αñÑαñ╛αñ¿αñ╛ αñòαÑìαñ╖αÑçαññαÑìαñ░ αñòαÑÇ αñÿαñƒαñ¿αñ╛ αñ╣αÑêαÑñ\n15:32\n15 minutes, 32 seconds\nαñàαñéαñ¼αñ╛αñ▓αñ╛ αñòαÑÇ αñ¬αÑüαñ░αñ╛αñ¿αÑÇ αñ╕αñ¼αÑìαñ£αÑÇ αñ«αñéαñíαÑÇ αñ«αÑçαñé αñ¡αñ░αñ¡αñ░αñ╛ αñòαñ░ αñùαñ┐αñ░αñ╛ αñçαñ«αñ╛αñ░αññ αñòαñ╛ αñ¢αñ£αÑìαñ£αñ╛αÑñ αñ╕αÑéαñÜαñ¿αñ╛ αñòαÑç αñ¼αñ╛αñª αñ«αÑîαñòαÑç αñ¬αñ░ αñ¬αñ╣αÑüαñéαñÜαñ╛ αñ¬αÑìαñ░αñ╢αñ╛αñ╕αñ¿αÑñ αñ«αñéαñªαñ┐αñ░ αñ«αÑçαñé αñªαñ¼αÑç αñªαÑï αñ▓αÑïαñùαÑïαñé [αñ╕αñéαñùαÑÇαññ] αñòαÑï αñ░αÑçαñ╕αÑìαñòαÑìαñ»αÑé αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛αÑñ αñòαñ╛αñ½αÑÇ αñ╕αñ«αñ» αñ╕αÑç αñ£αñ£αñ░ αñ╕αÑìαñÑαñ┐αññαñ┐ αñ«αÑçαñé αñÑαÑÇ αñ»αñ╣ αñçαñ«αñ╛αñ░αññαÑñ\n15:44\n15 minutes, 44 seconds\nαñòαÑïαñƒαñªαÑìαñ╡αñ╛αñ░ αñòαÑç αñ░αñ╛αñ«αñ£αÑÇ αñùαñ╛αñéαñ╡ αñ«αÑçαñé αñÿαÑüαñ╕αñ╛ αñ╣αñ╛αñÑαÑÇαÑñ\n15:46\n15 minutes, 46 seconds\nαñùαÑìαñ░αñ╛αñ«αÑÇαñúαÑïαñé αñ«αÑçαñé αñàαñ½αñ░αñ╛αññαñ½αñ░αÑÇ αñ«αñÜαÑÇαÑñ αñ╢αÑïαñ░ αñ«αñÜαñ╛αñ¿αÑç αñ¬αñ░ αñ╣αñ╛αñÑαÑÇ αñ£αñéαñùαñ▓ αñòαÑÇ αññαñ░αñ½ αñ¡αñ╛αñù αñùαñ»αñ╛αÑñ αñ╡αñ¿ αñ╡αñ┐αñ¡αñ╛αñù αñ╕αÑç αñçαñ▓αñ╛αñòαÑç αñ«αÑçαñé αñùαñ╢αÑìαññ αñ¼αñóαñ╝αñ╛αñ¿αÑç αñòαÑÇ αñ«αñ╛αñéαñùαÑñ\n15:54\n15 minutes, 54 seconds\nαñ░αñ╛αñ£αñ╕αÑìαñÑαñ╛αñ¿ αñòαÑç αñòαñê αñçαñ▓αñ╛αñòαÑïαñé αñ«αÑçαñé αñ¼αñªαñ▓αñ╛ αñ«αÑîαñ╕αñ« αñòαñ╛ αñ«αñ┐αñ£αñ╛αñ£αÑñ αñ£αÑêαñ╕αñ▓αñ«αÑçαñ░ αñòαÑç αñ░αñ╛αñ«αñùαñóαñ╝ αñ╕αñ«αÑçαññ αñ╕αÑÇαñ«αñ╛αñ╡αñ░αÑìαññαÑÇ αñçαñ▓αñ╛αñòαÑïαñé αñ«αÑçαñé αñ¼αñ╛αñ░αñ┐αñ╢αÑñ αñ▓αÑïαñùαÑïαñé αñòαÑï αñùαñ░αÑìαñ«αÑÇ αñ╕αÑç αñ░αñ╛αñ╣αññ αñ«αñ┐αñ▓αÑÇαÑñ\n16:04\n16 minutes, 4 seconds\nαñ«αñ╣αñ┐αñ▓αñ╛ αñƒαÑÇ20 αñ╡αñ░αÑìαñ▓αÑìαñí αñòαñ¬ αñ«αÑçαñé αñåαñ£ αñ¡αñ╛αñ░αññ αñòαÑç αñ╕αñ╛αñ«αñ¿αÑç αñ╣αÑïαñùαÑÇ αñ¿αÑÇαñªαñ░αñ▓αÑêαñéαñíαÑìαñ╕ αñòαÑÇ αñƒαÑÇαñ«αÑñ αñ¬αñ╛αñòαñ┐αñ╕αÑìαññαñ╛αñ¿ αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñ╢αñ╛αñ¿αñªαñ╛αñ░ αñ£αÑÇαññ αñ╕αÑç αñ¡αñ╛αñ░αññ αñòαÑç αñ╣αÑîαñ╕αñ▓αÑç αñ¼αÑüαñ▓αñéαñª αñ╣αÑêαÑñ αñ╢αñ╛αñ« 7:00 αñ¼αñ£αÑç αñ╢αÑüαñ░αÑé αñ╣αÑïαñùαñ╛ αñ«αÑüαñòαñ╛αñ¼αñ▓αñ╛αÑñ\n16:14\n16 minutes, 14 seconds\nαñòαÑêαñ▓αñ┐αñ½αÑïαñ░αÑìαñ¿αñ┐αñ»αñ╛ αñòαÑç αñ░αñ┐αñ╡αñ░ αñ╕αñ╛αñçαñí αñòαñ╛αñëαñéαñƒ αñ«αÑçαñé αññαÑçαñ£αÑÇ αñ╕αÑç αñ½αÑêαñ▓ αñ░αñ╣αÑÇ αñ╣αÑê αñ£αñéαñùαñ▓ αñ«αÑçαñé αñ▓αñùαÑÇ αñ╣αÑüαñê αñåαñùαÑñ αñàαñ¼ αññαñò 2600 αñÅαñòαñíαñ╝ αñÅαñò αñ£αñ«αÑÇαñ¿ αñ«αÑçαñé αñ»αñ╣ αñåαñù αñ½αÑêαñ▓ αñÜαÑüαñòαÑÇ αñ╣αÑêαÑñ\n16:22\n16 minutes, 22 seconds\nαñ½αñ╛αñ»αñ░ αñ½αñ╛αñçαñƒαñ░αÑìαñ╕ αñ▓αñùαñ╛αññαñ╛αñ░ αñåαñù αñ¬αñ░ αñòαñ╛αñ¼αÑé αñ¬αñ╛αñ¿αÑç αñòαÑÇ αñòαÑïαñ╢αñ┐αñ╢ αñòαñ░ αñ░αñ╣αÑç αñ╣αÑêαñéαÑñ\n16:27\n16 minutes, 27 seconds\nαñ«αÑëαñ╕αÑìαñòαÑï αñ«αÑçαñé αñ░αñ╢αñ┐αñ»αñ╛ αñöαñ░ αññαÑüαñ░αÑìαñòαÑÇ αñòαÑç αñ╡αñ┐αñªαÑçαñ╢ αñ«αñéαññαÑìαñ░αñ┐αñ»αÑïαñé αñòαÑÇ αñ«αÑüαñ▓αñ╛αñòαñ╛αññαÑñ αññαÑüαñ░αÑìαñòαÑÇ αñ¿αÑç αñªαÑïαñ╣αñ░αñ╛αñê αñ»αÑéαñòαÑìαñ░αÑçαñ¿ αñ»αÑüαñªαÑìαñº αñ«αÑçαñé αñ«αñºαÑìαñ»αñ╕αÑìαñÑαññαñ╛ αñòαÑÇ αñ¬αÑçαñ╢αñòαñ╢αÑñ\n16:32\n16 minutes, 32 seconds\nαñ░αñ╢αñ┐αñ»αñ╛ [αñ╕αñéαñùαÑÇαññ] αñ¿αÑç αñ»αÑéαñòαÑìαñ░αÑçαñ¿ αñòαÑÇ αñ»αÑéαñ░αÑïαñ¬αÑÇαñ» αñ»αÑéαñ¿αñ┐αñ»αñ¿ αñ«αÑçαñé αñÅαñéαñƒαÑìαñ░αÑÇ αñ¬αñ░ αñ¡αÑÇ αñ╕αñ╡αñ╛αñ▓ αñëαñáαñ╛αñÅαÑñ\n16:36\n16 minutes, 36 seconds\nαñùαÑìαñ╡αñ╛αñÜαñ┐αñ«αñ╛αñ▓αñ╛ αñ«αÑçαñé αñàαñÜαñ╛αñ¿αñò αñåαñê αñ¼αñ╛αñóαñ╝ αñ¿αÑç αñ«αñÜαñ╛αñê αññαñ¼αñ╛αñ╣αÑÇαÑñ αññαÑçαñ£ αñ¼αñ╣αñ╛αñ╡ αñ«αÑçαñé αñ¼αñóαñ╝ αñùαñÅ αñòαñê αñ╡αñ╛αñ╣αñ¿αÑñ αñ¡αñ╛αñ░αÑÇ αñ¼αñ╛αñ░αñ┐αñ╢ αñòαÑç αñ¼αñ╛αñª αñ░αñ╛αñ╣αññ αñöαñ░ αñ¼αñÜαñ╛αñ╡ αñòαñ╛αñ░αÑìαñ» αñ£αñ╛αñ░αÑÇαÑñ\n16:45\n16 minutes, 45 seconds\nαñƒαÑêαñòαÑìαñ╕αÑçαñ╕ αñ«αÑçαñé αñ¡αñ╛αñ░αÑÇ αñ¼αñ╛αñ░αñ┐αñ╢ αñòαÑÇ αñ╡αñ£αñ╣ αñ╕αÑç αñ¼αñ╛αñóαñ╝ αñ£αÑêαñ╕αÑç αñ╣αñ╛αñ▓αñ╛αññ αñ¼αñ¿ αñùαñÅαÑñ αñæαñ╕αÑìαñƒαñ┐αñ¿ αñöαñ░ αñòαñéαñƒαÑìαñ░αÑÇ αñ«αÑçαñé αñ╣αÑüαñê αñ£αñ«αñòαñ░ αñ¼αñ╛αñ░αñ┐αñ╢αÑñ αññαñƒαÑÇαñ» αñçαñ▓αñ╛αñòαÑïαñé αñ«αÑçαñé αñ░αñ╣αñ¿αÑç αñ╡αñ╛αñ▓αÑç αñ▓αÑïαñùαÑïαñé αñòαÑï αñÉαññαñ┐αñ╣αñ╛ [αñ╕αñéαñùαÑÇαññ] αñ¿αñ┐αñ░αÑìαñªαÑçαñ╢αñ┐αññ αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛αÑñ\n17:04\n17 minutes, 4 seconds\nαñÅαñ¼αÑÇαñ¬αÑÇ αñ¿αÑìαñ»αÑéαñ£αñ╝ αñåαñ¬αñòαÑï αñ░αñûαÑç αñåαñùαÑçαÑñ	f	2026-06-17 12:27:12.219474
37	UCRWFSbif-RFENbBrSiez1DA	National	General	Transcript\nSearch transcript\n0:02\n2 seconds\nG7 [αñ╕αñéαñùαÑÇαññ] αñ╕αñ«αñ┐αñƒ αñ«αÑçαñé αñ¬αÑÇαñÅαñ« αñ«αÑïαñªαÑÇ αñöαñ░ αñíαÑïαñ¿αñ╛αñ▓αÑìαñí αñƒαÑìαñ░αñéαñ¬ αñòαÑÇ αñ«αÑüαñ▓αñ╛αñòαñ╛αññαÑñ 16 αñ«αñ╣αÑÇαñ¿αÑç αñ¼αñ╛αñª αñ«αñ┐αñ▓αÑç αñªαÑïαñ¿αÑïαñé αñ¿αÑçαññαñ╛αÑñ αñ«αÑïαñªαÑÇ αñöαñ░ αñƒαÑìαñ░αñéαñ¬ αñ¿αÑç αñÅαñò αñªαÑéαñ╕αñ░αÑç αñ╕αÑç αñ«αñ┐αñ▓αñ╛αñÅ αñ╣αñ╛αñÑαÑñ\n0:11\n11 seconds\nαñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñöαñ░ αñêαñ░αñ╛αñ¿ αñòαÑç αñ¼αÑÇαñÜ αñ╢αÑüαñòαÑìαñ░αñ╡αñ╛αñ░ αñòαÑï αñ╕αÑìαñ╡αñ┐αñƒαÑìαñ£αñ░αñ▓αÑêαñéαñí αñ«αÑçαñé αñ╣αÑïαñéαñùαÑç αñÅαñ«αñôαñ»αÑé αñ¬αñ░ αñ╕αñ╛αñçαñ¿αÑñ\n0:16\n16 seconds\nαñàαñ«αÑçαñ░αñ┐αñòαÑÇ αñíαÑçαñ▓αÑÇαñùαÑçαñ╢αñ¿ αñòαÑï αñ╣αÑçαñí αñòαñ░αÑçαñéαñùαÑç αñ£αÑçαñ░αÑÇ αñ╡αÑçαñéαñ╕αÑñ αñêαñ░αñ╛αñ¿ αñòαÑç αñ«αÑüαññαñ╛αñ¼αñ┐αñò αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñ¿αÑç αñ╕αñ¡αÑÇ αñ«αÑïαñ░αÑìαñÜαÑïαñé αñ¬αñ░ αñ»αÑüαñªαÑìαñº αñûαññαÑìαñ« αñòαñ░αñ¿αÑç αñòαÑÇ αñòαñ╣αÑÇ αñ╣αÑê αñ¼αñ╛αññαÑñ\n0:25\n25 seconds\nαñêαñ░αñ╛αñ¿ αñòαÑç αñ╕αñ╛αñÑ αñíαÑÇαñ▓ αñòαÑï αñƒαÑìαñ░αñéαñ¬ αñ¿αÑç αñ¼αññαñ╛αñ»αñ╛ αñ¿αñ┐αñ╖αÑìαñ¬αñòαÑìαñ╖αÑñ αñòαñ╣αñ╛ αñ╣αñ« αñêαñ░αñ╛αñ¿ αñ«αÑçαñé αñ¿αñ╣αÑÇαñé αñòαñ░ αñ░αñ╣αÑç αñ╣αÑêαñé αñòαÑïαñê αñ¿αñ┐αñ╡αÑçαñ╢αÑñ αñ¬αñ┐αñ¢αñ▓αÑç αñ╣αñ½αÑìαññαÑç αñëαñ¿ αñ¬αñ░ [αñ╕αñéαñùαÑÇαññ] αñ¿αñ╣αÑÇαñé αñòαñ░αñ¿αñ╛ αñÜαñ╛αñ╣αññαñ╛ αñÑαñ╛ αñ╣αñ«αñ▓αñ╛αÑñ\n0:35\n35 seconds\nαñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñòαÑç αñ╕αñ╛αñÑ αñ¼αñ╛αññαñÜαÑÇαññ αñ¬αñ░ αñ¼αÑïαñ▓αÑç αñêαñ░αñ╛αñ¿ αñòαÑç αñ╡αñ┐αñªαÑçαñ╢ αñ«αñéαññαÑìαñ░αÑÇ αñàαñ¼αÑìαñ¼αñ╛αñ╕ αñ╕αñ░αñ╛αñòαÑìαñ╖αÑÇαÑñ αñ╡αñ╛αñ░αÑìαññαñ╛ αñòαÑç αñ¬αñ╣αñ▓αÑç αñÜαñ░αñú αñ«αÑçαñé αñ╣αÑëαñ░αÑìαñ«αÑïαñ£ αñ¬αñ░ αñ╣αÑïαñùαÑÇ αñ¼αñ╛αññαÑñ αñªαÑéαñ╕αñ░αÑç αñÜαñ░αñú αñ«αÑçαñé αñ¬αñ░αñ«αñ╛αñúαÑü αñ«αÑüαñªαÑìαñªαÑç αñöαñ░ αñ¬αÑìαñ░αññαñ┐αñ¼αñéαñºαÑïαñé αñ«αÑçαñé αñóαÑÇαñ▓ αñ¬αñ░ αñòαÑÇ αñ£αñ╛αñÅαñùαÑÇ αñÜαñ░αÑìαñÜαñ╛αÑñ\n0:47\n47 seconds\nαñêαñ░αñ╛αñ¿ αñòαÑç αñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñöαñ░ αñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑï αñªαÑï αñƒαÑéαñò αñ╡αñ┐αñªαÑçαñ╢ αñ«αñéαññαÑìαñ░αÑÇ αñàαñ¼αÑìαñ¼αñ╛αñ╕ αñ╕αñ░αñ╛αñòαÑìαñ╖αÑÇ αñ¿αÑç αñòαñ╣αñ╛ αñ»αÑüαñªαÑìαñº αññαñ¼ αññαñò αñûαññαÑìαñ« αñ¿αñ╣αÑÇαñé αñ╣αÑïαñùαñ╛ αñ£αñ¼ αññαñò αñçαñ£αñ░αñ╛αñçαñ▓αÑÇ αñ╕αÑçαñ¿αñ╛ αñ▓αÑçαñ¼αñ¿ αñ«αÑçαñé αñòαñ¼αÑìαñ£αÑç αñ╡αñ╛αñ▓αÑç αñçαñ▓αñ╛αñòαÑïαñé αñ╕αÑç αñ╡αñ╛αñ¬αñ╕ αñ¿αñ╣αÑÇαñé αñ╣αñƒ αñ£αñ╛αññαÑÇ αñ╣αÑêαÑñ\n0:59\n59 seconds\nαñ░αÑéαñ╕ αñòαÑÇ αñ░αñ╛αñ£αñºαñ╛αñ¿αÑÇ αñ«αÑëαñ╕αÑìαñòαÑï αñòαÑç αñ¬αñ╛αñ╕ αñÅαñò αñæαñ»αñ▓ αñ░αñ┐αñ½αñ╛αñçαñ¿αñ░αÑÇ αñ¬αñ░ αñ»αÑéαñòαÑìαñ░αÑçαñ¿ αñòαñ╛ αñíαÑìαñ░αÑïαñ¿ αñàαñƒαÑêαñòαÑñ αñ╣αñ«αñ▓αÑç αñòαÑç αñ¼αñ╛αñª αñ▓αñùαÑÇ αñ¡αÑÇαñ╖αñú αñåαñùαÑñ αñ«αÑëαñ╕αÑìαñòαÑï αñ╕αÑç αñ╕αñ┐αñ░αÑìαñ½ 15 αñòαñ┐.αñ«αÑÇ. αñòαÑÇ αñªαÑéαñ░αÑÇ αñ¬αñ░ αñ╣αÑê αñæαñ»αñ▓ αñ░αñ┐αñ½αñ╛αñçαñ¿αñ░αÑÇαÑñ\n1:10\n1 minute, 10 seconds\nαñ£αÑÇ7 αñ╕αñ«αñ┐αñƒ αñ«αÑçαñé αñ¼αÑïαñ▓αÑÇ αñ»αÑéαñòαÑìαñ░αÑçαñ¿ αñòαÑç αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ¬αññαñ┐ αñ£αÑçαñ▓αñ╕αÑìαñòαÑÇαÑñ αñòαñ╣αñ╛ G7 αñ¿αÑçαññαñ╛αñôαñé αñ¿αÑç αñ»αÑéαñòαÑìαñ░αÑçαñ¿ αñòαÑç αñ▓αñ┐αñÅ αñªαñ┐αñûαñ╛αñê αñÅαñòαñ£αÑüαñƒαññαñ╛αÑñ αñ╣αñ« αñàαñ¡αÑÇ αñ¡αÑÇ αñ╕αñéαñÿαñ░αÑìαñ╖ αñ╡αñ┐αñ░αñ╛αñ« αñòαÑç αñ▓αñ┐αñÅ αññαÑêαñ»αñ╛αñ░ αñ╣αÑêαñéαÑñ\n1:21\n1 minute, 21 seconds\nαñàαñ»αÑïαñºαÑìαñ»αñ╛ αñ░αñ╛αñ« αñ«αñéαñªαñ┐αñ░ αñÜαñéαñªαñ╛ αñÜαÑïαñ░αÑÇ αñ«αñ╛αñ«αñ▓αÑç αñ«αÑçαñé αñÅαñ╕αñåαñêαñƒαÑÇ αñ¿αÑç αñàαñ¼ αññαñò 43 αñ▓αÑïαñùαÑïαñé αñ╕αÑç αñòαÑÇ αñ¬αÑéαñ¢αññαñ╛αñ¢αÑñ\n1:26\n1 minute, 26 seconds\nαñ«αñéαñªαñ┐αñ░ αñòαÑç αñ¬αÑüαñ£αñ╛αñ░αñ┐αñ»αÑïαñé αñöαñ░ αñƒαÑìαñ░αñ╕αÑìαñƒ αñòαÑç αñ¬αñªαñ╛αñºαñ┐αñòαñ╛αñ░αñ┐αñ»αÑïαñé αñ╕αÑç αñ╕αñ╡αñ╛αñ▓ αñ£αñ╡αñ╛αñ¼αÑñ\n1:32\n1 minute, 32 seconds\nαñ░αñ╛αñ« αñ«αñéαñªαñ┐αñ░ αñÜαñéαñªαñ╛ αñÜαÑïαñ░αÑÇ αñ«αñ╛αñ«αñ▓αÑç αñòαÑï αñ▓αÑçαñòαñ░ αñàαñûαñ┐αñ▓αÑçαñ╢ αñ»αñ╛αñªαñ╡ αñ¿αÑç αñ╕αñ░αñòαñ╛αñ░ [αñ╕αñéαñùαÑÇαññ] αñòαÑï αñÿαÑçαñ░αñ╛αÑñ αñòαñ╣αñ╛ αñ£αñ╣αñ╛αñé αñåαñêαñåαñêαñƒαÑÇ αñ¼αñ¿αñ¿αÑÇ αñÑαÑÇ αñ╡αñ╣αñ╛αñé αñÅαñ╕αñåαñêαñƒαÑÇ αñ¼αñ¿ αñ░αñ╣αÑÇ αñ╣αÑêαÑñ\n1:41\n1 minute, 41 seconds\nαñ»αÑéαñ¬αÑÇ αñòαÑç αñ╕αÑÇαñÅαñ« αñ»αÑïαñùαÑÇ αñ¿αÑç αñ¼αñ»αñ╛αñé αñòαñ┐αñ»αñ╛ αñàαñ¬αñ¿αñ╛ αñ¬αñ╣αñ▓αñ╛ αñ¬αñ╕αñéαñª αñ¼αÑïαñ▓αÑç αñ«αñ╛αñ½αñ┐αñ»αñ╛αñôαñé αñòαñ╛ αñûαñ╛αññαÑìαñ«αñ╛ αñ╣αÑÇ αñ«αÑçαñ░αñ╛ αñ¬αÑìαñ░αñ┐αñ» αñ╡αñ┐αñ╖αñ» αñ╣αÑêαÑñ\n1:50\n1 minute, 50 seconds\nαñƒαÑÇαñÅαñ«αñ╕αÑÇ αñòαÑç αñ¼αñ╛αñùαÑÇ αñ╕αñ╛αñéαñ╕αñªαÑïαñé αñòαÑç αñ╡αñ┐αñ▓αñ» αñ¬αñ░ αñ½αñéαñ╕αñ╛ αñ¬αÑçαñÜαÑñ αñ▓αÑïαñòαñ╕αñ¡αñ╛ αñàαñºαÑìαñ»αñòαÑìαñ╖ αñªαÑïαñ¿αÑïαñé αñùαÑüαñƒαÑïαñé αñòαÑç αñ╕αñ╛αñéαñ╕αñªαÑïαñé αñ╕αÑç αñ¼αñ╛αññαñÜαÑÇαññ αñòαÑç αñ¼αñ╛αñª αñ▓αÑçαñéαñùαÑç αñåαñûαñ┐αñ░αÑÇ αñ½αÑêαñ╕αñ▓αñ╛αÑñ\n1:58\n1 minute, 58 seconds\nαñ¬αñ╢αÑìαñÜαñ┐αñ« αñ¼αñéαñùαñ╛αñ▓ αñòαÑç αñ░αñ╛αñ¿αÑÇαñùαñéαñ£ αñ«αÑçαñé αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ¿αÑçαññαñ╛ αñ╕αÑîαñ«αñ┐αññαÑìαñ░ αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñ¬αñ░ αñ½αÑçαñéαñòαÑç αñùαñÅ αñàαñéαñíαÑçαÑñ αñòαÑïαñ░αÑìαñƒ αñ▓αÑç αñ£αñ╛αñ¿αÑç αñòαÑç αñªαÑîαñ░αñ╛αñ¿ αñ╕αÑîαñ«αñ┐αññαÑìαñ░ αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñ¬αñ░ αñàαñéαñíαÑïαñé αñ╕αÑç αñ╣αñ«αñ▓αñ╛αÑñ\n2:08\n2 minutes, 8 seconds\nαñ¬αñ╛αñ░αÑìαñƒαÑÇ αñ«αÑçαñé αñƒαÑéαñƒ αñòαÑÇ αñàαñƒαñòαñ▓αÑïαñé αñòαÑç αñ¼αÑÇαñÜ αñëαñªαÑìαñºαñ╡ αñáαñ╛αñòαñ░αÑç αñòαñ╛ αñ¼αñíαñ╝αñ╛ αñ¼αñ»αñ╛αñ¿αÑñ αñ¼αÑïαñ▓αÑç αñàαñùαñ░ αñòαñ┐αñ╕αÑÇ αñòαÑï αñ£αñ╛αñ¿αñ╛ αñ╣αÑê αññαÑï αñûαÑüαñ╢αÑÇ αñ╕αÑç αñ£αñ╛αñÅαÑñ αñ╢αñ┐αñ╡αñ╕αÑçαñ¿αñ╛ αñ¿αÑç αñòαñ╣αñ╛ αñ╕αñ╛αññ αñ╕αñ╛αñéαñ╕αñª αñåαñ¿αÑç αñòαÑï αñ╣αÑêαñé αññαÑêαñ»αñ╛αñ░αÑñ\n2:18\n2 minutes, 18 seconds\nαñ¥αñ╛αñ░αñûαñéαñí αñ░αñ╛αñ£αÑìαñ»αñ╕αñ¡αñ╛ αñÜαÑüαñ¿αñ╛αñ╡ αñ«αÑçαñé αñòαÑìαñ░αÑëαñ╕ αñ╡αÑïαñƒαñ┐αñéαñù αñ░αÑïαñòαñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ αñÅαñ¿αñíαÑÇαñÅ αñòαñ╛ αñ¼αñíαñ╝αñ╛ αñ½αÑêαñ╕αñ▓αñ╛αÑñ\n2:22\n2 minutes, 22 seconds\nαñ╡αñ┐αñºαñ╛αñ»αñòαÑïαñé αñòαÑï αñ░αñ╛αñéαñÜαÑÇ αñòαÑç αñ╣αÑïαñƒαñ▓ αñ«αÑçαñé αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛ αñ╢αñ┐αñ½αÑìαñƒαÑñ\n2:27\n2 minutes, 27 seconds\nαñôαñ╡αÑêαñ╕αÑÇ αñòαÑç αñ«αÑüαñ╕αÑìαñ▓αñ┐αñ« αñ▓αÑÇαñíαñ░αñ╢αñ┐αñ¬ αñ╡αñ╛αñ▓αÑç αñ¼αñ»αñ╛αñ¿ αñ¬αñ░ αñàαñûαñ┐αñ▓αÑçαñ╢ αñ»αñ╛αñªαñ╡ αñòαñ╛ αñ£αñ╡αñ╛αñ¼αÑñ αñòαñ╣αñ╛ αñ£αÑï αñçαñéαñíαñ┐αñ»αñ╛ αñùαñáαñ¼αñéαñºαñ¿ αñÑαñ╛ αñ╡αñ╣αÑÇ αñ¼αñ¿αñ╛ αñ░αñ╣αÑçαñùαñ╛αÑñ αñ¼αÑÇαñ£αÑçαñ¬αÑÇ αñòαÑï αñ½αñ╛αñ»αñªαñ╛ αñ¬αñ╣αÑüαñéαñÜαñ╛αñ¿αñ╛ αñÜαñ╛αñ╣αññαÑç αñ╣αÑêαñé αñÉαñ╕αÑç αñ▓αÑïαñùαÑñ\n2:38\n2 minutes, 38 seconds\nαñ╢αÑìαñ░αÑÇ αñàαñòαñ╛αñ▓ αññαñûαÑìαññ αñ╕αñ╛αñ╣αñ┐αñ¼ αñòαÑç αñ½αÑêαñ╕αñ▓αÑç αñ¬αñ░ αñ╕αÑÇαñÅαñ« αñ«αñ╛αñ¿ αñòαÑÇ αñ╕αñ½αñ╛αñêαÑñ αñòαñ╣αñ╛ αñ╕αñ┐αñ»αñ╛αñ╕αÑÇ αñåαñòαñ╛αñôαñé αñòαÑç αñçαñ╢αñ╛αñ░αÑç αñ¬αñ░ αñ«αÑüαñ¥αÑç αñ¼αñªαñ¿αñ╛αñ« αñòαñ░αñ¿αÑç αñòαÑÇ αñòαÑïαñ╢αñ┐αñ╢αÑñ αñ«αÑêαñé αñàαñòαñ╛αñ▓\n2:45\n2 minutes, 45 seconds\nαññαñûαÑìαññ αñòαÑï αñ╕αñ░αÑìαñ╡αÑïαñÜαÑìαñÜ αñ«αñ╛αñ¿αññαñ╛ αñ╣αÑéαñé αñöαñ░ αññαñûαÑìαññ αñòαÑç αñåαñùαÑç αñ╕αñ┐αñ░ αñ¥αÑüαñòαñ╛αññαñ╛ αñ╣αÑéαñéαÑñ\n2:51\n2 minutes, 51 seconds\nαñ¬αÑìαñ░αñºαñ╛αñ¿αñ«αñéαññαÑìαñ░αÑÇ αñ«αÑïαñªαÑÇ αñ¿αÑç αñ»αÑïαñù αñªαñ┐αñ╡αñ╕ αñòαÑï αñ▓αÑçαñòαñ░ αñ▓αñ┐αñûαÑç αñùαÑìαñ░αñ╛αñ« αñ¬αÑìαñ░αñºαñ╛αñ¿αÑïαñé αñòαÑï αñÜαñ┐αñƒαÑìαñáαÑÇ αñöαñ░ αñùαÑìαñ░αñ╛αñ« αñ¬αñéαñÜαñ╛αñ»αññ αñ«αÑçαñé αñ»αÑïαñù αñªαñ┐αñ╡αñ╕ αñ«αñ¿αñ╛αñ¿αÑç αñòαÑÇ αñàαñ¬αÑÇαñ▓ αñòαÑÇαÑñ\n3:00\n3 minutes\nαññαñ«αñ┐αñ▓αñ¿αñ╛αñíαÑü αñ«αÑçαñé αñ¿αÑÇαñƒ αñ¬αÑçαñ¬αñ░ αñ▓αÑç αñ£αñ╛αñ¿αÑç αñòαÑÇ αñ░αñ┐αñ╣αñ▓αñ╕αñ▓αÑñ\n3:02\n3 minutes, 2 seconds\nαñÅαñ»αñ░αñ½αÑïαñ░αÑìαñ╕ αñòαÑç αñ╣αÑçαñ▓αÑÇαñòαÑëαñ¬αÑìαñƒαñ░ αñ╕αÑç αñ¿αÑÇαñƒ αñ¬αÑçαñ¬αñ░ αñòαÑï αñ«αñªαñªαÑüαñ░αñê αñ╕αÑç αññαÑüαñ░αÑüαñ¿αÑçαñ▓ αñ╡αÑçαñ▓αñ╡αÑÇ αñ▓αÑç αñ£αñ╛αñ¿αÑç αñòαñ╛ αñàαñ¡αÑìαñ»αñ╛αñ╕αÑñ 21 αñ£αÑéαñ¿ αñòαÑï αñ╣αÑïαñ¿αÑç αñ╡αñ╛αñ▓αÑÇ αñ╣αÑê αñ¿αÑÇαñƒ αñòαÑÇ αñªαÑïαñ¼αñ╛αñ░αñ╛ αñ¬αñ░αÑÇαñòαÑìαñ╖αñ╛αÑñ\n3:12\n3 minutes, 12 seconds\nαñ░αñ╛αñ£αñ╕αÑìαñÑαñ╛αñ¿ αñòαÑç αñòαÑïαñƒαñ╛ αñ«αÑçαñé αñòαñ▓ αñ¢αñ╛αññαÑìαñ░αÑïαñé αñ╕αÑç αñ╕αñéαñ╡αñ╛αñª αñòαñ░αÑçαñéαñùαÑç αñ░αñ╛αñ╣αÑüαñ▓ αñùαñ╛αñéαñºαÑÇαÑñ αñ╡αÑÇαñíαñ┐αñ»αÑï αñ£αñ╛αñ░αÑÇ αñòαñ░ αñòαñ╣αñ╛ αñ»αÑüαñ╡αñ╛αñôαñé αñòαñ╛ αñ¡αñ╡αñ┐αñ╖αÑìαñ» αñ╕αÑüαñ░αñòαÑìαñ╖αñ┐αññ αñòαñ░αñ¿αñ╛αÑñ αñ╕αñ░αñòαñ╛αñ░ αñòαÑÇ αñ£αñ┐αñ«αÑìαñ«αÑçαñªαñ╛αñ░αÑÇ αñ▓αÑçαñòαñ┐αñ¿ αñ»αÑüαñ╡αñ╛αñôαñé αñòαÑç αñ╕αñ¬αñ¿αÑç αññαÑïαñíαñ╝ αñ░αñ╣αÑÇ αñ╕αñ░αñòαñ╛αñ░αÑñ\n3:24\n3 minutes, 24 seconds\nαñƒαÑçαñ▓αÑÇαñùαÑìαñ░αñ╛αñ« αñ¬αñ░ 22 αñ£αÑéαñ¿ αññαñò αñòαñ╛ αñ╕αÑìαñÑαñ╛αñê αñ░αÑïαñùαÑñ\n3:26\n3 minutes, 26 seconds\n[αñ╕αñéαñùαÑÇαññ] αñ¿αÑÇαñƒ αñ░αÑÇ αñÅαñùαÑìαñ£αñ╛αñ« αñòαÑï αñ▓αÑçαñòαñ░ αñòαÑçαñéαñªαÑìαñ░ αñ╕αñ░αñòαñ╛αñ░ αñòαñ╛ αñ½αÑêαñ╕αñ▓αñ╛αÑñ αñ«αÑêαñ╕αÑçαñ£ αñÅαñíαñ┐αñƒ αñ½αÑÇαñÜαñ░ αñ¼αñéαñªαÑñ\n3:33\n3 minutes, 33 seconds\nαñòαÑçαñéαñªαÑìαñ░αÑÇαñ» αñ╕αÑìαñ╡αñ╛αñ╕αÑìαñÑαÑìαñ» αñ«αñéαññαÑìαñ░αñ╛αñ▓αñ» αñòαñ╛ αñ¼αñíαñ╝αñ╛ αñ½αÑêαñ╕αñ▓αñ╛αÑñ αñàαñ¼ αñíαÑëαñòαÑìαñƒαñ░ αñòαÑÇ αñ¬αñ░αÑìαñÜαÑÇ αñòαÑç αñ¼αñ┐αñ¿αñ╛ αñ¿αñ╣αÑÇαñé αñ«αñ┐αñ▓αÑçαñùαñ╛ αñòαñ¬ αñ╕αñ┐αñ░αñ¬αÑñ\n3:41\n3 minutes, 41 seconds\nαñ░αñ╛αñ£αñ╕αÑìαñÑαñ╛αñ¿ αñòαÑç αñ¼αÑÇαñòαñ╛αñ¿αÑçαñ░ αñ«αÑçαñé αñëαñáαñ╛ αñ░αÑçαññ αñòαñ╛ αñ¼αñ╡αñéαñíαñ░αÑñ αñòαÑüαñ¢ αñ╣αÑÇ αñªαÑçαñ░ αñ«αÑçαñé αñºαÑéαñ▓ αñ╕αÑç αñ¡αñ░ αñùαñ»αñ╛ αñ¬αÑéαñ░αñ╛ αñ╢αñ╣αñ░αÑñ αñºαÑéαñ▓ αñ¡αñ░αÑÇ αñåαñéαñºαÑÇ αñ╕αÑç αñ£αñ¿αñ£αÑÇαñ╡αñ¿ αñ╣αÑüαñå αñàαñ╕αÑìαññ-αñ╡αÑìαñ»αñ╕αÑìαññαÑñ\n3:50\n3 minutes, 50 seconds\nαñ£αñ«αÑìαñ«αÑé αñòαñ╢αÑìαñ«αÑÇαñ░ αñòαÑç αñ░αñ╛αñ£αÑîαñ░αÑÇ αñ«αÑçαñé 25αñ╡αÑçαñé αñªαñ┐αñ¿ αñ¡αÑÇ αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñ¼αñ▓αÑïαñé αñòαñ╛ αñæαñ¬αñ░αÑçαñ╢αñ¿ αñ£αñ╛αñ░αÑÇαÑñ αñÿαñ¿αÑç αñ£αñéαñùαñ▓αÑïαñé αñ«αÑçαñé αñåαññαñéαñòαñ╡αñ╛αñªαñ┐αñ»αÑïαñé αñòαÑÇ αññαñ▓αñ╛αñ╢αÑñ\n3:58\n3 minutes, 58 seconds\nαñ¬αÑÇαñôαñòαÑç αñòαÑç αñ░αñ╛αñ╡αñ▓αñòαÑïαñƒ αñ«αÑçαñé αñ¬αñ╛αñòαñ┐αñ╕αÑìαññαñ╛αñ¿αÑÇ αñ╕αñ░αñòαñ╛αñ░ αñöαñ░ αñ╕αÑçαñ¿αñ╛ αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñ¬αÑìαñ░αñªαñ░αÑìαñ╢αñ¿ αñ£αñ╛αñ░αÑÇαÑñ αñ¼αñ╕ αñƒαñ░αÑìαñ«αñ┐αñ¿αñ▓ αñ¬αñ░ αñ╣αñ£αñ╛αñ░αÑïαñé αñ«αñ╣αñ┐αñ▓αñ╛αñÅαñé αñºαñ░αñ¿αÑç αñ¬αñ░ αñ¼αñ╕ αñƒαñ░αÑìαñ«αñ┐αñ¿αñ▓ αñòαÑï αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛ αñ¼αñéαñªαÑñ\n4:10\n4 minutes, 10 seconds\nαñ░αÑéαñ╕ αñòαÑç αñçαñ░αññαÑìαñ╕αÑüαñò αñ╢αñ╣αñ░ αñ«αÑçαñé αñƒαÑìαñ░αÑçαñ¿αñ┐αñéαñù αñ½αÑìαñ▓αñ╛αñçαñƒ αñòαÑç αñªαÑîαñ░αñ╛αñ¿ αñƒαÑÇαñ»αÑé 222 αñÅαñ«3 αñ¼αñ«αñ¼αñ░ αñòαÑìαñ░αÑêαñ╢ αñòαÑìαñ░αÑé αñ«αÑçαñéαñ¼αñ░αÑìαñ╕ αñòαñ╛ αñòαñ┐αñ»αñ╛ αñùαñ»αñ╛ αñ░αÑçαñ╕αÑìαñòαÑìαñ»αÑéαÑñ αñçαñéαñ£αñ¿ αñòαñ╛ αñ½αÑçαñ▓ αñ╣αÑïαñ¿αñ╛ αñ¼αññαñ╛αñ»αñ╛ αñ£αñ╛ αñ░αñ╣αñ╛ αñ╣αÑê αñ╣αñ╛αñªαñ╕αÑç αñòαñ╛ αñòαñ╛αñ░αñúαÑñ\n4:22\n4 minutes, 22 seconds\n[αñ╕αñéαñùαÑÇαññ]\n4:27\n4 minutes, 27 seconds\n[αñ╕αñéαñùαÑÇαññ]\n4:28\n4 minutes, 28 seconds\nαñÅαñ¼αÑÇαñ¬αÑÇ αñ¿αÑìαñ»αÑéαñ£αñ╝ αñåαñ¬αñòαÑï αñ░αñûαÑç αñåαñùαÑçαÑñ	f	2026-06-17 12:27:12.22624
38	UCQIycDaLsBpMKjOCeaKUYVg	National	Finance	Transcript\nSearch transcript\n0:01\n1 second\nαñ╕αÑüαñ¬αÑìαñ░αñ¡αñ╛αññ αñùαÑüαñí αñ«αÑëαñ░αÑìαñ¿αñ┐αñéαñù αñƒαÑëαñ¬ 20 αñòαÑç αñåαñ£ αñòαÑç αñçαñ╕ αñ╡αÑçαñíαñ¿αÑçαñ╕αñíαÑç αñÅαñ¬αñ┐αñ╕αÑïαñí αñ«αÑçαñé αñåαñ¬ αñ╕αñ¼αñòαñ╛ αñ╕αÑìαñ╡αñ╛αñùαññ αñ╣αÑêαÑñ\n0:08\n8 seconds\nαññαÑÇαñ¿ αñªαñ┐αñ¿ αñçαñ¿ αñùαÑìαñ░αÑÇαñ¿ αñòαñ╛αñ«αñòαñ╛αñ£ αñöαñ░ αñåαñ£ αñ▓αñ╛αñ░αÑìαñ£αñ▓αÑÇ αñÑαÑïαñíαñ╝αñ╛ αñ╕αñ╛ αñòαñéαñ╕αÑïαñ▓αñ┐αñíαÑçαñ╢αñ¿ αñƒαñ╛αñçαñ¬ αñ«αÑéαñ╡αÑñ αñ╣αñ╛αñ▓αñ╛αñéαñòαñ┐ αñòαÑìαñ»αÑéαñ£αñ╝ αñàαñ¡αÑÇ αñ¡αÑÇ αñ¼αñóαñ╝αñ┐αñ»αñ╛ αñ╣αÑêαÑñ αñòαÑìαñ░αÑéαñí αñàαñùαñ░\n0:16\n16 seconds\nαñçαñéαñ¬αÑëαñ░αÑìαñƒαÑçαñéαñƒ αñÑαñ╛ αññαÑï αñ╡αÑï αñöαñ░ αñòαÑéαñ▓ αñæαñ½ αñ╣αÑÇ αñ╣αÑï αñ░αñ╣αñ╛ αñ╣αÑê $80 αñòαÑç αñ¿αÑÇαñÜαÑçαÑñ αñ¬αñ░ αñªαÑüαñ¿αñ┐αñ»αñ╛ αñ¡αñ░ αñ«αÑçαñé αñÑαÑïαñíαñ╝αñ╛ αñ╕αñ╛ αñ«αñ┐αñ▓αñ╛αñ£αÑüαñ▓αñ╛ αñ╣αÑÇ αñ░αÑüαñ¥αñ╛αñ¿ αñªαÑçαñûαñ¿αÑç αñòαÑï αñ«αñ┐αñ▓ αñ░αñ╣αñ╛ αñ╣αÑê\n0:24\n24 seconds\nαñåαñ¬αñòαÑïαÑñ αñÉαñ╕αÑç αñ«αÑçαñé αñåαñ£ αñòαÑç αñƒαÑëαñ¬ 20 αñ╕αÑìαñƒαÑëαñòαÑìαñ╕ αñòαÑîαñ¿ αñ╕αÑç αñ╣αÑïαñéαñùαÑç? αñëαñ¿αñòαÑÇ αñòαñ░ αñ▓αÑÇ αñ£αñ╛αñÅ αñÜαñ░αÑìαñÜαñ╛αÑñ αñòαÑîαñ¿ αñ╕αÑç αñ╣αÑïαñéαñùαÑç?\n0:30\n30 seconds\nαñ╣αñ« αñ«αñ╛αñ░αÑìαñòαÑçαñƒ αñàαñùαñ░ αñåαñ¬ αñªαÑçαñûαÑçαñé αññαÑï αñ½αñ┐αñ▓αñ╣αñ╛αñ▓ αñùαñ┐αñ½αÑìαñƒ αñ¿αñ┐αñ½αÑìαñƒαÑÇ αñåαñ¬αñòαÑï αñ╣αñ▓αÑìαñòαñ╛ αñ╕αñ╛ αñ½αÑìαñ▓αÑêαñƒ αñ╣αÑÇ αñ¿αñ£αñ░ αñåαñÅαñùαñ╛αÑñ\n0:34\n34 seconds\nαñ▓αÑçαñòαñ┐αñ¿ αñ¼αñóαñ╝αñ┐αñ»αñ╛ αñ¼αñ╛αññ αñ»αñ╣ αñ╣αÑê αñòαñ┐ αñòαÑìαñ░αÑéαñí αñàαñ¼ αñ¼αñ╣αÑüαññ αñ╣αÑÇ αñòαñéαñ½αñ░αÑìαñƒαÑçαñ¼αñ▓ αñ▓αÑçαñ╡αñ▓ αñ¬αñ░ αñå αñ░αñ╣αñ╛ αñ╣αÑêαÑñ 3 αñ«αñ╣αÑÇαñ¿αÑç αñ╕αÑç αñ£αÑìαñ»αñ╛αñªαñ╛ αñòαÑç αñ¿αñ┐αñ╢αÑìαñÜαñ┐αññ αñ╕αÑìαññαñ░ αñ¬αñ░ αñ╣αÑêαÑñ αññαÑï αñ»αÑç αñ¡αñ╛αñ░αññαÑÇαñ» αñ«αñ╛αñ░αÑìαñòαÑçαñƒαÑìαñ╕ αñòαÑç αñ▓αñ┐αñÅ αñòαñ╛αñ½αÑÇ αñàαñÜαÑìαñ¢αñ╛ αñ╣αÑêαÑñ\n0:41\n41 seconds\nαñ¼αñ╛αñòαÑÇ αñåαñ¬ αññαÑÇαñ¿ αñªαñ┐αñ¿αÑïαñé αñòαÑç αñ¬αÑìαñ░αñ╛αñçαñ╕ αñÅαñòαÑìαñ╢αñ¿ αñªαÑçαñûαÑçαñé αññαÑï αñ¼αñíαñ╝αÑç αñçαñéαñƒαñ░αÑçαñ╕αÑìαñƒαñ┐αñéαñù αñªαÑçαñûαñ¿αÑç αñòαÑï αñ«αñ┐αñ▓ αñ░αñ╣αñ╛ αñ╣αÑêαÑñ αñ╕αÑìαñƒαÑëαñòαÑìαñ╕ αñòαÑÇ αñ▓αñ┐αñ╕αÑìαñƒ αñåαñ£ αñ¼αñíαñ╝αÑÇ αñçαñéαñƒαñ░αÑçαñ╕αÑìαñƒαñ┐αñéαñù αñ╣αÑêαÑñ\n0:47\n47 seconds\nαñöαñ░ αñ╢αÑüαñ░αÑüαñåαññ αñ«αÑêαñé αñòαñ░αÑéαñéαñùαñ╛ LG αñçαñ▓αÑçαñòαÑìαñƒαÑìαñ░αÑëαñ¿αñ┐αñòαÑìαñ╕ αñòαÑç αñ╕αñ╛αñÑ αñöαñ░ αñ»αÑç αñ¬αÑéαñ░αÑÇ αñòαñéαñ£αÑìαñ»αÑéαñ«αñ░ αñíαÑìαñ»αÑéαñ░αÑçαñ¼αñ▓ αñòαÑÇ αñÑαÑÇαñ« αñ╣αÑêαÑñ αñêαñÅαñ«αñÅαñ╕ αñòαÑÇ αñÑαÑÇαñ« αñ╣αÑêαÑñ αñçαñ╕αñòαÑç αñèαñ¬αñ░ αñ«αñ╛αñ░αÑìαñòαÑçαñƒ αñòαñ╛ αñ½αÑïαñòαñ╕ αñªαÑïαñ¼αñ╛αñ░αñ╛ αñ╕αÑç αñå αñ░αñ╣αñ╛ αñ╣αÑêαÑñ αñàαñ¼\n0:55\n55 seconds\nαñçαñ╕αñòαÑç αñ¬αÑÇαñ¢αÑç αñªαÑï αñòαñ╛αñ░αñú αñ╣αÑêαÑñ LG αñçαñ▓αÑçαñòαÑìαñƒαÑìαñ░αÑëαñ¿αñ┐αñòαÑìαñ╕ αñ¬αñ░ αñÅαñò αññαÑï αñåαñ£ αñ╕αÑÇαñÅαñ▓αñÅαñ╕αÑÇ αñòαÑÇ αññαñ░αñ½ αñ╕αÑç αñ░αñ┐αñ¬αÑïαñ░αÑìαñƒ αñåαñê αñ╣αÑê αñöαñ░ αñªαÑéαñ╕αñ░αñ╛ αñªαÑçαñ╢ αñòαÑç αñòαñê αñ╣αñ┐αñ╕αÑìαñ╕αÑïαñé αñ«αÑçαñé αñ£αÑï αñ«αñ╛αñ¿αñ╕αÑéαñ¿ αñíαñ┐αñ▓αÑç αñ╣αÑï αñ░αñ╣αñ╛ αñ╣αÑê αñçαñ╕αñòαÑç αñÜαñ▓αññαÑç αñ«αñ╛αñ¿αñ╛ αñ£αñ╛\n1:04\n1 minute, 4 seconds\nαñ░αñ╣αñ╛ αñ╣αÑê αñòαñ┐ αñ£αÑï αñòαÑéαñ▓αñ┐αñéαñù αñ¬αÑìαñ░αÑïαñíαñòαÑìαñƒαÑìαñ╕ αñòαÑÇ αñ¼αñ┐αñòαÑìαñ░αÑÇ αñ╣αÑê αñàαñ¼ αñçαñ╕αñòαÑï αñÑαÑïαñíαñ╝αñ╛ αñ╕αñ╛ αñ¼αñ┐αñòαñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ αñ£αÑìαñ»αñ╛αñªαñ╛ αñ╕αñ«αñ» αñåαñ¬αñòαÑï αñ«αñ┐αñ▓ αñ£αñ╛αñÅαñùαñ╛αÑñ αñàαñ¼ αñ╕αÑÇαñÅαñ▓αñÅαñ╕αñÅ αñ¿αÑç αñåαñëαñƒαñ¬αñ░αñ½αÑëαñ░αÑìαñ« αñòαÑÇ αñ░αÑçαñƒαñ┐αñéαñù αñòαÑç αñ╕αñ╛αñÑ Γé╣1830 αñòαñ╛\n1:13\n1 minute, 13 seconds\nαñƒαñ╛αñ░αñùαÑçαñƒ αñªαñ┐αñ»αñ╛ αñ╣αÑê αñöαñ░ αñ»αÑç αñ¼αññαñ╛ αñ░αñ╣αÑç αñ╣αÑêαñé αñòαñ┐ αñ«αñ╛αñ░αÑìαñòαÑçαñƒ αñ▓αÑÇαñíαñ░ αñ╣αÑêαÑñ αñûαñ╛αñ╕αññαÑîαñ░ αñ¬αñ░ αñàαñùαñ░ αñåαñ¬ αñªαÑçαñûαÑçαñé αññαÑï αñ▓αñ╛αñ░αÑìαñ£ αñàαñ¬αÑìαñ▓αñ╛αñ»αñéαñ╕αÑçαñ╕ αñ«αÑçαñé αñòαñê αñ╕αñ╛αñ▓αÑïαñé αñòαñ╛ αñƒαÑìαñ░αÑêαñò αñ░αñ┐αñòαÑëαñ░αÑìαñí αñ╣αÑê αñ¼αñ╣αÑüαññ αñ¼αñóαñ╝αñ┐αñ»αñ╛ αñùαÑìαñ░αÑïαñÑ αñòαñ╛ αñöαñ░\n1:21\n1 minute, 21 seconds\nαñåαñùαÑç αñ£αñ╛αñòαÑç αñ«αñ╛αñ░αÑìαñ£αñ┐αñ¿ αñòαÑÇ αñƒαÑçαñ▓ αñ╡αñ┐αñéαñíαÑìαñ╕ αñ¡αÑÇ αñ»αñ╣αñ╛αñé αñ¬αñ░ αñªαÑçαñûαñ¿αÑç αñòαÑï αñ«αñ┐αñ▓ αñ░αñ╣αÑÇ αñ╣αÑêαÑñ αññαÑï LG αñçαñ▓αÑçαñòαÑìαñƒαÑìαñ░αÑëαñ¿αñ┐αñòαÑìαñ╕ αñ»αÑç αñ¬αñ╣αñ▓αñ╛ αñ╕αÑìαñƒαÑëαñò αñ╣αÑê αñ£αñ┐αñ╕αÑç αñçαñ¿αñùαÑìαñ░αÑÇαñ¿ αñ░αñûαñ╛ αñ╣αÑêαÑñ αñªαÑéαñ╕αñ░αñ╛ αñ╕αÑìαñƒαÑëαñò αñ╣αÑê ITCαÑñ αñ»αñ╣αñ╛αñé\n1:30\n1 minute, 30 seconds\nαñ¬αñ░ αñ¡αÑÇ αñåαñ¬ αñ½αÑïαñòαñ╕ αñ░αñûαñ┐αñÅαñùαñ╛ αñöαñ░ αñòαñ▓ αñòαÑç αñ«αñ╛αñ░αÑìαñòαÑçαñƒ αñòαÑç αñ¬αÑìαñ░αñ╛αñçαñ╕ αñÅαñòαÑìαñ╢αñ¿ αñ«αÑçαñé αñåαñ¬ αñªαÑçαñûαÑçαñé αññαÑï αñÅαñ½αñÅαñ«αñ╕αÑÇαñ£αÑÇ αñ╕αÑìαñƒαÑëαñòαÑìαñ╕ αñ«αÑçαñé αñåαñ¬αñòαÑï αñ╕αÑìαñƒαÑìαñ░αÑçαñéαñÑ αñ¿αñ£αñ░ αñåαñÅαñùαÑÇαÑñ ITC\n1:38\n1 minute, 38 seconds\nαñ£αñ¼ αñ╕αÑç αñ╕αñ┐αñùαñ░αÑçαñƒ αñ¬αñ░ αñƒαÑêαñòαÑìαñ╕ αñ¼αñóαñ╝αñ╛ αññαñ¼ αñ╕αÑç αñ¼αñ╣αÑüαññ αñ¼αÑüαñ░αñ╛ αñ╣αñ╛αñ▓ αñ╣αÑêαÑñ αñ╕αÑìαñƒαÑëαñò αññαÑï αñ¼αñ┐αñ▓αÑìαñòαÑüαñ▓ αñÜαñ▓αñ¿αÑç αñòαñ╛ αñ¿αñ╛αñ« αñ╣αÑÇ αñ¿αñ╣αÑÇαñé αñ▓αÑç αñ░αñ╣αñ╛ αñ╣αÑêαÑñ αñ▓αÑçαñòαñ┐αñ¿ αñ¬αñ┐αñ¢αñ▓αÑç αññαÑÇαñ¿ αñªαñ┐αñ¿αÑïαñé αñ╕αÑç αñåαñ¬ αñªαÑçαñûαÑçαñé αññαÑï αñ╕αÑìαñƒαÑëαñò αñ«αÑçαñé αñàαñ░αÑìαñ▓αÑÇ\n1:46\n1 minute, 46 seconds\nαñ╕αñ╛αñçαñ¿ αñæαñ½ αñ░αñ┐αñ╡αñ░αÑìαñ╕αñ▓αÑìαñ╕ αñåαñ¬αñòαÑï αñªαÑçαñûαñ¿αÑç αñòαÑï αñ«αñ┐αñ▓ αñ░αñ╣αÑç αñ╣αÑêαñéαÑñ αñÅαñƒαñ▓αÑÇαñ╕αÑìαñƒ αñåαñ¬ αñ»αÑç αñ╕αñ«αñ¥ αñ▓αÑÇαñ£αñ┐αñÅ αñòαñ┐ αñàαñ¼ αñùαñ┐αñ░αñ╛αñ╡αñƒ αññαÑï αñ░αñ┐αñ╡αñ░αÑìαñ╕ αñ╣αÑïαñ¿αÑÇ αñÜαñ╛αñ╣αñ┐αñÅαÑñ αñ¬αñ┐αñ¢αñ▓αÑç αññαÑÇαñ¿ αñªαñ┐αñ¿αÑïαñé αñ╕αÑç αñ▓αñùαñ╛αññαñ╛αñ░ αñçαñ╕ αñ╕αÑìαñƒαÑëαñò αñ«αÑçαñé αñ╣αñ╛αñ»αñ░ αñ╣αñ╛αñêαñ£\n1:55\n1 minute, 55 seconds\nαñöαñ░ αñ╣αñ╛αñ»αñ░ αñ▓αÑïαñ╕ αñªαÑçαñûαñ¿αÑç αñòαÑï αñ«αñ┐αñ▓ αñ░αñ╣αÑç αñ╣αÑêαñéαÑñ αñöαñ░ αñàαñùαñ░ αñåαñ¬ αñçαñ╕αñòαñ╛ αñíαÑçαñ▓αÑÇ αñòαÑêαñéαñíαñ▓αñ╕αÑìαñƒαñ┐αñò αñÜαñ╛αñ░αÑìαñƒ αñªαÑçαñûαÑçαñéαñùαÑç αññαÑï αñ¬αñ┐αñ¢αñ▓αÑç αññαÑÇαñ¿ αñªαñ┐αñ¿αÑïαñé αñ╕αÑç αñåαñ¬ αñÅαñò αñÜαÑÇαñ£ αñæαñ¼αÑìαñ£αñ░αÑìαñ╡ αñòαñ░αñ┐αñÅαñùαñ╛ αñòαñ┐ αñÑαÑïαñíαñ╝αñ╛-αñÑαÑïαñíαñ╝αñ╛ αñùαÑêαñ¬ αñàαñ¬ αñôαñ¬αñ¿αñ┐αñéαñù\n2:03\n2 minutes, 3 seconds\nαñªαÑçαñûαñ¿αÑç αñòαÑï αñ«αñ┐αñ▓ αñ░αñ╣αÑÇ αñ╣αÑêαÑñ αññαÑï αñòαÑîαñ¿ αñÉαñ╕αñ╛ αñ╣αÑê αñ£αñ┐αñ╕αñòαÑï 9:15 αñ¬αñ░ αñ░αÑïαñ£ ITC αñÑαÑïαñíαñ╝αñ╛ αñ╕αñ╛ αñ«αñ╣αñéαñùαñ╛ αñÑαÑïαñíαñ╝αñ╛ αñ╕αñ╛ αñùαÑêαñ¬ αñòαÑç αñ╕αñ╛αñÑ αñûαñ░αÑÇαñªαñ¿αñ╛ αñ╣αÑïαññαñ╛ αñ╣αÑêαÑñ αñ¼αñíαñ╝αñ╛ αñçαñéαñƒαñ░αÑçαñ╕αÑìαñƒαñ┐αñéαñù αñÜαñ╛αñ░αÑìαñƒ αñ╕αÑìαñƒαÑìαñ░αñòαÑìαñÜαñ░ αñ╣αÑêαÑñ αñçαñ╕αñòαÑç αñ▓αñ┐αñÅ αñªαÑéαñ╕αñ░αñ╛ αñ╕αÑìαñƒαÑëαñò αñ╣αÑê ITC αñ£αñ┐αñ╕αÑç αñ░αñûαñ╛ αñ╣αÑê αñçαñ¿αñòαÑìαñ░αÑÇαñ«αÑñ\n2:13\n2 minutes, 13 seconds\nαñàαñÜαÑìαñ¢αñ╛ αñªαÑïαñ¿αÑïαñé αñ¼αñ╣αÑüαññ αñ╕αñ┐αñéαñ¬αñ▓ αñ╕αñ¼αñ╕αÑç αñàαñÜαÑìαñ¢αÑç αñòαÑìαñ»αÑïαñé αññαÑï αñòαñÜαÑìαñÜαñ╛ αññαÑçαñ▓ αñ╣αÑÇ αñÑαñ╛αÑñ αñ╕αÑìαñƒαÑëαñò αñ«αñ╛αñ░αÑìαñòαÑçαñƒ αñ░αñ┐αñÅαñòαÑìαñƒ αñ¿αñ╣αÑÇαñé αñòαñ░ αñ░αñ╣αñ╛ αñ╣αÑê αñòαÑìαñ»αÑïαñéαñòαñ┐ αñáαÑÇαñò αñ╣αÑê αñàαñ¼ αñ½αÑìαñ░αñ╛αñçαñíαÑç\n2:21\n2 minutes, 21 seconds\nαñòαÑÇ αñ¿αÑçαñùαÑïαñ╢αñ┐αñÅαñ╢αñéαñ╕ αñòαÑï αñ╕αÑÇαñ▓ αñòαñ░αñ¿αÑç αñòαñ╛ αñªαñ┐αñ¿ αñ╣αÑê αñ╕αñ╛αñ«αñ¿αÑç αñûαñíαñ╝αñ╛ αñ¬αñ░ αñåαñêαñôαñ╕αÑÇ αñöαñ░ αñÅαñÜαñ¬αÑÇαñ╕αÑÇαñÅαñ▓ αñªαÑïαñ¿αÑïαñé αñòαÑï\n2:28\n2 minutes, 28 seconds\nαñçαñ¿ αñùαÑìαñ░αÑÇαñ¿ αñ▓αÑç αñ£αñ╛ αñ░αñ╣αñ╛ αñ╣αÑéαñé αñàαñ¡αÑÇ αñ¡αÑÇ αñ¬αÑìαñ░αñ╛αñçαñ╕ αñ╣ αñòαñ░αñ¿αÑç αñòαÑç αñ¼αñ╛αñª αñ▓αÑëαñ╕αÑçαñ╕ αñÑαÑç αñ«αÑêαñ╕αñ┐αñ╡αñ▓αÑÇ αñ▓αÑëαñ╕αÑçαñ╕ αñ░αñ┐αñíαÑìαñ»αÑéαñ╕ αñ╣αÑïαñéαñùαÑç αñàαñùαñ░ αñòαÑìαñ░αÑéαñí αñ╡αñ╛αñòαñê αñ¼αñ╣αÑüαññ αñòαÑéαñ▓ αñæαñ½\n2:36\n2 minutes, 36 seconds\nαñ╣αÑï αñ░αñ╣αñ╛ αñ╣αÑê αñöαñ░ αñÅαñò αñ¼αñ╛αñ░ αñ¬αñéαñ¬ αñ¬αÑìαñ░αñ╛αñçαñ╕ αñ¼αñóαñ╝ αñùαñÅ αñ╣αÑêαñé αññαÑï αñ«αÑüαñ¥αÑç αñ▓αñùαññαñ╛ αñ¿αñ╣αÑÇαñé αñ╣αÑê αñ╡αÑï αñ░αÑïαñ▓ αñ¼αÑêαñò αñàαñ¼ αñ╣αÑïαñ¿αÑç αñ╡αñ╛αñ▓αÑç αñ╣αÑêαñéαÑñ αññαÑï αñåαñ¬ αñçαñ¿αñùαñ░αÑÇ αñ▓αÑçαñòαÑç αñ░αñûαñ┐αñÅ αñçαñ¿\n2:43\n2 minutes, 43 seconds\nαñªαÑïαñ¿αÑïαñé αñòαÑïαÑñ αñ¿αñ╣αÑÇαñé αñ╣αÑï αñùαñÅ αñªαÑïαñ¿αÑïαñéαÑñ αñàαñùαñ▓αÑç αñªαÑï αñ¼αñ╣αÑüαññ αñ£αñ▓αÑìαñªαÑÇ αñ¼αññαñ╛ αñªαñ┐αñ»αñ╛αÑñ\n2:48\n2 minutes, 48 seconds\nαñ╡αÑï αñªαÑïαñ¿αÑïαñé αñ½αÑÇαñ▓ αñùαÑüαñí αñ½αÑêαñòαÑìαñƒαñ░ αñ╡αñ╛αñ▓αÑç αñ¼αñóαñ╝ [αñ╣αñéαñ╕αÑÇ] αñùαñÅαÑñ\n2:50\n2 minutes, 50 seconds\nαñ«αñ£αñùαñ╛αñéαñ╡ αñíαÑëαñù αñòαÑç αñàαñùαñ▓αñ╛ αñ╕αÑìαñƒαÑëαñò αñ«αÑçαñ░αÑÇ αñ▓αñ┐αñ╕αÑìαñƒ αñ«αÑçαñé αñöαñ░ αñíαñ┐αñ½αÑçαñéαñ╕ αñ╕αÑìαñ¬αÑçαñ╕ αñòαÑç αñ╕αÑìαñƒαÑëαñòαÑìαñ╕ αñòαÑÇ αñÜαñ░αÑìαñÜαñ╛ αñ╣αñ« αñ▓αñùαñ╛αññαñ╛αñ░ αñòαñ░αññαÑç αñ£αñ╛ αñ░αñ╣αÑç αñ╣αÑêαñéαÑñ αñòαñ▓ αñåαñ¬αñòαÑç αñ╕αñ╛αñÑ αñ¼αÑÇαñíαÑÇαñÅαñ▓ αñ╢αÑçαñ»αñ░ αñòαñ┐αñ»αñ╛ αñÑαñ╛αÑñ αññαÑï 2.5% αñòαÑÇ αññαÑçαñ£αÑÇ\n2:59\n2 minutes, 59 seconds\nαñ╡αñ╣αñ╛αñé αñ¬αñ░ αñªαÑçαñûαñ¿αÑç αñòαÑï αñ«αñ┐αñ▓αÑÇαÑñ αñ«αñ£αñùαñ╛αñéαñ╡ αñíαÑëαñò αñ╣αñ╛αñê αñ╕αÑç αñ¼αñíαñ╝αñ╛ αñ╕αñ┐αñùαÑìαñ¿αñ┐αñ½αñ┐αñòαÑçαñéαñƒαñ▓αÑÇ αñƒαÑéαñƒαñ╛ αñ╣αÑüαñå αñ╕αÑìαñƒαÑëαñò αñ╣αÑêαÑñ\n3:04\n3 minutes, 4 seconds\n35% αñàαñ¬αñ¿αÑç αñæαñ▓ αñƒαñ╛αñçαñ« αñ╣αñ╛αñê αñ╕αÑç αñ¿αÑÇαñÜαÑç αñƒαÑìαñ░αÑçαñí αñòαñ░ αñ░αñ╣αñ╛ αñ╣αÑêαÑñ αñòαñ▓ αñÅαñò% αñòαÑÇ αññαÑçαñ£αÑÇ αñªαÑçαñûαñ¿αÑç αñòαÑï αñ«αñ┐αñ▓αÑÇ αñ▓αÑçαñòαñ┐αñ¿ αñçαñ╕αñòαñ╛ αñÜαñ╛αñ░αÑìαñƒ αñòαñ╛ αñ╕αÑìαñƒαÑìαñ░αñòαÑìαñÜαñ░ αñ¼αÑ¥αñ┐αñ»αñ╛ αñ╣αÑêαÑñ\n3:10\n3 minutes, 10 seconds\nαñàαñ¼ αñûαñ╛αñ╕ αñ¼αñ╛αññ αñ╣αÑê αñòαñ┐ αñçαñ╕αñ¿αÑç αñÅαñò αñíαñ╛αñëαñ¿αñ╡αñ░αÑìαñí αñ╕αÑìαñ▓αÑïαñ¬αñ┐αñéαñù αñƒαÑìαñ░αÑçαñéαñí αñ▓αñ╛αñçαñ¿ αñòαÑç αñèαñ¬αñ░ αñ¼αÑìαñ░αÑçαñòαñåαñëαñƒ αñªαñ┐αñ»αñ╛ αñÑαñ╛ αñöαñ░ αñëαñ╕αñòαÑç αñ¼αñ╛αñª αñÅαñò αñ¢αÑïαñƒαñ╛ αñ╕αñ╛ αñòαñéαñ╕αÑïαñ▓αñ┐αñíαÑçαñ╢αñ¿ αñòαñ╛ αñ½αÑ¢ αñ╣αÑêαÑñ αñçαñ╕ αñƒαÑìαñ░αÑçαñéαñí αñ▓αñ╛αñçαñ¿ αñòαÑç\n3:17\n3 minutes, 17 seconds\nαñèαñ¬αñ░ αñ╣αÑÇ αñ¼αñ¿αñ╛ αñ╣αÑüαñå αñ╣αÑêαÑñ αñöαñ░ αñ£αñ¼ αññαñò αñçαñ╕αñòαÑï αñ»αÑç αñ░αñ┐αñ╕αÑìαñ¬αÑçαñòαÑìαñƒ αñòαñ░ αñ░αñ╣αñ╛ αñ╣αÑê αñƒαÑìαñ░αÑçαñéαñí αñ¼αÑ¥αñ┐αñ»αñ╛ αñ╣αÑÇ αñ╣αÑêαÑñ αññαÑï Mαñ£g αñçαñ╕ αñ╕αÑìαñƒαÑëαñò αñòαÑï αñçαñ¿ αñùαÑìαñ░αÑÇαñ¿ αñ▓αÑçαñòαÑç αñÜαñ▓αÑçαñéαñùαÑçαÑñ\n3:24\n3 minutes, 24 seconds\nαñ¼αñ╛αñòαÑÇ Bank Finance αñ╕αñ¼αñ╕αÑç αñ£αÑìαñ»αñ╛αñªαñ╛ αññαÑçαñ£αÑÇ αñöαñ░ αñòαñéαñ½αñ░αÑìαñƒ αñ»αñ╣αÑÇαñé αñ¬αñ░ αñå αñ░αñ╣αñ╛ αñ╣αÑêαÑñ αñ«αñ╛αñ░αÑìαñòαÑçαñƒ αñ£αñ¡αÑÇ αñ¡αÑÇ αñÜαñ▓ αñ░αñ╣αñ╛ αñ╣αÑê αññαñ¼ αñçαñ¿ αñ╕αÑìαñƒαÑëαñòαÑìαñ╕ αñ«αÑçαñé αñåαñ¬αñòαÑï αñªαÑçαñûαñ¿αÑç αñòαÑï αñ«αñ┐αñ▓αÑçαñùαñ╛ αñòαñ┐ αñåαñëαñƒαñ¬αñ░αñ½αÑëαñ░αÑìαñ«αÑçαñéαñ╕ αñ╣αÑêαÑñ αñÅαñò αñ╣αñ╛αñ▓ αñ╣αÑÇ αñòαÑÇ αñ▓αñ┐αñ╕αÑìαñƒαñ┐αñéαñù αñ╣αÑê i Finance αñÅαñê FinanceαÑñ\n3:36\n3 minutes, 36 seconds\nαñ»αñ╣αñ╛αñé αñ¬αñ░ αñåαñ¬ αñ¿αñ£αñ░ αñ░αñûαñ┐αñÅαñùαñ╛αÑñ αñòαñ▓ αñòαÑç αñ╕αññαÑìαñ░ αñ«αÑçαñé αñæαñ▓ αñƒαñ╛αñçαñ« αñ╣αñ╛αñê αñ¼αÑìαñ░αÑçαñòαñåαñëαñƒ αñ╣αÑï αñöαñ░ αñ»αÑç αñ¼αñ╣αÑüαññ αñ╕αñ╛αñ░αÑÇ αñåαñêαñ¬αÑÇαñôαñ╕ αñ░αñ┐αñ╕αÑçαñéαñƒαñ▓αÑÇ αñåαñÅ αñ╣αÑêαñé αñ£αÑï αñæαñ½ αñª αñ░αÑçαñíαñ╛αñ░\n3:43\n3 minutes, 43 seconds\nαñòαÑìαñ»αñ╛ αñ▓αñùαñ╛αññαñ╛αñ░ αñ¼αñóαñ╝αññαÑç αñ£αñ╛ αñ░αñ╣αÑç αñ╣αÑêαñéαÑñ αñùαñ£αñ¼ αñòαÑÇ αññαÑçαñ£αÑÇ αñ»αñ╣αñ╛αñé αñ¬αñ░ αñåαñ¬αñòαÑï αñªαÑçαñûαñ¿αÑç αñòαÑï αñ«αñ┐αñ▓ αñ░αñ╣αÑÇ αñ╣αÑêαÑñ\n3:48\n3 minutes, 48 seconds\nαñíαÑçαñ▓αÑÇ αñÜαñ╛αñ░αÑìαñƒαÑìαñ╕ αñ¬αñ░ αñòαñ▓ 6% αñòαÑÇ αññαÑçαñ£αÑÇ αñòαÑç αñ╕αñ╛αñÑ αñæαñ▓ αñƒαñ╛αñçαñ« αñ╣αñ╛αñê αñòαñ╛ αñ¼αÑìαñ░αÑçαñòαñåαñëαñƒ αñ╣αÑï αñùαñ»αñ╛αÑñ αñ¬αÑëαñ£αñ┐αñƒαñ┐αñ╡ αñ¬αÑìαñ░αñ╛αñçαñ╕ αñ╡αÑëαñ▓αÑìαñ»αÑéαñ« αñÅαñòαÑìαñ╢αñ¿ αñ¬αñ┐αñ¢αñ▓αÑç αññαÑÇαñ¿ αñªαñ┐αñ¿αÑïαñé αñ╕αÑç αñªαÑçαñûαñ¿αÑç αñòαÑï αñ«αñ┐αñ▓ αñ░αñ╣αÑç αñ╣αÑêαñé αñöαñ░ αñ╕αñ╛αñÑ αñ«αÑçαñé αñ¬αÑìαñ░αñ╛αñçαñ╕\n3:56\n3 minutes, 56 seconds\nαñƒαÑé αñ¼αÑüαñò αñòαÑç αñ▓αñ┐αñ╣αñ╛αñ£ αñ╕αÑç αñªαÑçαñûαÑçαñé αññαÑï αñ«αÑêαñé αñƒαÑÇαñÅαñ« αñåαñºαñ╛αñ░ αñ¬αñ░ αñ¼αññαñ╛ αñ░αñ╣αñ╛ αñ╣αÑéαñé αñåαñ¬αñòαÑïαÑñ αñæαñ▓αñ«αÑïαñ╕αÑìαñƒ αñ╕αñ┐αñ░αÑìαñ½ 1.6 αñƒαñ╛αñçαñ«αÑìαñ╕ αñ¬αñ░ αñÜαñ▓ αñ░αñ╣αñ╛ αñ╣αÑêαÑñ αññαÑï αñòαñéαñ½αñ░αÑìαñƒ αñçαñ╡αÑêαñ▓αÑìαñ»αÑéαñÅαñ╢αñ¿ αñòαñ╛ αñ¡αÑÇ i finance αñçαñ╕ αñ╕αÑìαñƒαÑëαñò αñòαÑï\n4:04\n4 minutes, 4 seconds\nαñ░αñûαñ╛ αñ╣αÑê αñçαñ¿αñòαÑìαñ░αÑÇαÑñ αñ╣αñ« αñªαÑï αñ╣αÑêαñéαÑñ αñÅαñò αññαÑï αñ«αÑêαñéαñ¿αÑç αñòαñ╣αñ╛ αñÑαñ╛ αñ£αÑÇαñåαñêαñ╕αÑÇ αñòαÑï αñ░αñ┐αñ╡αñ£αñ┐αñƒ αñòαñ░αÑçαñéαñùαÑç αñòαñ▓ αñ╕αÑüαñ¼αñ╣ αññαÑï αñåαñ£ αñ╕αÑüαñ¼αñ╣ αñ░αñ┐αñ╡αñ£αñ┐αñƒ αñòαñ░αñ¿αÑç αñòαñ╛ αñªαñ┐αñ¿αÑñ αñ«αÑêαñé αñ░αñû αññαÑï\n4:13\n4 minutes, 13 seconds\nαñ▓αñ╛αñ▓ αñ░αñ╣αñ╛ αñ╣αÑéαñéαÑñ αñ╣αñ╛αñ▓αñ╛αñéαñòαñ┐ αñòαñ▓ αñæαñ▓αñ░αÑçαñíαÑÇ αñ¼αñ╣αÑüαññ αñ¬αÑìαñ░αÑçαñ╢αñ░ αñ«αÑçαñé αñÑαñ╛αÑñ αñòαÑìαñ»αÑïαñé αñ▓αñ╛αñ▓ αñòαñ╛ αñ▓αÑëαñ£αñ┐αñò αñ╣αÑê αñ¡αñ╛αñê? αñòαñ╣αñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ αñæαñ½αñ░ αñ╕αñ╛αñçαñ£ 3.5 αñòαñ░αÑïαñíαñ╝\n4:20\n4 minutes, 20 seconds\nαñ╢αÑçαñ»αñ░αÑïαñé αñòαñ╛ αñÑαñ╛αÑñ αñ¼αñíαÑìαñ╕ αñåαñê αñ¬αÑîαñ¿αÑç αñòαñ░αÑïαñíαñ╝ αñ╢αÑçαñ»αñ░αÑìαñ╕ αñòαÑÇ αññαÑï 3.5 αñ╕αñ╡αñ╛5 αñùαÑüαñ¿αñ╛ αñ¡αñ░ αñùαñ»αñ╛αÑñ αñ¬αñ░ αñåαñ¬αñ¿αÑç\n4:28\n4 minutes, 28 seconds\nαñùαÑìαñ░αÑÇαñ¿ αñ╢αÑé αñ¡αÑÇ αññαÑï αñçαñ╕αÑìαññαÑçαñ«αñ╛αñ▓ αñòαñ░αñ¿αñ╛ αñ╣αÑêαÑñ αñëαñ╕αñòαÑï αñªαÑçαñûαÑçαñéαñùαÑç αññαÑï αñ╕αñ┐αñ░αÑìαñ½ 1.3 αñƒαñ╛αñçαñ«αÑìαñ╕ αñ¡αñ░αñ╛ αñÑαñ╛αÑñ αñöαñ░\n4:35\n4 minutes, 35 seconds\nαñòαÑìαñ»αñ╛ αñ╣αÑüαñå? αñ½αÑìαñ▓αÑïαñ░ αñ¬αÑìαñ░αñ╛αñçαñ╕ αñÑαÑÇ 352 αñòαÑÇαÑñ 352.2 αñòαÑìαñ▓αñ┐αñ»αñ░αñ┐αñéαñù αñ¬αÑìαñ░αñ╛αñçαñ╕ αñ╣αÑêαÑñ αñ»αÑç αñ╕αÑìαñƒαÑëαñò αñòαñ▓ αñòαÑç\n4:43\n4 minutes, 43 seconds\nαñòαñ░αÑçαñòαÑìαñ╢αñ¿ αñòαÑç αñ¼αñ╛αñ╡αñ£αÑéαñª 358 359 αñ¬αÑçαÑñ αñòαÑïαñê αñíαñ┐αñ«αñ╛αñéαñí αñ¼αñ╣αÑüαññ αñûαñ╛αñ╕ αñ¿αñ╣αÑÇαñé αñÑαÑÇαÑñ αñºαÑìαñ»αñ╛αñ¿ αñ░αñûαñ┐αñÅαñùαñ╛αÑñ αñöαñ░ αñ£αÑÇαñåαñêαñ╕αÑÇ αñ╕αñ┐αñ░αÑìαñ½ αñªαñ╛αñ»αñ░αÑç αñ«αÑçαñé αñ╣αÑÇ αñòαñ╛αñ«αñòαñ╛αñ£ αñòαñ░αñ¿αÑç\n4:52\n4 minutes, 52 seconds\nαñ╡αñ╛αñ▓αñ╛ αñ▓αñéαñ¼αÑç αñàαñ░αñ╕αÑç αñ╕αÑç αñ╕αÑìαñƒαÑëαñò αñ╣αÑêαÑñ αñ▓αñ╛αñ▓ αñ░αñû αñ░αñ╣αñ╛ αñ╣αÑéαñéαÑñ αñ¼αñ╛αñòαÑÇ αññαÑï αñûαÑêαñ░ αñªαÑçαñûαÑçαñéαñùαÑç αñªαñ┐αñ¿ αñòαÑç αñªαÑîαñ░αñ╛αñ¿αÑñ\n4:56\n4 minutes, 56 seconds\nDoms Industries αñ▓αñ╛αñ╕αÑìαñƒ αñƒαÑìαñ░αÑçαñí αñ╣αÑï αñ╕αñòαññαñ╛ αñ╣αÑê αñ£αñ┐αñ╕αñ«αÑçαñé αñòαñ╣αñ╛ αñ£αñ╛ αñ░αñ╣αñ╛ αñ╣αÑê αñ½αÑÇαñ▓αñ╛ 7% αññαñò αñ╣αñ┐αñ╕αÑìαñ╕αÑçαñªαñ╛αñ░αÑÇ αñ¼αÑçαñÜαñ¿αÑç αñòαÑÇ αññαÑêαñ»αñ╛αñ░αÑÇ αñòαñ░αÑÇ αññαÑï αñ¼αñíαñ╝αñ╛\n5:04\n5 minutes, 4 seconds\nαñÜαñéαñù αññαñòαñ░αÑÇαñ¼αñ¿ Γé╣9000 αñòαñ╛ αñå αñ░αñ╣αñ╛ αñ╣αÑïαñùαñ╛ αñöαñ░ αñ╢αñ╛αñ»αñª αñòαñ▓ αñòαÑÇ αñòαÑìαñ▓αÑïαñ£ αñ╕αÑç 9% αñíαñ┐αñ╕αÑìαñòαñ╛αñëαñéαñƒ αñ¬αÑìαñ▓αñ╕ αñ½αÑìαñ▓αÑïαñ░ αñ¬αÑìαñ░αñ╛αñçαñ╕ αñ░αñûαÑÇ αñùαñê αñ╣αÑêαÑñ αñ»αÑç αñ«αññαñ▓αñ¼ αñ╢αñ╛αñ»αñª αñçαñ¿αñòαÑï αñçαñ╕\n5:12\n5 minutes, 12 seconds\nαñ¼αñ╛αññ αñòαñ╛ αñòαÑëαñ¿αÑìαñ½αñ┐αñíαÑçαñéαñ╕ αñ╣αÑê αñòαñ┐ αñ¼αÑìαñ▓αÑëαñò αñíαÑÇαñ▓ αñ¿αñ╣αÑÇαñé αñ╣αÑïαñùαÑÇαÑñ αñòαñéαñƒαñ┐αñ¿αÑìαñ»αÑéαñàαñ╕ αñ╕αÑçαñ╢αñ¿ αñ«αÑçαñé αñ╣αÑï αñ░αñ╣αñ╛ αñ╣αÑïαñùαñ╛ αññαÑï αñ╢αñ╛αñ»αñª αñªαñ┐αñòαÑìαñòαññ αñåαñÅαñùαÑÇ αñ╕αÑìαñƒαÑëαñò αñòαÑç αñ▓αñ┐αñÅαÑñ αñàαñùαñ▓αÑç αñàαñùαñ▓αÑç αñªαÑï αñ╕αÑìαñƒαÑëαñòαÑìαñ╕ αñ«αÑçαñé αñòαñ░αÑìαñ¿αñ╛αñƒαñò αñ¼αÑêαñéαñò αñ»αñ╣αñ╛αñé αñ¬αñ░ αñåαñ¬\n5:21\n5 minutes, 21 seconds\nαñ½αÑïαñòαñ╕ αñ░αñûαñ┐αñÅαñùαñ╛αÑñ αñÅαñò αñåαñê αñ½αñ╛αñçαñ¿αÑçαñéαñ╕ αñòαÑÇ αñ¼αñ╛αññ αñ╣αñ«αñ¿αÑç αñòαÑÇαÑñ αñòαñ┐ αñÅαñò αñòαñ░αÑìαñ¿αñ╛αñƒαñò αñ¼αÑêαñéαñò αñÉαñ╕αñ╛ αñ╣αÑê αñ£αñ┐αñ╕αñ«αÑçαñé αñåαñ¬ αñªαÑçαñûαÑçαñé αññαÑï αñÅαñò αñ«αñ▓αÑìαñƒαÑÇ αñ¼αÑìαñ░αÑçαñòαñåαñëαñƒ αñƒαÑçαñ╕αÑìαñƒ αñ╣αÑïαñ¿αÑç αñ╡αñ╛αñ▓αñ╛ αñ╣αÑêαÑñ αñ╕αÑìαñƒαÑëαñò αñ«αÑçαñé αñ▓αñùαñ╛αññαñ╛αñ░ αññαÑçαñ£αÑÇ αñªαÑçαñûαñ¿αÑç αñòαÑï αñ«αñ┐αñ▓ αñ░αñ╣αÑÇ αñ╣αÑêαÑñ αñåαñëαñƒαñ¬αñ░αñ½αÑëαñ░αÑìαñ«αñ┐αñéαñù αñ╕αÑìαñƒαÑëαñò αñ╣αÑêαÑñ\n5:31\n5 minutes, 31 seconds\nαñ£αÑìαñ»αñ╛αñªαñ╛ αñÜαñ░αÑìαñÜαñ╛ αñ¿αñ╣αÑÇαñé αñ╣αÑïαññαÑÇ αñ▓αÑçαñòαñ┐αñ¿ αñòαÑìαñ»αñ╛ αñ¼αñíαñ╝αÑç αñ«αÑéαñ╡αÑìαñ╕ αñåαñ¬αñòαÑï αñªαÑçαñûαñ¿αÑç αñòαÑï αñ«αñ┐αñ▓αÑçαÑñ αñåαñ¬ αñçαñ╕αñòαÑç αñ¬αñ┐αñ¢αñ▓αÑç αñÅαñò αñ╕αñ╛αñ▓ αñòαñ╛ αñÜαñ╛αñ░αÑìαñƒ αñÅαñò αñ¼αñ╛αñ░ αñªαÑçαñûαñ┐αñÅ αññαÑï αñ╕αñ╣αÑÇαÑñ αñàαñ¼ αñ╕αÑìαñƒαÑëαñò αñ«αÑçαñé αñûαñ╛αñ╕ αñ¼αñ╛αññ αñ»αÑç αñ╣αÑê αñòαñ┐ αñàαñ¼ αñ£αñ┐αñ¿ αñ╕αÑìαññαñ░\n5:40\n5 minutes, 40 seconds\nαñèαñ¬αñ░ αñ»αÑç αñ╕αÑìαñƒαÑëαñò αñòαñ╛αñ░αÑïαñ¼αñ╛αñ░ αñòαñ░ αñ░αñ╣αñ╛ αñ╣αÑêαÑñ αñ»αÑç αñ£αÑêαñ¿ 2024 αñòαÑç αñ£αÑï αñ╣αñ╛αñêαÑ¢ αñ╣αÑêαñé, αñçαñ╕αñòαÑï αñªαÑïαñ¼αñ╛αñ░αñ╛ αñ╕αÑç αñ░αÑÇαñ┐αñƒαÑçαñ╕αÑìαñƒ αñòαñ░αñ¿αÑç αñòαÑÇ αññαÑêαñ»αñ╛αñ░αÑÇ αñ«αÑçαñé αñ╣αÑêαÑñ αñÜαñ╛αñ░αÑìαñƒαÑìαñ╕ αñåαñ¬ αñªαÑçαñûαÑçαñéαñùαÑç αññαÑï αñåαñ¬αñòαÑï αñ╕αñ«αñ¥ αñ«αÑçαñé αñå αñ£αñ╛αñÅαñùαñ╛αÑñ\n5:49\n5 minutes, 49 seconds\nαñÑαÑïαñíαñ╝αÑÇ αñ╕αÑÇ αñ▓αñéαñ¼αÑÇ αñàαñ╡αñºαñ┐ αñòαÑç αñÜαñ╛αñ░αÑìαñƒ αÑ¢αÑéαñ« αñåαñëαñƒ αñòαñ░αñòαÑç αñªαÑçαñûαñ¿αÑç αñ¬αñíαñ╝αÑçαñéαñùαÑçαÑñ αñ▓αÑçαñòαñ┐αñ¿ αñ╕αÑìαñƒαÑìαñ░αñòαÑìαñÜαñ░ αñ¼αñ╣αÑüαññ αñ¼αñóαñ╝αñ┐αñ»αñ╛ αñ╣αÑêαÑñ αñàαñ¬ αñƒαÑìαñ░αÑçαñéαñí αñ¼αñóαñ╝αñ┐αñ»αñ╛ αñ╣αÑêαÑñ αñ«αñ╛αñ░αÑìαñòαÑçαñƒ αñòαÑï αñ¬αñ╕αñéαñª αñå αñ░αñ╣αÑç αñ╣αÑêαñéαÑñ αñ¼αÑêαñéαñòαÑìαñ╕ αñöαñ░ αñ½αñ╛αñçαñ¿αñ╢αñ┐αñ»αñ▓αÑìαñ╕ αñçαñ╕αñòαÑç αñ▓αñ┐αñÅ αñòαñ░αÑìαñ¿αñ╛αñƒαñò αñ¼αÑêαñéαñò αñçαñ╕ αñ╕αÑìαñƒαÑëαñò αñòαÑï αñÅαñ¿αñùαÑìαñ░αÑÇαñ¿ αñ░αñûαñ╛ αñ╣αÑêαÑñ αñàαñùαñ▓αñ╛ αñ╕αÑìαñƒαÑëαñò αñ╣αÑê tαñ╛αñçαñƒαñ¿αÑñ\n6:00\n6 minutes\nαñ»αñ╣αñ╛αñé αñ¬αñ░ αñåαñ¬ αñ½αÑïαñòαñ╕ αñ░αñûαñ┐αñÅαñùαñ╛ αñöαñ░ αñ£αñ¼ αñ╕αÑç αñåαñ¬ αñªαÑçαñûαÑçαñé αññαÑï αñ»αñ╣αñ╛αñé αñ¬αñ░ αñ¬αÑìαñ░αñºαñ╛αñ¿αñ«αñéαññαÑìαñ░αÑÇ αñ¿αñ░αÑçαñéαñªαÑìαñ░ αñ«αÑïαñªαÑÇ αñòαÑÇ αñÅαñò αñàαñ¬αÑÇαñ▓ αñªαÑçαñûαñ¿αÑç αñòαÑï αñ«αñ┐αñ▓αÑÇ αñÑαÑÇ αñòαñ┐ αñ╕αÑïαñ¿αñ╛ αñòαñ« αñûαñ░αÑÇαñªαÑçαñé αñçαñ╕ αñ╕αñ╛αñ▓ αñëαñ╕αñòαÑç αñ¼αñ╛αñª αñ╕αÑç αñÑαÑïαñíαñ╝αÑÇ αñ¼αñ╣αÑüαññ αñùαñ┐αñ░αñ╛αñ╡αñƒ αñåαñêαÑñ αñ▓αÑçαñòαñ┐αñ¿ αñòαÑìαñ»αñ╛ αñ▓αñ╛αñçαñòαñ▓αÑÇ αñ░αñ┐αñ╡αñ░αÑìαñ╕αñ▓ αñ╣αÑêαÑñ\n6:12\n6 minutes, 12 seconds\nαñ£αÑêαñ╕αÑç αñòαñ┐ LNT αñòαÑç αñòαÑçαñ╕ αñ«αÑçαñé αñ╣αñ« αñ╕αñ«αñ¥ αñ░αñ╣αÑç αñÑαÑç αñòαñ┐ αñ£αñ╣αñ╛αñé αñ½αñéαñíαñ╛αñ«αÑçαñéαñƒαñ▓αÑìαñ╕ αñ¼αñ╣αÑüαññ αñ╕αÑìαñƒαÑìαñ░αñ╛αñéαñù αñ╣αÑïαññαÑç αñ╣αÑêαñé αñ¿αñ╛ αñûαñ░αñ╛αñ¼ αñûαñ¼αñ░αÑïαñé αñòαÑç αñ¼αñ╛αñª αñ░αñ┐αñòαñ╡αñ░αÑÇ αñòαñ╛ αñƒαÑìαñ░αÑçαñéαñí αñ¡αÑÇ αñåαñ¬αñòαÑï αñ¼αñ╣αÑüαññ αñ¼αñóαñ╝αñ┐αñ»αñ╛ αñªαÑçαñûαñ¿αÑç αñòαÑï αñ«αñ┐αñ▓αññαñ╛ αñ╣αÑêαÑñ\n6:20\n6 minutes, 20 seconds\nTitan αñòαñ╛αñ½αÑÇ αñàαñÜαÑìαñ¢αÑÇ αñ░αñ┐αñòαñ╡αñ░αÑÇ αñ»αñ╣αñ╛αñé αñ¬αñ░ αñªαÑçαñûαñ¿αÑç αñòαÑï αñ«αñ┐αñ▓ αñ░αñ╣αÑÇ αñ╣αÑê αñöαñ░ αñ»αÑç αññαÑï αñ╕αÑìαñƒαÑëαñò αñÉαñ╕αñ╛ αñ╣αÑê αñòαñ┐ αñàαñ¬αñ¿αÑç αñæαñ▓ αñƒαñ╛αñçαñ« αñ╣αñ╛αñê αñ╕αÑç αñ£αÑìαñ»αñ╛αñªαñ╛ αñªαÑéαñ░ αñ¿αñ╣αÑÇαñé αñ╣αÑêαÑñ αñòαñ▓ 1αÑ¥ αñòαÑÇ αññαÑçαñ£αÑÇ αñ»αñ╣αñ╛αñé αñ¬αñ░ αñªαÑçαñûαñ¿αÑç αñòαÑï αñ«αñ┐αñ▓αÑÇ αñÑαÑÇαÑñ\n6:28\n6 minutes, 28 seconds\nαñƒαÑçαñòαÑìαñ¿αñ┐αñòαñ▓ αñ£αÑï αñ╕αÑìαñƒαÑìαñ░αÑçαñéαñÑ αñ╣αÑê αñ¼αñ╣αÑüαññ αñ¼αñóαñ╝αñ┐αñ»αñ╛ αñ╣αÑê αñöαñ░ αñòαñ▓ αñ£αñ¼ αñ«αÑêαñé αñÜαñ╛αñ░ αñ╕αÑìαñòαÑêαñ¿ αñòαñ░ αñ░αñ╣αñ╛ αñÑαñ╛ αññαñ¼ αñ¬αññαñ╛ αñÜαñ▓αñ╛ αñòαñ┐ αñ¿αñ╛ αñòαñ┐ αñ╕αñ┐αñ░αÑìαñ½ Titan αñ¼αñ╛αñòαÑÇ αñòαÑç αñ¡αÑÇ αñ¢αÑïαñƒαÑç αñ£αÑìαñ╡αÑçαñ▓αñ░αÑÇ αñ╕αÑìαñƒαÑëαñòαÑìαñ╕ αñ╣αÑêαñé αñ¿αñ╛ αñçαñ¿αñ«αÑçαñé αñ¬αñ┐αñ¢αñ▓αÑç αñªαÑï\n6:36\n6 minutes, 36 seconds\nαñªαñ┐αñ¿αÑïαñé αñ╕αÑç αñ▓αñùαñ╛αññαñ╛αñ░ αñûαñ░αÑÇαñªαñ╛αñ░αÑÇ αñªαÑçαñûαñ¿αÑç αñòαÑï αñ«αñ┐αñ▓ αñ░αñ╣αÑÇ αñ╣αÑêαÑñ αñòαÑüαñ¢ αñ¿αñ╛ αñòαÑüαñ¢ αñ¼αñ╣αÑüαññ αñ¼αñóαñ╝αñ┐αñ»αñ╛ αñ╣αÑï αñ░αñ╣αñ╛ αñ╣αÑêαÑñ αññαÑï αñªαñ┐αñùαÑìαñùαñ£ αñòαÑç αñ╕αñ╛αñÑ αñ£αñ╛αñÅαñéαñùαÑç Titan αñçαñ╕ αñ╕αÑìαñƒαÑëαñò αñòαÑï αñçαñ¿αñòαÑìαñ░αÑÇαñ¿ αñ░αñûαñ╛ αñ╣αÑêαÑñ αñòαñ▓ αñÅαñò αñ╕αÑìαñƒαÑëαñò αñÑαñ╛ αñòαÑêαñ╢ αñ«αÑçαñé\n6:46\n6 minutes, 46 seconds\nαñ£αÑï αñùαñ£αñ¼ αñòαñ░αñ╛ αñ╣αÑüαñå αñÑαñ╛ αñªαñ┐αñ¿ αñ¡αñ░ αñ╡αÑï αñÑαñ╛ Sonata αñ╕αÑëαñ½αÑìαñƒαñ╡αÑçαñ»αñ░αÑñ αñ╡αÑëαñ▓αÑìαñ»αÑéαñ« αñëαñ╕αñòαÑç αñ╕αñ╛αñÑ αñ¡αñ╛αñùαñ╛ αñÑαñ╛αÑñ\n6:51\n6 minutes, 51 seconds\nαñàαñ¬αñíαÑçαñƒ αñå αñùαñ»αñ╛αÑñ αñ»αÑéαñòαÑç αñòαÑç αñ¬αÑïαñ▓αÑüαñ¿αñ┐αñ¿ αñçαñ«αñ░αÑìαñ£αñ┐αñéαñù αñ«αñ╛αñ░αÑìαñòαÑçαñƒ αñ╕αÑìαñ«αñ╛αñ▓ αñòαÑêαñ¬ αñ½αñéαñí αñ¿αÑç αñòαñ▓ 1921000\n6:59\n6 minutes, 59 seconds\nαñ╢αÑçαñ»αñ░αÑìαñ╕ αñûαñ░αÑÇαñªαÑçαÑñ αñæαñ▓αñ░αÑçαñíαÑÇ αñ¼αñ╣αÑüαññ αñÜαñ▓αñ╛ αñ╣αÑüαñå αñ╣αÑê αñ¬αñ░ αñ«αñ╛αñ░αÑìαñò αñòαñ░αñ¿αñ╛ αñ£αñ░αÑéαñ░αÑÇ αñÑαñ╛ αñçαñ╕αñ▓αñ┐αñÅ αñƒαÑÇαñ« αñ«αÑçαñé αñùαÑìαñ░αÑÇαñ¿ αñòαÑç αñ╕αñ╛αñÑ αñ╣αÑÇ αñ╣αÑêαÑñ αñàαñéαñíαñ░ αñ¬αñ░αñ½αÑëαñ░αÑìαñ«αñ┐αñéαñù αñ╕αÑìαñƒαÑëαñò αññαÑï\n7:07\n7 minutes, 7 seconds\nαñÑαñ╛ αñ╣αÑÇ αñÑαñ╛αÑñ αñ¼αÑìαñ░αñ┐αñùαÑçαñí αñÅαñéαñƒαñ░αñ¬αÑìαñ░αñ╛αñçαñ£αÑçαñ╕ αñåαñ£ αñÅαñíαñ£αñ╕αÑìαñƒαñ«αÑçαñéαñƒ αñ╣αÑï αñ░αñ╣αñ╛ αñ╣αÑïαñùαñ╛ αñ░αñ┐αñ»αñ▓αñ╕αÑìαñƒαÑçαñƒ αñ╕αÑìαñ╡αÑÇαñƒ αñ╕αÑìαñ¬αÑëαñƒ αñ«αÑçαñéαÑñ αñ╣αñ╛αñé αñÅαñò αñ¿αÑêαñ░αÑçαñƒαñ┐αñ╡ αñ»αÑç αñ£αñ░αÑéαñ░ αñ╣αÑê αñòαñ┐ αñ¬αñ╛αñ¿αÑÇ αñ╡αñ╛αñ¿αÑÇ αñ¼αÑÇαñÅαñÅαñ«αñ╕αÑÇ αñ╕αñ¬αÑìαñ▓αñ╛αñê αñ¿αñ╣αÑÇαñé αññαÑï αñëαñ╕αñòαñ╛\n7:15\n7 minutes, 15 seconds\nαñçαñ╢αÑé αñåαñÅαñùαñ╛αÑñ αñ¬αñ░ αñºαÑìαñ»αñ╛αñ¿ αñ░αñûαÑçαñé αñ░αÑçαñ¿αÑÇ αñ╕αÑÇαñ£αñ¿ αñ«αÑçαñé αñ╡αÑêαñ╕αÑç αñ¡αÑÇ αñòαñ╛αñ« αñòαñ░αñ¿αÑç αñòαñ╛ αññαñ░αÑÇαñòαñ╛ αñ¼αñªαñ▓ αñ£αñ╛αññαñ╛ αñ╣αÑêαÑñ αñòαÑïαñê αñ¼αñ╛αñ╣αñ░ αñòαñ╛ αñ╕αÑìαñƒαÑìαñ░αñòαÑìαñÜαñ░αñ▓ αñ╡αñ░αÑìαñò αñ¿αñ╣αÑÇαñé αñ╣αÑïαññαñ╛αÑñ\n7:22\n7 minutes, 22 seconds\nαñ»αÑç αñ╕αñ«αñ» αñ░αñ┐αñ»αñ▓αñ╕αÑìαñƒαÑçαñƒ αñòαñéαñ¬αñ¿αÑÇαÑ¢ αñàαñ¬αñ¿αÑç αñåαñ¬ αñòαÑï αñ╕αÑìαñ«αñ╛αñ░αÑìαñƒαñ▓αÑÇ αñçαñéαñƒαÑÇαñ░αñ┐αñ»αñ░ αñ╡αñ░αÑìαñò αñòαÑÇ αññαñ░αñ½ αñ«αÑéαñ╡ αñòαñ░αññαÑÇ αñ╣αÑêαñéαÑñ αññαÑï αññαÑï αñûαÑêαñ░ αñ¬αñ╛αñ¿αÑÇ αñòαÑÇ αñ▓αÑçαñòαñ┐αñ¿ αñªαñ┐αñòαÑìαñòαññ αñçαñ╕ αñ½αÑëαñ░ αñ░αñ┐αñ»αñ▓ αñ¬αÑéαñ░αÑç αñªαÑçαñ╢ αñ«αÑçαñé αñ╡αÑï αñàαñ▓αñù αñ¼αñ╛αññ αñ╣αÑêαÑñ\n7:31\n7 minutes, 31 seconds\nαñ¼αÑìαñ░αñ┐αñùαÑç αñÅαñéαñƒαñ░αñ¬αÑìαñ░αñ╛αñçαñ£ αñçαñ¿ αñùαñùαñ¿ αñ╣αÑÇ αñ░αñû αñ░αñ╣αñ╛ αñ╣αÑéαñéαÑñ\n7:33\n7 minutes, 33 seconds\nαñ▓αÑçαñòαñ┐αñ¿ αñåαñ£ αñ╢αñ╛αñ»αñª αñ░αñ┐αñ»αñ▓αñ╕αÑìαñƒαÑçαñƒ αñòαÑç αñ▓αñ┐αñÅ αñÑαÑïαñíαñ╝αÑç αñ╕αÑç αñ¿αñ┐αñùαñ▓αñ┐αñéαñù αñ╡αñ░αÑÇαñ£ αñ╣αÑïαñéαñùαÑçαÑñ αñ¼αÑìαñ░αÑçαñò αñ¼αÑìαñ░αÑçαñò αñòαÑç αñëαñ╕ αñ¬αñ╛αñ░ αñàαñùαñ▓αÑç αñÜαñ╛αñ░-αñÜαñ╛αñ░ αñ¬αÑç αñ¼αñ╛αññαñÜαÑÇαññαÑñ\n7:44\n7 minutes, 44 seconds\n[αñ╕αñéαñùαÑÇαññ]\n7:44\n7 minutes, 44 seconds\nαñ¼αÑìαñ░αÑçαñò αñòαÑç αñ¼αñ╛αñª αñåαñ¬αñòαñ╛ αñ╕αÑìαñ╡αñ╛αñùαññ αñ╣αÑê αñöαñ░ αñàαñùαñ▓αÑç αñÜαñ╛αñ░-αñÜαñ╛αñ░ αñ╕αÑìαñƒαÑëαñòαÑìαñ╕ αñòαÑÇ αñ¼αñ╛αññ αñòαñ░ αñ▓αÑÇ αñ£αñ╛αñÅ αñöαñ░ αñ¿αñ╡αÑÇαñ¿ αñ½αÑìαñ▓αÑïαñ░αñ╛αñçαñ¿ αñ»αñ╣αñ╛αñé αñ¬αñ░ αñåαñ¬ αñ¿αñ£αñ░ αñ░αñûαñ┐αñÅαñùαñ╛αÑñ αñ╣αñ«\n7:52\n7 minutes, 52 seconds\nαñ▓αñùαñ╛αññαñ╛αñ░ αñ¼αñ╛αññ αñòαñ░αññαÑç αñ£αñ╛ αñ░αñ╣αÑç αñ╣αÑêαñéαÑñ αñ»αÑç αñ£αÑï αñòαÑéαñ▓αñ┐αñéαñù αñùαÑêαñ╕ αñ╡αñ╛αñ▓αÑÇ αñòαñéαñ¬αñ¿αÑÇ αñ╣αÑê αñ░αÑçαñ½αÑìαñ░αñ┐αñ£αñ░αÑçαñéαñƒ αñùαÑêαñ╕ αñ╡αñ╛αñ▓αÑÇ αñòαñéαñ¬αñ¿αÑÇαÑ¢ αñçαñ¿αñòαÑç αñ▓αñ┐αñÅ αñ¼αñ╣αÑüαññ αñ╕αñ╛αñ░αÑç αñòαÑêαñƒαñ▓αñ┐αñ╕αÑìαñƒ αñ╣αÑêαñéαÑñ\n7:58\n7 minutes, 58 seconds\nαñàαñ¼ αñåαñ£ αñÅαñò αñ¼αñóαñ╝αñ┐αñ»αñ╛ αñ░αñ┐αñ¬αÑïαñ░αÑìαñƒ αñåαñê αñ╣αÑê αñ£αÑçαñ½αñ░αÑÇαñ£ αñòαÑÇ αññαñ░αñ½ αñ╕αÑç αñ£αñ╣αñ╛αñé αñ¬αñ░ αñÅαñòαÑìαñ»αÑéαñ«αÑüαñ▓αÑçαñƒ αñòαÑÇ αñ░αÑçαñƒαñ┐αñéαñù αñòαÑç αñ╕αñ╛αñÑ αñƒαñ╛αñ░αñùαÑçαñƒ αñ¬αÑìαñ░αñ╛αñçαñ╕ Γé╣8385 αñ╕αÑç αñ¼αñóαñ╝αñ╛αñòαñ░ αñàαñ¼ Γé╣8700 αñòαñ░ αñªαñ┐αñ»αñ╛αÑñ αñƒαÑçαñòαÑìαñ¿αñ┐αñòαñ▓ αññαÑîαñ░ αñ¬αñ░ αñ¡αÑÇ αñ»αÑç\n8:07\n8 minutes, 7 seconds\nαñ╕αÑìαñƒαÑëαñò αñåαñëαñƒαñ¬αñ░αñ½αÑëαñ░αÑìαñ«αñ┐αñéαñù αñ╣αÑêαÑñ αñöαñ░ αñ¡αÑÇ αñ¼αñ╣αÑüαññ αñ╕αñ╛αñ░αÑç αñƒαÑìαñ░αñ┐αñùαñ░αÑìαñ╕ αñ╣αÑêαñéαÑñ αñ╡αñ┐αñ╕αÑìαññαñ╛αñ░ αñ╕αÑç αñ¼αñ╛αñª αñ«αÑçαñé αñ¼αñ╛αññ αñòαñ░αÑçαñéαñùαÑçαÑñ αñ▓αÑçαñòαñ┐αñ¿ αñ½αñ┐αñ▓αñ╣αñ╛αñ▓ αñòαÑç αñ▓αñ┐αñÅ αñçαñ¿ αñùαÑìαñ░αÑÇαñ¿ αñ░αñûαñ╛ αñ╣αÑüαñå αñ╣αÑêαÑñ αñàαñùαñ▓αñ╛ αñ╕αÑìαñƒαÑëαñò αñ╣αÑê Sun FarmaαÑñ αñ»αñ╣αñ╛αñé αñ¬αñ░\n8:14\n8 minutes, 14 seconds\nαñ¡αÑÇ αñ¼αÑìαñ░αÑïαñòαñ░αÑçαñ£ αñ╣αñ╛αñëαñ╕ αñÅαñòαÑìαñ╡αñ░αÑÇ αñòαÑÇ αññαñ░αñ½ αñ╕αÑç αñ░αñ┐αñ¬αÑïαñ░αÑìαñƒ αñåαñê αñ╣αÑêαÑñ αñåαñëαñƒαñ¬αñ░αñ½αÑëαñ░αÑìαñ« αñòαÑÇ αñ░αÑçαñƒαñ┐αñéαñù αñÑαÑÇαÑñ\n8:18\n8 minutes, 18 seconds\n2150 αñòαñ╛ αñƒαñ╛αñ░αñùαÑçαñƒ αñ╣αÑê αñöαñ░ αñ»αñ╣ αñ¼αññαñ╛ αñ░αñ╣αÑç αñ╣αÑêαñé αñòαñ┐ αñ£αÑï αñçαñ¿αÑìαñ╣αÑïαñéαñ¿αÑç αñ╣αñ╛αñ▓ αñ╣αÑÇ αñ«αÑçαñé αñ»αÑéαñÅαñ╕ αñòαÑÇ αñ¼αñíαñ╝αÑÇ αñòαñéαñ¬αñ¿αÑÇ αñòαñ╛ αñÅαñòαÑìαñ╡αñ┐αñ£αñ┐αñ╢αñ¿ αñòαñ┐αñ»αñ╛ αñÑαñ╛αÑñ αñçαñ╕αñ╕αÑç αñÅαñò αñ«αÑÇαñ¿αñ┐αñéαñùαñ½αÑüαñ▓ αñàαñ¬αñ╕αñ╛αñçαñí αñ»αñ╣αñ╛αñé αñ¬αñ░ αñªαÑçαñûαñ¿αÑç αñòαÑï αñ«αñ┐αñ▓\n8:26\n8 minutes, 26 seconds\nαñ╕αñòαññαÑÇ αñ╣αÑêαÑñ αñ¼αÑüαñ▓αñ┐αñ╢ αñ╣αÑê αñöαñ░ αñ»αÑç αñ¼αññαñ╛ αñ░αñ╣αÑç αñ╣αÑêαñé αñòαñ┐ αñ£αÑï αñ╕αñ┐αñ¿αñ░αÑìαñ£αÑÇ αñ░αÑçαñ╡αÑçαñ¿αÑìαñ»αÑé αñùαÑìαñ░αÑïαñÑ αñíαÑçαñ¬αÑìαñƒ αñòαÑï αñ▓αÑçαñòαñ░ αñòαñéαñ╕αñ░αÑìαñ¿αÑìαñ╕ αñ¼αññαñ╛αñÅ αñ£αñ╛ αñ░αñ╣αÑç αñ╣αÑêαñéαÑñ αñÑαÑïαñíαñ╝αÑç αñ╕αÑç αñôαñ╡αñ░αñíαñ¿ αñ╣αÑêαÑñ αññαÑï αñçαñ╕ αñ╕αÑìαñƒαÑëαñò αñòαÑï αñ¡αÑÇ αñçαñ¿αñòαÑìαñ░αÑÇαñ¿ αñ░αñûαñ╛ αñ╣αÑêαÑñ\n8:35\n8 minutes, 35 seconds\nαñàαñÜαÑìαñ¢αñ╛ αñªαÑï αñ«αÑêαñéαñ¿αÑç αñåαñ£ αñ╕αÑüαñ¼αñ╣ αñ«αÑëαñ░αÑìαñ¿αñ┐αñéαñù αñòαÑëαñ▓ αñ«αÑçαñé αñ«αÑçαñéαñ╢αñ¿ αñòαñ░ αñ░αñ╣αñ╛ αñÑαñ╛ αñòαñ┐ αñƒαÑÇαñ« αñ¼αñªαñ▓αÑÇαÑñ αñ╡αÑï αñÅαñò αññαÑï αñ╣αÑê αñòαñ┐ αñêαñ░αñ╛αñ¿ αñòαÑç αñ▓αñ┐αñÅ αñàαñ¼ αñ╡αÑï αñòαñ╛αñ½αÑÇ αñ╕αñ░αÑìαñƒαÑçαñ¿αñ┐αñƒαÑÇ αñå αñùαñê\n8:43\n8 minutes, 43 seconds\nαñ╣αÑêαÑñ αñ£αñ┐αññαñ¿αÑç αñ¡αÑÇ αñ▓αÑÇαñò αñíαÑëαñòαÑìαñ»αÑéαñ«αÑçαñéαñƒαÑìαñ╕ αñ╣αÑêαñé αñòαñ┐ 300 αñ¼αñ┐αñ▓αñ┐αñ»αñ¿ αñíαÑëαñ▓αñ░ αñòαÑÇ αñ╡αñ╛αñòαñê αñ½αñ╛αñçαñ¿αÑçαñéαñ╕αñ┐αñéαñù αñòαÑÇ αññαÑêαñ»αñ╛αñ░αÑÇαÑñ αññαÑï αñçαñ░αñòαÑëαñ¿ αñçαñéαñƒαñ░αñ¿αÑçαñ╢αñ¿αñ▓ αñ░αñ╛αñçαñƒαÑìαñ╕ αñªαÑïαñ¿αÑïαñé\n8:50\n8 minutes, 50 seconds\nαñçαñ¿αñùαÑìαñ░αÑÇαñ¿ αñòαñ░ αñªαñ┐αñÅαÑñ αñªαÑïαñ¿αÑïαñé αñ╣αÑçαñ╡αñ▓αÑÇ αñíαÑìαñ░αñ┐αñ╡αñ¿ αñ╣αÑê αñ╕αÑìαñƒαÑçαñƒ αñƒαÑé αñ╕αÑìαñƒαÑçαñƒ αñ«αÑêαñéαñíαÑçαñƒαÑìαñ╕ αñöαñ░ αñçαñ¿αÑìαñ╣αÑïαñéαñ¿αÑç αñ¼αñ╣αÑüαññ αñòαñ╛αñ« αñòαñ░ αñ░αñûαñ╛ αñ╣αÑê αñ╡αñ╣αñ╛αñé αñ¬αÑçαÑñ αññαÑï αñçαñ¿ αñªαÑïαñ¿αÑïαñé αñòαÑï αñùαÑìαñ░αÑÇαñ¿ αñòαñ░ αñªαñ┐αñ»αñ╛αÑñ αñòαÑüαñ¢ αñòαñ░αñòαÑç αñ╣αÑÇ αñ¿αñ╣αÑÇαñé αñªαÑç αñ░αñ╣αÑç\n8:59\n8 minutes, 59 seconds\nαñ╡αÑêαñ╕αÑç αñ¡αÑÇ αñ»αÑç αñ╕αÑìαñƒαÑëαñòαÑñ αññαÑï αñ▓αÑçαñƒαÑìαñ╕ αñ╣αÑïαñ¬ αñ╕αÑï αñ£αñ¼ αññαñò αñ╡αÑï αñíαÑÇαñ▓ αñ╣αÑï αñ░αñ╣αÑÇ αñ╣αÑï αñçαñ╕ αñ¼αÑÇαñÜ αñòαÑüαñ¢ αñÅαñòαÑìαñ»αÑéαñ«αÑüαñ▓αÑçαñ╢αñ¿ αñå αñ░αñ╣αñ╛ αñ╣αÑïαÑñ αñªαÑï αñöαñ░ αñ£αÑïαñíαñ╝ αñªαÑçαññαñ╛ αñ╣αÑéαñéαÑñ αñ╡αñ┐pαÑìαñ░αÑï αñöαñ░\n9:05\n9 minutes, 5 seconds\nTCS αñ╡αñ┐pαÑìαñ░αÑï αñ¿αÑç αñÅαñò αñ╕αÑçαñéαñƒαñ░ αñæαÑ₧ αñÅαñòαÑìαñ╕αÑÇαñ▓αÑçαñéαñ╕ αñûαÑïαÑ£αñ╛ αñ╣αÑê αñòαÑìαñ▓αñ╛αñëαñí αñ«αÑëαñíαñ▓αÑìαñ╕ αñòαÑç αñ▓αñ┐αñÅ αñÅαñéαñÑαÑìαñ░αÑïαñ¬αñ┐αñò\n9:12\n9 minutes, 12 seconds\nαñ¬αñ╛αñ╡αñ░αÑìαñíαÑñ αñ¼αÑ¥αñ┐αñ»αñ╛ αñûαñ¼αñ░ αñ╣αÑêαÑñ αñ╣αñ╛αñê αñÅαñéαñí αñíαñ┐αñ▓αÑÇαñ╡αñ░αÑÇ αñòαÑÇ αññαñ░αñ½ αñ¼αÑ¥ αñ░αñ╣αÑç αñ╣αÑêαñéαÑñ αñöαñ░ αñªαÑéαñ╕αñ░αñ╛ αñƒαÑÇαñ╕αÑÇαñÅαñ╕ αñòαñ▓ αñ╕αÑüαñ¼αñ╣ αñ╡αÑï αñùαñ╛αñ£ αñùαñ┐αñ░αñ¿αÑç αñòαÑÇ αñûαñ¼αñ░ αñÑαÑÇαÑñ αñ»αÑéαñÅαñ╕ αñòαÑïαñ░αÑìαñƒ αñ¿αÑç\n9:21\n9 minutes, 21 seconds\nαñÅαñòαÑìαñ╕αÑçαñ¬αÑìαñƒ αñ¿αñ╣αÑÇαñé αñòαñ░αñ╛ αññαÑï αñçαñ¿αñòαÑï αñ¬αÑç αñòαñ░αñ¿αñ╛ αñ¬αñíαñ╝αÑçαñùαñ╛αÑñ αñëαñ╕αñòαÑç αñ¼αñ╛αñ╡αñ£αÑéαñª αñƒαÑÇαñ╕αÑÇαñÅαñ╕ αñ«αñ£αñ¼αÑéαññ αñÑαñ╛αÑñ αñûαÑêαñ░ αñ╢αñ╛αñ« αñòαÑï αñàαñ¬αñíαÑçαñƒ αñåαñ»αñ╛ αñÅαñò αñöαñ░ αñƒαÑïαñƒαñ¿αñ╣αñ« αñ╣αÑëαñƒαñ╕αÑìαñ¬αÑïαñ░\n9:29\n9 minutes, 29 seconds\nαñ½αÑüαñƒαñ¼αÑëαñ▓ αñòαÑìαñ▓αñ¼ αñ¿αÑëαñ░αÑìαñÑ αñ▓αñéαñªαñ¿ αñòαñ╛αÑñ αñëαñ¿αñòαÑç αñ╕αñ╛αñÑ αñòαñ░αñ╛αñ░ αñ╣αÑüαñå αñ╣αÑê αñëαñ¿αñòαÑç αñíαñ┐αñ£αñ┐αñƒαñ▓ αñƒαÑìαñ░αñ╛αñéαñ╕αñ½αÑëαñ░αÑìαñ«αÑçαñ╢αñ¿ αñòαÑç αñ¬αñ╛αñ░αÑìαñƒαñ¿αñ░ αñ¼αñ¿αÑçαñéαñùαÑçαÑñ αñåαñ╕αñ╛αñ¿ αñ╢αñ¼αÑìαñªαÑïαñé αñ«αÑçαñé αñæαñ░αÑìαñíαñ░\n9:37\n9 minutes, 37 seconds\nαñ¼αÑêαñò αñòαñ┐αñ»αñ╛αÑñ αññαÑï αñçαñ╕αñòαÑï αñùαÑìαñ░αÑÇαñ¿ αñ╣αÑÇ αñòαñ░ αñªαñ┐αñ»αñ╛αÑñ αñåαñêαñƒαÑÇ αñÑαÑïαñíαñ╝αñ╛ αñ¼αñ╣αÑüαññ αñ¼αÑçαñ╣αññαñ░ αñÜαñ▓ αñ░αñ╣αñ╛ αñ╣αÑê αñåαñ£αñòαñ▓αÑñ\n9:41\n9 minutes, 41 seconds\nαñ╣αñ« αñåαñûαñ┐αñ░αÑÇ αñòαÑç αñªαÑï αñ╕αÑìαñƒαÑëαñò αñ╣αÑê αñ╡αñ┐αñ╢αñ╛αñ▓ αñ«αÑçαñùαñ╛αÑñ αñ»αñ╣αñ╛αñé αñ¬αñ░ αñåαñ¬ αñªαÑçαñûαñ┐αñÅ αñàαñùαñ░ αñ«αñ╛αñ░αÑìαñòαÑçαñƒαÑìαñ╕ αñæαñ½ αñ╣αÑïαññαñ╛ αñ╣αÑê αñÑαÑïαñíαñ╝αÑÇ αñ╕αÑÇ αñòαñ«αñ£αÑïαñ░αÑÇ αñåαññαÑÇ αñ╣αÑêαÑñ αññαÑï αñòαÑüαñ¢ αñÉαñ╕αÑç αñ£αÑï αñƒαÑçαñòαÑìαñ¿αñ┐αñòαñ▓ αññαÑîαñ░ αñ¬αñ░ αñ╕αÑìαñƒαÑëαñò αñòαñ«αñ£αÑïαñ░ αñ╣αÑêαÑñ αñ»αñ╣αñ╛αñé αñ¬αñ░\n9:50\n9 minutes, 50 seconds\nαñåαñ¬ αñ¿αñ£αñ░ αñ░αñûαñ┐αñÅαñùαñ╛αÑñ αñòαñ▓ 3% αñòαÑÇ αñùαñ┐αñ░αñ╛αñ╡αñƒ αñåαñ¬αñòαÑï αñàαñÜαÑìαñ¢αÑç αñ«αñ╛αñ░αÑìαñòαÑçαñƒ αñ«αÑçαñé αñªαÑçαñûαñ¿αÑç αñòαÑï αñ«αñ┐αñ▓αÑÇαÑñ\n9:54\n9 minutes, 54 seconds\nαñ¼αÑìαñ░αÑçαñòαñíαñ╛αñëαñ¿ αñòαñéαñ½αñ░αÑìαñ« αñ╣αÑê αññαÑï αñçαñ¿ αñ░αÑçαñí αñ░αñûαñ╛ αñ╣αÑüαñå αñ╣αÑê αñöαñ░ αñ╕αÑïαñ▓αñ╛αñ░ Industries αñ¼αñ╣αÑüαññ αñùαñ£αñ¼ αñòαñ╛ αñ╕αÑìαñƒαÑëαñò αñÜαñ▓αñ╛ αñ╣αÑüαñå αñ╣αÑêαÑñ αñíαñ┐αñ½αÑçαñéαñ╕ αñ¼αÑçαñ╕ αñòαÑç αñ╕αñ¡αÑÇ αñ╕αÑìαñƒαÑëαñòαÑìαñ╕ αñ«αÑçαñé αññαÑçαñ£αÑÇ αñ¿αñ╣αÑÇαñé αñ╣αÑêαÑñ αñòαÑüαñ¢ αñÉαñ╕αÑç αñ╣αÑêαñé αñ£αÑï αñ¼αñ╣αÑüαññ\n10:02\n10 minutes, 2 seconds\nαñ¼αñíαñ╝αÑÇ αñ░αÑêαñ▓αÑÇ αñòαÑç αñ¼αñ╛αñª αñàαñ¼ αñÑαÑïαñíαñ╝αñ╛ αñ╕αñ╛ αñ╕αÑüαñ╕αÑìαññαñ╛αñ¿αÑç αñòαñ╛ αñ¬αÑìαñ░αñ»αñ╛αñ╕ αñòαñ░ αñ░αñ╣αÑç αñ╣αÑêαñé αñöαñ░ αñòαñ▓ αññαñòαñ░αÑÇαñ¼αñ¿ 2% αñòαÑÇ αñùαñ┐αñ░αñ╛αñ╡αñƒ αñ»αñ╣αñ╛αñé αñ¬αñ░ αñÑαÑÇαÑñ αñ¼αÑìαñ░αÑçαñòαñíαñ╛αñëαñ¿ αñ»αñ╣αñ╛αñé αñ¬αñ░ αñ¡αÑÇ αñ╣αÑê αññαÑï αñçαñ╕ αñ╕αÑìαñƒαÑëαñò αñòαÑï αñ¡αÑÇ αñ░αñûαñ╛ αñ╣αÑê αñçαñ¿αñ░αÑçαñƒαÑñ αññαÑï αñÜαñ▓αñ┐αñÅ αñ¼αÑÇ αñ╕αÑìαñƒαÑëαñòαÑìαñ╕ αñòαÑÇ αñ▓αñ┐αñ╕αÑìαñƒ αñ╣αÑï αñùαñê αñ╣αÑê αññαÑêαñ»αñ╛αñ░αÑñ\n10:13\n10 minutes, 13 seconds\nαñ░αÑüαñòαññαÑç αñ╣αÑêαñé αñÅαñò αñ¢αÑïαñƒαÑç αñ╕αÑç αñ¼αÑìαñ░αÑçαñò αñòαÑç αñ▓αñ┐αñÅ αñöαñ░ αñ¼αÑìαñ░αÑçαñò αñòαÑçαÑñ αñÜαñ▓αñ┐αñÅ αñ¼αÑìαñ░αÑçαñò αñòαÑç αñ¼αñ╛αñª αñåαñ¬αñòαñ╛ αñ╕αÑìαñ╡αñ╛αñùαññ αñ╣αÑê αñöαñ░ αñàαñ¼ αñªαÑçαñûαññαÑç αñ╣αÑêαñé αñ░αñ┐αñòαñòαÑêαñ¬αÑñ αñ╢αÑüαñ░αÑüαñåαññ αñ«αÑêαñéαñ¿αÑç αñòαÑÇ αñÅαñÜαñ£αÑÇ [αñ╕αñéαñùαÑÇαññ] αñçαñ▓αÑçαñòαÑìαñƒαÑìαñ░αÑëαñ¿αñ┐αñòαÑìαñ╕ αñòαÑç αñ╕αñ╛αñÑαÑñ\n10:19\n10 minutes, 19 seconds\nαñçαñ╕αñòαÑç αñàαñ▓αñ╛αñ╡αñ╛ αñåαñêαñƒαÑÇc αñ╕αÑìαñƒαÑëαñò αñ¬αñ░ αñ¡αÑÇ αñûαñ╛αñ╕ αñ½αÑïαñòαñ╕ αñ░αñûαñ┐αñÅαñùαñ╛αÑñ αñòαñ╛ αñ«αñ╕αñùαñ╛αñéαñ╡ αñíαÑëαñò αñ╣αÑê αñåαñê αñ½in αñòαñ░αÑìαñ¿αñ╛αñƒαñòαñ╛ αñ¼αÑêαñéαñò tαñ╛αñçαñƒαñ¿ αñ«αÑçαñé αñ¬αÑìαñ░αñ╛αñçαñ╕ αñ╡αÑëαñ▓αÑìαñ»αÑéαñ« αñÅαñòαÑìαñ╢αñ¿ αñòαñ╛αñ½αÑÇ αñçαñéαñƒαñ░αÑçαñ╕αÑìαñƒαñ┐αñéαñù [αñ╕αñéαñùαÑÇαññ] αñ▓αñù αñ░αñ╣αñ╛ αñ╣αÑêαÑñ αñ¿αñ╡αÑÇαñ¿ αñ½αÑìαñ▓αÑïαñ░αñ╛αñçαñ¿ αñ¬αñ░ αñ¼αÑìαñ░αÑïαñòαÑçαñ£ αñ╣αñ╛αñëαñ╕ αñòαÑÇ αññαñ░αñ½ αñ╕αÑç\n10:27\n10 minutes, 27 seconds\nαñ¼αñóαñ╝αñ┐αñ»αñ╛ αñ░αñ┐αñ¬αÑïαñ░αÑìαñƒ αñ╣αÑêαÑñ Sun Farma αñòαÑï αñ¡αÑÇ αñ▓αñ┐αñ╕αÑìαñƒ αñ«αÑçαñé αñ╢αñ╛αñ«αñ┐αñ▓ αñòαñ░αÑçαñéαÑñ αñ╡αñ┐αñ╢αñ╛αñ▓ αñ«αÑçαñùαñ╛ αñöαñ░ αñ╕αÑïαñ▓αñ╛αñ░ αñçαñéαñíαñ╕αÑìαñƒαÑìαñ░αÑÇαñ£ αñ»αÑç αñªαÑï αñ╕αÑìαñƒαÑëαñòαÑìαñ╕ αñ╣αÑêαñé αñÑαÑïαÑ£αÑç αñ╕αÑç αñòαñ«αñ£αÑïαñ░ [αñ╕αñéαñùαÑÇαññ] αñ╣αÑêαñéαÑñ αñôαñòαÑç 10 αñöαñ░ αñ£αÑïαÑ£ αñªαÑÇαñ£αñ┐αñÅαÑñ\n10:36\n10 minutes, 36 seconds\nαñ╕αñ┐αñ░αÑìαñ½ αñ£αñ┐αñ╕ αññαñ░αñ╣ αñòαÑÇ αñûαñ¼αñ░αÑçαñé αñ╣αÑêαñé αñëαñ╕ αññαñ░αñ╣ αñòαÑç αñòαñ▓αñ░ αñ╢αÑçαñíαÑìαñ╕ αñ╣αÑêαñéαÑñ\n10:40\n10 minutes, 40 seconds\nαñ£αÑÇαñåαñêαñ╕αÑÇ αñöαñ░ Doms αñòαÑï αñ«αÑêαñé αñ▓αñ╛αñ▓ αñ▓αÑçαñòαÑç αñ£αñ╛ αñ░αñ╣αñ╛ αñ╣αÑéαñéαÑñ αñöαñ░ αñåαñêαñôαñ╕αÑÇ, HPCL, Sonata αñ╕αÑëαñ½αÑìαñƒαñ╡αÑçαñ»αñ░,\n10:46\n10 minutes, 46 seconds\nαñ¼αÑìαñ░αñ┐αñùαÑçαñí αñÅαñéαñƒαñ░αñ¬αÑìαñ░αñ╛αñçαñ£αÑçαñ╕, αñçαñ░αñòαÑëαñ¿ αñöαñ░ αñ░αñ╛αñçαñƒαÑìαñ╕, αñ╡αñ┐pαÑìαñ░αÑï αñöαñ░ TCS [αñ╕αñéαñùαÑÇαññ] αñàαñ▓αñù-αñàαñ▓αñù αñ░αÑÇαÑ¢αñ¿ αñ╕αÑç αñÜαñ▓αññαÑç αñçαñ¿ αñùαÑìαñ░αÑÇαñ¿ αñåαñ£ αñòαÑç αñ╕αÑçαñ╢αñ¿ αñ«αÑçαñéαÑñ	f	2026-06-17 12:27:45.875408
39	UCRWFSbif-RFENbBrSiez1DA	National	General	Transcript\nSearch transcript\n0:00\n[αñ╕αñéαñùαÑÇαññ]\n0:01\n1 second\nαñ╣αñ┐αñ£αñ¼αÑüαñ▓αÑìαñ▓αñ╛αñ╣ αñ¬αñ░ αñçαñ£αñ░αñ╛αñçαñ▓ αñòαñ╛ αñ¼αñíαñ╝αñ╛ αñ╣αñ«αñ▓αñ╛αÑñ 80 αñ╕αÑç αñàαñºαñ┐αñò αñáαñ┐αñòαñ╛αñ¿αÑïαñé αñòαÑï αñòαñ┐αñ»αñ╛ αññαñ¼αñ╛αñ╣αÑñ αñçαñ£αñ░αñ╛αñçαñ▓ αñòαñ╛ αñªαñ╛αñ╡αñ╛ αñ╣αñ«αñ▓αÑç αñ«αÑçαñé αñ╣αñ┐αñ£αñ¼αÑüαñ▓αÑìαñ▓αñ╛αñ╣ αñòαÑç αñòαñê αñ╕αñªαñ╕αÑìαñ» αñóαÑçαñ░αÑñ\n0:11\n11 seconds\nαñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñêαñ░αñ╛αñ¿ αñ«αÑçαñé αñ╢αñ╛αñéαññαñ┐ αñ╕αñ«αñ¥αÑîαññαÑç αñòαÑç αñ¼αÑÇαñÜ αñªαñòαÑìαñ╖αñ┐αñúαÑÇ αñ▓αÑçαñ¼αñ¿αñ╛αñ¿ αñ¬αñ░ αñçαñ£αñ░αñ╛αñçαñ▓ αñòαñ╛ αñÿαñ╛αññαñò αñ╣αñ«αñ▓αñ╛αÑñ\n0:16\n16 seconds\nαñ¿αñ¼αñ╛αññαÑÇ αñöαñ░ αñòαÑçαñ½αñ░αñ╕ αñ╕αñ┐αñ░ [αñ╕αñéαñùαÑÇαññ] αñçαñ▓αñ╛αñòαÑïαñé αñ«αÑçαñé αñ╣αñ┐αñ£αñ¼αÑüαñ▓αÑìαñ▓αñ╛αñ╣ αñòαÑç αñáαñ┐αñòαñ╛αñ¿αÑïαñé αñ¬αñ░ αñ£αñ¼αñ░αñªαñ╕αÑìαññ αñ¼αñ«αñ¼αñ╛αñ░αÑÇαÑñ 18 αñ▓αÑïαñùαÑïαñé αñòαÑÇ αñ«αÑîαññαÑñ\n0:23\n23 seconds\nαñ╣αñ┐αñ£αñ¼αÑüαñ▓αÑìαñ▓αñ╛αñ╣ αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñçαñ£αñ░αñ▓αÑÇ αñ╡αñ╛αñ»αÑü αñ╕αÑçαñ¿αñ╛ αñ¿αÑç αññαÑçαñ£ [αñ╕αñéαñùαÑÇαññ] αñòαñ┐αñÅ αñ╣αñ«αñ▓αÑçαÑñ αñªαñòαÑìαñ╖αñ┐αñúαÑÇ αñ▓αÑçαñ¼αñ¿αñ╛αñ¿ αñòαÑç αñ¼αÑçαñòαñ╛ αñÿαñ╛αñƒαÑÇ αñ«αÑçαñé αñªαÑï αñòαñ«αñ╛αñéαñí αñ╕αÑçαñéαñƒαñ░αÑìαñ╕ αñòαÑï αñëαñíαñ╝αñ╛αñ»αñ╛ αñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñåαññαñéαñòαÑÇ αñùαññαñ┐αñ╡αñ┐αñºαñ┐αñ»αñ╛αñé αñÜαñ▓αñ╛αñ¿αÑç αñòαñ╛ αñªαñ╛αñ╡αñ╛αÑñ\n0:35\n35 seconds\nαñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñòαÑç αñ╕αñ╛αñÑ αñ╣αÑüαñÅ αñÅαñ«αñôαñ»αÑé αñòαÑç αñÅαñò αñªαñ┐αñ¿ αñòαÑç αñ¼αñ╛αñª αñêαñ░αñ╛αñ¿ αñòαñ╛ αñ»αÑéαñƒαñ░αÑìαñ¿ αñòαñ╣αñ╛ αñ╣αÑëαñ░αÑìαñ«αÑïαñ╕ αñ╕αÑç αñùαÑüαñ£αñ░αñ¿αÑç αñ╡αñ╛αñ▓αÑç αñ£αñ╣αñ╛αñ£αÑïαñé αñòαÑï αñàαñ¡αÑÇ αñ¡αÑÇ αñ▓αÑçαñ¿αñ╛ αñ╣αÑïαñùαñ╛ αñ¬αñ░αñ«αñ┐αñƒαÑñ\n0:43\n43 seconds\nαñ╕αÑìαñƒαÑçαñƒ αñæαñ½ αñ╣αÑëαñ░αÑìαñ«αÑïαñ╕ αñ¬αñ░ αñ¼αññαñ╛αñ»αñ╛ αñàαñ¬αñ¿αñ╛ αñàαñºαñ┐αñòαñ╛αñ░αÑñ αñàαñº αñ«αÑçαñé αñ▓αñƒαñò αñ╕αñòαññαÑÇ αñ╣αÑê αñàαñ«αÑçαñ░αñ┐αñòαñ╛αÑñ αñêαñ░αñ╛αñ¿ αñòαÑÇ αñíαÑÇαñ▓αÑñ\n0:49\n49 seconds\nαñÅαñò αñªαñ┐αñ¿ αñòαÑç αñ¼αñ╛αñª αñ╣αÑÇ αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ¬αññαñ┐ αñƒαÑìαñ░αñéαñ¬ αñòαñ╛ αñªαñ╛αñ╡αñ╛αÑñ αñòαñ╣αñ╛ αñêαñ░αñ╛αñ¿ αñòαÑç αñ¬αñ╛αñ╕ αñ¿αñ╣αÑÇαñé αñ¼αñÜαÑÇ αñ╕αÑêαñ¿αÑìαñ» αññαñ╛αñòαññαÑñ αñ¬αÑéαñ░αÑÇ αññαñ░αñ╣ αññαñ¼αñ╛αñ╣ αñ╣αÑï αñÜαÑüαñòαñ╛ αñ╣αÑêαÑñ αñòαñ«αñ£αÑïαñ░ αñ╣αÑï αñÜαÑüαñòαñ╛ αñ╣αÑêαÑñ αñêαñ░αñ╛αñ¿ αñòαÑï αñ¡αñ░αñ¬αñ╛αñê [αñ╕αñéαñùαÑÇαññ] αñòαÑÇ αñ¿αñ╣αÑÇαñé αñ«αñ┐αñ▓αÑçαñùαÑÇ αñ░αñòαñ«αÑñ\n1:01\n1 minute, 1 second\nαñæαñ»αñ▓ αñ░αñ┐αñ½αñ╛αñçαñ¿αñ░αÑÇ αñ¬αñ░ αñ»αÑéαñòαÑìαñ░αÑçαñ¿ αñòαÑç αñ╣αñ«αñ▓αÑç αñòαñ╛ αñ░αÑéαñ╕ αñ¿αÑç αñªαñ┐αñ»αñ╛ αñ£αñ╡αñ╛αñ¼αÑñ αñûαñ╛αñ░αñòαÑÇαñ¼ αñöαñ░ αñåαñ╕αñ¬αñ╛αñ╕ αñòαÑç αñçαñ▓αñ╛αñòαÑïαñé αñ«αÑçαñé αñ░αñ╛αññ αñ¡αñ░ αñ¼αñ░αñ╕αñ╛αñÅ αñ¼αñ«αÑñ 40 αñ░αñ┐αñ╣αñ╛αñçαñ╢αÑÇ αñçαñ«αñ╛αñ░αññαÑïαñé\n1:09\n1 minute, 9 seconds\nαñòαÑï αñ¬αñ╣αÑüαñéαñÜαñ╛ αñ¿αÑüαñòαñ╕αñ╛αñ¿αÑñ αñƒαÑìαñ░αñò αñ¬αñ╛αñ░αÑìαñòαñ┐αñéαñù αñÅαñ░αñ┐αñ»αñ╛ αñ«αÑçαñé αñ▓αñùαÑÇ αñ¡αÑÇαñ╖αñú αñåαñùαÑñ\n1:14\n1 minute, 14 seconds\nαñ░αÑéαñ╕, αñ»αÑéαñòαÑìαñ░αÑçαñ¿ αñ£αñéαñù αñòαÑÇ αñåαñù αñ«αÑçαñé αñÿαÑÇ αñíαñ╛αñ▓αÑçαñéαñùαÑç αñ»αÑéαñ░αÑïαñ¬αÑÇαñ» αñªαÑçαñ╢αÑñ αñ»αÑéαñòαÑìαñ░αÑçαñ¿ αñòαÑï αñªαÑçαñéαñùαÑç αñòαñ░αÑÇαñ¼ 36,000 αñòαñ░αÑïαñíαñ╝ αñòαÑç αñíαÑìαñ░αÑïαñ¿αÑñ [αñ╕αñéαñùαÑÇαññ] αñ¬αÑçαñƒαÑìαñ░αñ┐αñ»αñƒ, αñ«αñ┐αñ╕αñ╛αñçαñ▓ αñöαñ░ αññαÑïαñ¬ αñòαÑç αñùαÑïαñ▓αÑçαÑñ αñ»αÑéαñòαÑìαñ░αÑçαñ¿ αñíαñ┐αñ½αÑçαñéαñ╕\n1:22\n1 minute, 22 seconds\nαñòαñ╛αñéαñƒαÑçαñòαÑìαñƒ αñùαÑìαñ░αÑüαñ¬ αñòαñ╛ αñ╣αñ┐αñ╕αÑìαñ╕αñ╛ αñ╣αÑê αñçαñéαñùαÑìαñ▓αÑêαñéαñí αñöαñ░ αñ£αñ░αÑìαñ«αñ¿αÑÇ αñ╕αñ«αÑçαññ αñÅαñò αñªαñ░αÑìαñ£αñ¿ αñªαÑçαñ╢αÑñ\n1:28\n1 minute, 28 seconds\nαñ¼αñ╛αñ▓αÑìαñƒαñ┐αñò αñ╕αñ╛αñùαñ░ αñ«αÑçαñé αñ¿αñ╛αñƒαÑï αñªαÑçαñ╢αÑïαñé αñ¿αÑç αñòαñ┐αñ»αñ╛ αñ╕αÑêαñ¿αÑìαñ» αñàαñ¡αÑìαñ»αñ╛αñ╕αÑñ 20 αñ¿αÑîαñ╕αÑêαñ¿αñ┐αñòαÑïαñé αñ¿αÑîαñ╕αÑêαñ¿αñ┐αñò αñ£αñ╣αñ╛αñ£αÑïαñé αñòαñ╛ αñ½αÑëαñ░αÑìαñ«αÑçαñ╢αñ¿ αñªαñ┐αñûαñ╛αñ»αñ╛ αñùαñ»αñ╛αÑñ αñàαñ«αÑçαñ░αñ┐αñòαñ╛, αñ»αÑéαñòαÑç, αñ½αÑìαñ░αñ╛αñéαñ╕, αñçαñƒαñ▓αÑÇ [αñ╕αñéαñùαÑÇαññ] αñ╕αñ«αÑçαññ αñòαÑüαñ▓ 15 αñªαÑçαñ╢αÑïαñé αñ¿αÑç αñ▓αñ┐αñ»αñ╛ αñ╣αñ┐αñ╕αÑìαñ╕αñ╛αÑñ\n1:40\n1 minute, 40 seconds\nαñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ¬αññαñ┐ αñƒαÑìαñ░αñéαñ¬ αñ¬αñ░ αñ¡αñíαñ╝αñòαÑÇ αñçαñƒαñ▓αÑÇ αñòαÑç αñ¬αÑìαñ░αñºαñ╛αñ¿αñ«αñéαññαÑìαñ░αÑÇ αñ£αÑëαñ░αÑìαñ£αñ┐αñ»αñ╛ αñ«αÑçαñ▓αÑïαñ¿αÑÇαÑñ αñƒαÑìαñ░αñéαñ¬ αñòαÑç αñ¼αñ»αñ╛αñ¿ αñòαÑï αñ«αñ¿αñùαñóαñ╝αñéαññ αñ¼αññαñ╛αñ»αñ╛αÑñ αñƒαÑìαñ░αñéαñ¬ αñ¿αÑç αñòαñ╣αñ╛ αñÑαñ╛ αñ«αÑçαñ▓αÑïαñ¿αÑÇ αñ¿αÑç αñ╕αñ╛αñÑ αñ«αÑçαñé αññαñ╕αÑìαñ╡αÑÇαñ░ αñûαñ┐αñéαñÜαñ╡αñ╛αñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ αñ«αñ╛αñéαñùαÑÇ αñÑαÑÇ αñ¡αÑÇαñûαÑñ\n1:51\n1 minute, 51 seconds\nαñ¬αÑÇαñô αñ£αÑçαñòαÑç αñ«αÑçαñé αñ¬αñ╛αñòαñ┐αñ╕αÑìαññαñ╛αñ¿αÑÇ αñ░αÑçαñéαñ£αñ░αÑìαñ╕ αñ¿αÑç αñ½αñ┐αñ░ αñ▓αÑïαñùαÑïαñé αñ¬αñ░ αñòαñ╣αñ░ αñ¼αñ░αñ¬αñ╛αñ»αñ╛αÑñ αñàαñéαñºαñ╛αñºαÑüαñéαñº αñùαÑïαñ▓αñ┐αñ»αñ╛αñé αñ¼αñ░αñ╕αñ╛αñêαÑñ αñ╣αñ«αñ▓αÑç αñ«αÑçαñé αñªαÑï αñ▓αÑïαñùαÑïαñé αñòαÑÇ αñ«αÑîαññ, αñåαñá αñÿαñ╛αñ»αñ▓αÑñ αñùαÑïαñ▓αÑÇαñ¼αñ╛αñ░αÑÇ αñ«αÑçαñé αñàαñ¼ αññαñò 58 αñ¬αÑìαñ░αñªαñ░αÑìαñ╢αñ¿αñòαñ╛αñ░αñ┐αñ»αÑïαñé [αñ╕αñéαñùαÑÇαññ] αñòαÑÇ αñ£αñ╛αñ¿ αñùαñêαÑñ\n2:03\n2 minutes, 3 seconds\nαñ¬αñ╢αÑìαñÜαñ┐αñ« αñ¼αñéαñùαñ╛αñ▓ αñ«αÑçαñé αññαÑÇαñ¿ αñ»αÑüαñªαÑìαñº αñ¬αÑïαññ, αñ¿αÑî αñ╕αÑçαñ¿αñ╛ [αñ╕αñéαñùαÑÇαññ] αñ«αÑçαñé αñ╣αÑïαñéαñùαÑç αñ╢αñ╛αñ«αñ┐αñ▓αÑñ 21 αñ£αÑéαñ¿ αñòαÑï αñªαÑéαñ¿αñ╛αñùαñ┐αñ░αÑÇ, αñ╕αñéαñ╢αÑïαñºαñò αñöαñ░ αñàαñùαÑìαñ░αÑïαññ αñ╣αÑïαñéαñùαÑç αñòαñ«αÑÇαñ╢αñ¿αÑñ\n2:11\n2 minutes, 11 seconds\nαñ¬αÑÇαñÅαñ« αñ«αÑïαñªαÑÇ αñ¡αÑÇ αñòαñ╛αñ░αÑìαñ»αñòαÑìαñ░αñ« αñ«αÑçαñé αñ╣αÑïαñéαñùαÑç αñ╢αñ╛αñ«αñ┐αñ▓αÑñ\n2:15\n2 minutes, 15 seconds\nαñàαñ¡αñ┐αñ╖αÑçαñò αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñ¿αÑç αñ▓αÑïαñòαñ╕αñ¡αñ╛ αñ╕αÑìαñ¬αÑÇαñòαñ░ αñôαñ« [αñ╕αñéαñùαÑÇαññ] αñ¼αñ┐αñ░αñ▓αñ╛ αñ╕αÑç αñòαÑÇ αñ«αÑüαñ▓αñ╛αñòαñ╛αññαÑñ αñ¼αñ╛αñùαÑÇ αñ╕αñ╛αñéαñ╕αñªαÑïαñé αñòαÑï αñàαñ▓αñù αñùαÑüαñƒ αñòαÑÇ αñ«αñ╛αñ¿αÑìαñ»αññαñ╛ αñªαÑçαñ¿αÑç αñ¬αñ░ αñ£αññαñ╛αñ»αñ╛ αñÉαññαñ░αñ╛αñ£αÑñ 20 αñàαñ▓αñù-αñàαñ▓αñù αñ»αñ╛αñÜαñ┐αñòαñ╛αñÅαñé αñªαÑÇαÑñ\n2:23\n2 minutes, 23 seconds\nαñ«αÑüαñ▓αñ╛αñòαñ╛αññ αñòαÑç αñªαÑîαñ░αñ╛αñ¿ αñòαñ▓αÑìαñ»αñ╛αñú αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñöαñ░ αñ«αñ╣αñ╡αñ╛ αñ«αÑïαñ╣αñ┐αññαÑìαñ░αñ╛ αñ¡αÑÇ αñÑαÑç αñ«αÑîαñ£αÑéαñªαÑñ\n2:29\n2 minutes, 29 seconds\nαñƒαÑÇαñÅαñ«αñ╕αÑÇ αñòαÑç 20 αñ¼αñ╛αñùαÑÇ αñ╕αñ╛αñéαñ╕αñªαÑïαñé αñòαÑç αñ«αñ╛αñ«αñ▓αÑç αñ¬αñ░ αñ╕αÑìαñ¬αÑÇαñòαñ░ αñ£αñ▓αÑìαñª αñòαñ░αÑçαñéαñùαÑç αñ½αÑêαñ╕αñ▓αñ╛αÑñ αñ╕αÑéαññαÑìαñ░αÑïαñé αñ╕αÑç αñûαñ¼αñ░αÑñ αñ╕αñªαñ¿ αñ«αÑçαñé αñàαñ▓αñù αñ¼αÑêαñáαñ¿αÑç [αñ╕αñéαñùαÑÇαññ] αñöαñ░ αñÅαñ¿αñ╕αÑÇαñ¬αÑÇαñåαñê αñòαÑç αñ╕αñªαñ╕αÑìαñ» αñòαÑç αññαÑîαñ░ αñ¬αñ░ αñ«αñ╛αñ¿αÑìαñ»αññαñ╛ αñªαÑçαñ¿αÑç αñòαÑÇ αñ»αñ╛αñÜαñ┐αñòαñ╛ αñ¬αñ░ αñ£αñ▓αÑìαñª αñ▓αÑçαñéαñùαÑç αñ¿αñ┐αñ░αÑìαñúαñ»αÑñ\n2:42\n2 minutes, 42 seconds\nαñ¬αñ╢αÑìαñÜαñ┐αñ« αñ¼αñéαñùαñ╛αñ▓ αñ«αÑçαñé αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ¿αÑçαññαñ╛αñôαñé αñ¬αñ░ αñàαñéαñíαñ╛ αñ½αÑçαñéαñò αñ╣αñ«αñ▓αñ╛ αñ£αñ╛αñ░αÑÇ αñ╣αÑêαÑñ αñåαñ╕αñ¿αñ╕αÑïαñ▓ αñ«αÑçαñé αñòαÑïαñ░αÑìαñƒ αñ«αÑçαñé αñ¬αÑçαñ╢αÑÇ αñòαÑç αñ▓αñ┐αñÅ αñ▓αÑç αñ£αñ╛αñ¿αÑç αñòαÑç αñªαÑîαñ░αñ╛αñ¿ αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ¿αÑçαññαñ╛ αñ¡αÑïαñ▓αñ╛ αñ╕αñ┐αñéαñ╣ αñ¬αñ░ αñ▓αÑïαñùαÑïαñé αñ¿αÑç αñàαñéαñíαÑç αñ½αÑçαñéαñòαÑçαÑñ αñ╣αÑçαñ▓αñ«αÑçαñƒ αñ¬αñ╣αñ¿αñ╛αñòαñ░ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ¼αñÜαñ╛αñ»αñ╛αÑñ\n2:56\n2 minutes, 56 seconds\nαñ¬αÑÇαñÅαñ« αñ«αÑïαñªαÑÇ αñ¿αÑç αñ¬αÑìαñ░αñºαñ╛αñ¿αñ«αñéαññαÑìαñ░αÑÇ αñ╡αñ┐αñòαñ╕αñ┐αññ αñ¡αñ╛αñ░αññ αñ░αÑïαñ£αñùαñ╛αñ░ αñ»αÑïαñ£αñ¿αñ╛ αñòαÑç αññαñ╣αññ αñ▓αñùαñ¡αñù Γé╣2400 αñòαñ░αÑïαñíαñ╝ αñòαÑÇ αñ¬αÑìαñ░αÑïαññαÑìαñ╕αñ╛αñ╣αñ¿ αñ░αñ╛αñ╢αñ┐ αñ╡αñ┐αññαñ░αñ┐αññ αñòαÑÇαÑñ αñ▓αñ╛αñ¡αñ╛αñ░αÑìαñÑαñ┐αñ»αÑïαñé αñ╕αÑç αñòαñ┐αñ»αñ╛ αñ╕αñéαñ╡αñ╛αñªαÑñ\n3:07\n3 minutes, 7 seconds\nαñ╣αñ¿αÑüαñ«αñ╛αñ¿αñùαñóαñ╝αÑÇ αñ«αÑçαñé αñ╣αñ╛αñ£αñ┐αñ░αÑÇ αñ▓αñùαñ╛αñ¿αÑç αñòαÑç αñ¼αñ╛αñª αñ╕αÑÇαñÅαñ« αñ»αÑïαñùαÑÇ αñ¿αÑç αñàαñ»αÑïαñºαÑìαñ»αñ╛ αñ«αñéαñªαñ┐αñ░ αñ«αÑçαñé αñòαñ┐αñÅ αñ╢αÑìαñ░αÑÇ αñ░αñ╛αñ« αñòαÑç αñªαñ░αÑìαñ╢αñ¿αÑñ αñ░αñ╛αñ«αñ▓αñ▓αñ╛ αñòαÑÇ αñåαñ░αññαÑÇ αñëαññαñ╛αñ░αÑÇαÑñ αñÜαñéαñ¬αññ αñ░αñ╛αñ» αñòαÑï αñòαñ╛αñ░αÑìαñ»αñòαÑìαñ░αñ« αñ╕αÑç αñ░αñûαñ╛ αñùαñ»αñ╛ αñªαÑéαñ░αÑñ\n3:17\n3 minutes, 17 seconds\nαñàαñ»αÑïαñºαÑìαñ»αñ╛ αñ«αÑçαñé αñÜαñóαñ╝αñ╛αñ╡αñ╛ αñÜαÑïαñ░αÑÇ αñ╡αñ┐αñ╡αñ╛αñª αñ¬αñ░ αñ¼αÑïαñ▓αÑç αñ╕αÑÇαñÅαñ« αñ»αÑïαñùαÑÇαÑñ αñÅαñ╕αñåαñêαñƒαÑÇ αñ£αñ╛αñéαñÜ αñ«αÑçαñé αñ╣αÑïαñùαñ╛ αñªαÑéαñº αñòαñ╛ αñªαÑéαñº αñ¬αñ╛αñ¿αÑÇ [αñ╕αñéαñùαÑÇαññ] αñòαñ╛ αñ¬αñ╛αñ¿αÑÇαÑñ αñòαÑïαñê αñ¡αÑÇ αñªαÑïαñ╖αÑÇ αñ¿αñ╣αÑÇαñé αñ¼αñÜαÑçαñùαñ╛αÑñ\n3:26\n3 minutes, 26 seconds\nαñëαññαÑìαññαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñ¼αñ╛αñùαñ¬αññ [αñ╕αñéαñùαÑÇαññ] αñ«αÑçαñé αñ«αñ╣αñéαñùαñ╛αñê αñ¡αÑìαñ░αñ╖αÑìαñƒαñ╛αñÜαñ╛αñ░ αñòαÑï αñ▓αÑçαñòαñ░ αñ╕αñ«αñ╛αñ£αñ╡αñ╛αñªαÑÇ αñ¬αñ╛αñ░αÑìαñƒαÑÇ αñòαÑç αñ¿αÑçαññαñ╛αñôαñé αñ¿αÑç αñ¼αÑêαñ▓αñùαñ╛αñíαñ╝αÑÇ αñ¬αñ░ αñ╕αñ╡αñ╛αñ░ αñ╣αÑïαñòαñ░ αñòαñ┐αñ»αñ╛ αñ¬αÑìαñ░αñªαñ░αÑìαñ╢αñ¿αÑñ αñ░αñ╛αñ£αÑìαñ»αñ¬αñ╛αñ▓ αñòαÑç αñ¿αñ╛αñ« αñÅαñ╕αñíαÑÇαñÅαñ« αñòαÑï αñ╕αÑîαñéαñ¬αñ╛ αñ£αÑìαñ₧αñ╛αñ¬αñ¿αÑñ\n3:38\n3 minutes, 38 seconds\nαñ¼αñ╛αñùαñ¬αññ αñòαÑç αñ¼αñíαñ╝αÑîαññ αñ«αÑçαñé αñ«αñ╣αñ┐αñ▓αñ╛αñôαñé αñ¿αÑç αñ«αñ╕αÑìαñ£αñ┐αñª αñòαÑç αñ¼αñ╛αñ╣αñ░ αñªαñ┐αñ»αñ╛ αñºαñ░αñ¿αñ╛αÑñ αñ╕αÑÇαñÅαñ« αñ»αÑïαñùαÑÇ αñ╕αÑç αñ▓αñùαñ╛αñê αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñòαÑÇ αñùαÑüαñ╣αñ╛αñ░αÑñ αñ«αñ╕αÑìαñ£αñ┐αñª αñ¿αñ┐αñ░αÑìαñ«αñ╛αñú αñòαÑï αñ▓αÑçαñòαñ░ αñ¡αÑÇ αñëαñáαñ╛αñÅ αñ╕αñ╡αñ╛αñ▓αÑñ [αñ╕αñéαñùαÑÇαññ]\n3:50\n3 minutes, 50 seconds\n[αñ╕αñéαñùαÑÇαññ]\n3:52\n3 minutes, 52 seconds\nαñÅαñ¼αÑÇαñ¬αÑÇ αñ¿αÑìαñ»αÑéαñ£αñ╝ αñåαñ¬αñòαÑï αñ░αñûαÑç αñåαñùαÑçαÑñ	f	2026-06-19 21:49:56.357709
40	UCRWFSbif-RFENbBrSiez1DA	National	General	Transcript\nSearch transcript\n0:00\n[αñ╕αñéαñùαÑÇαññ]\n0:01\n1 second\nαñ╣αñ┐αñ£αñ¼αÑüαñ▓αÑìαñ▓αñ╛αñ╣ αñ¬αñ░ αñçαñ£αñ░αñ╛αñçαñ▓ αñòαñ╛ αñ¼αñíαñ╝αñ╛ αñ╣αñ«αñ▓αñ╛αÑñ 80 αñ╕αÑç αñàαñºαñ┐αñò αñáαñ┐αñòαñ╛αñ¿αÑïαñé αñòαÑï αñòαñ┐αñ»αñ╛ αññαñ¼αñ╛αñ╣αÑñ αñçαñ£αñ░αñ╛αñçαñ▓ αñòαñ╛ αñªαñ╛αñ╡αñ╛ αñ╣αñ«αñ▓αÑç αñ«αÑçαñé αñ╣αñ┐αñ£αñ¼αÑüαñ▓αÑìαñ▓αñ╛αñ╣ αñòαÑç αñòαñê αñ╕αñªαñ╕αÑìαñ» αñóαÑçαñ░αÑñ\n0:11\n11 seconds\nαñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñêαñ░αñ╛αñ¿ αñ«αÑçαñé αñ╢αñ╛αñéαññαñ┐ αñ╕αñ«αñ¥αÑîαññαÑç αñòαÑç αñ¼αÑÇαñÜ αñªαñòαÑìαñ╖αñ┐αñúαÑÇ αñ▓αÑçαñ¼αñ¿αñ╛αñ¿ αñ¬αñ░ αñçαñ£αñ░αñ╛αñçαñ▓ αñòαñ╛ αñÿαñ╛αññαñò αñ╣αñ«αñ▓αñ╛αÑñ\n0:16\n16 seconds\nαñ¿αñ¼αñ╛αññαÑÇ αñöαñ░ αñòαÑçαñ½αñ░αñ╕ αñ╕αñ┐αñ░ [αñ╕αñéαñùαÑÇαññ] αñçαñ▓αñ╛αñòαÑïαñé αñ«αÑçαñé αñ╣αñ┐αñ£αñ¼αÑüαñ▓αÑìαñ▓αñ╛αñ╣ αñòαÑç αñáαñ┐αñòαñ╛αñ¿αÑïαñé αñ¬αñ░ αñ£αñ¼αñ░αñªαñ╕αÑìαññ αñ¼αñ«αñ¼αñ╛αñ░αÑÇαÑñ 18 αñ▓αÑïαñùαÑïαñé αñòαÑÇ αñ«αÑîαññαÑñ\n0:23\n23 seconds\nαñ╣αñ┐αñ£αñ¼αÑüαñ▓αÑìαñ▓αñ╛αñ╣ αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñçαñ£αñ░αñ▓αÑÇ αñ╡αñ╛αñ»αÑü αñ╕αÑçαñ¿αñ╛ αñ¿αÑç αññαÑçαñ£ [αñ╕αñéαñùαÑÇαññ] αñòαñ┐αñÅ αñ╣αñ«αñ▓αÑçαÑñ αñªαñòαÑìαñ╖αñ┐αñúαÑÇ αñ▓αÑçαñ¼αñ¿αñ╛αñ¿ αñòαÑç αñ¼αÑçαñòαñ╛ αñÿαñ╛αñƒαÑÇ αñ«αÑçαñé αñªαÑï αñòαñ«αñ╛αñéαñí αñ╕αÑçαñéαñƒαñ░αÑìαñ╕ αñòαÑï αñëαñíαñ╝αñ╛αñ»αñ╛ αñçαñ£αñ░αñ╛αñçαñ▓ αñòαÑç αñûαñ┐αñ▓αñ╛αñ½ αñåαññαñéαñòαÑÇ αñùαññαñ┐αñ╡αñ┐αñºαñ┐αñ»αñ╛αñé αñÜαñ▓αñ╛αñ¿αÑç αñòαñ╛ αñªαñ╛αñ╡αñ╛αÑñ\n0:35\n35 seconds\nαñàαñ«αÑçαñ░αñ┐αñòαñ╛ αñòαÑç αñ╕αñ╛αñÑ αñ╣αÑüαñÅ αñÅαñ«αñôαñ»αÑé αñòαÑç αñÅαñò αñªαñ┐αñ¿ αñòαÑç αñ¼αñ╛αñª αñêαñ░αñ╛αñ¿ αñòαñ╛ αñ»αÑéαñƒαñ░αÑìαñ¿ αñòαñ╣αñ╛ αñ╣αÑëαñ░αÑìαñ«αÑïαñ╕ αñ╕αÑç αñùαÑüαñ£αñ░αñ¿αÑç αñ╡αñ╛αñ▓αÑç αñ£αñ╣αñ╛αñ£αÑïαñé αñòαÑï αñàαñ¡αÑÇ αñ¡αÑÇ αñ▓αÑçαñ¿αñ╛ αñ╣αÑïαñùαñ╛ αñ¬αñ░αñ«αñ┐αñƒαÑñ\n0:43\n43 seconds\nαñ╕αÑìαñƒαÑçαñƒ αñæαñ½ αñ╣αÑëαñ░αÑìαñ«αÑïαñ╕ αñ¬αñ░ αñ¼αññαñ╛αñ»αñ╛ αñàαñ¬αñ¿αñ╛ αñàαñºαñ┐αñòαñ╛αñ░αÑñ αñàαñº αñ«αÑçαñé αñ▓αñƒαñò αñ╕αñòαññαÑÇ αñ╣αÑê αñàαñ«αÑçαñ░αñ┐αñòαñ╛αÑñ αñêαñ░αñ╛αñ¿ αñòαÑÇ αñíαÑÇαñ▓αÑñ\n0:49\n49 seconds\nαñÅαñò αñªαñ┐αñ¿ αñòαÑç αñ¼αñ╛αñª αñ╣αÑÇ αñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ¬αññαñ┐ αñƒαÑìαñ░αñéαñ¬ αñòαñ╛ αñªαñ╛αñ╡αñ╛αÑñ αñòαñ╣αñ╛ αñêαñ░αñ╛αñ¿ αñòαÑç αñ¬αñ╛αñ╕ αñ¿αñ╣αÑÇαñé αñ¼αñÜαÑÇ αñ╕αÑêαñ¿αÑìαñ» αññαñ╛αñòαññαÑñ αñ¬αÑéαñ░αÑÇ αññαñ░αñ╣ αññαñ¼αñ╛αñ╣ αñ╣αÑï αñÜαÑüαñòαñ╛ αñ╣αÑêαÑñ αñòαñ«αñ£αÑïαñ░ αñ╣αÑï αñÜαÑüαñòαñ╛ αñ╣αÑêαÑñ αñêαñ░αñ╛αñ¿ αñòαÑï αñ¡αñ░αñ¬αñ╛αñê [αñ╕αñéαñùαÑÇαññ] αñòαÑÇ αñ¿αñ╣αÑÇαñé αñ«αñ┐αñ▓αÑçαñùαÑÇ αñ░αñòαñ«αÑñ\n1:01\n1 minute, 1 second\nαñæαñ»αñ▓ αñ░αñ┐αñ½αñ╛αñçαñ¿αñ░αÑÇ αñ¬αñ░ αñ»αÑéαñòαÑìαñ░αÑçαñ¿ αñòαÑç αñ╣αñ«αñ▓αÑç αñòαñ╛ αñ░αÑéαñ╕ αñ¿αÑç αñªαñ┐αñ»αñ╛ αñ£αñ╡αñ╛αñ¼αÑñ αñûαñ╛αñ░αñòαÑÇαñ¼ αñöαñ░ αñåαñ╕αñ¬αñ╛αñ╕ αñòαÑç αñçαñ▓αñ╛αñòαÑïαñé αñ«αÑçαñé αñ░αñ╛αññ αñ¡αñ░ αñ¼αñ░αñ╕αñ╛αñÅ αñ¼αñ«αÑñ 40 αñ░αñ┐αñ╣αñ╛αñçαñ╢αÑÇ αñçαñ«αñ╛αñ░αññαÑïαñé\n1:09\n1 minute, 9 seconds\nαñòαÑï αñ¬αñ╣αÑüαñéαñÜαñ╛ αñ¿αÑüαñòαñ╕αñ╛αñ¿αÑñ αñƒαÑìαñ░αñò αñ¬αñ╛αñ░αÑìαñòαñ┐αñéαñù αñÅαñ░αñ┐αñ»αñ╛ αñ«αÑçαñé αñ▓αñùαÑÇ αñ¡αÑÇαñ╖αñú αñåαñùαÑñ\n1:14\n1 minute, 14 seconds\nαñ░αÑéαñ╕, αñ»αÑéαñòαÑìαñ░αÑçαñ¿ αñ£αñéαñù αñòαÑÇ αñåαñù αñ«αÑçαñé αñÿαÑÇ αñíαñ╛αñ▓αÑçαñéαñùαÑç αñ»αÑéαñ░αÑïαñ¬αÑÇαñ» αñªαÑçαñ╢αÑñ αñ»αÑéαñòαÑìαñ░αÑçαñ¿ αñòαÑï αñªαÑçαñéαñùαÑç αñòαñ░αÑÇαñ¼ 36,000 αñòαñ░αÑïαñíαñ╝ αñòαÑç αñíαÑìαñ░αÑïαñ¿αÑñ [αñ╕αñéαñùαÑÇαññ] αñ¬αÑçαñƒαÑìαñ░αñ┐αñ»αñƒ, αñ«αñ┐αñ╕αñ╛αñçαñ▓ αñöαñ░ αññαÑïαñ¬ αñòαÑç αñùαÑïαñ▓αÑçαÑñ αñ»αÑéαñòαÑìαñ░αÑçαñ¿ αñíαñ┐αñ½αÑçαñéαñ╕\n1:22\n1 minute, 22 seconds\nαñòαñ╛αñéαñƒαÑçαñòαÑìαñƒ αñùαÑìαñ░αÑüαñ¬ αñòαñ╛ αñ╣αñ┐αñ╕αÑìαñ╕αñ╛ αñ╣αÑê αñçαñéαñùαÑìαñ▓αÑêαñéαñí αñöαñ░ αñ£αñ░αÑìαñ«αñ¿αÑÇ αñ╕αñ«αÑçαññ αñÅαñò αñªαñ░αÑìαñ£αñ¿ αñªαÑçαñ╢αÑñ\n1:28\n1 minute, 28 seconds\nαñ¼αñ╛αñ▓αÑìαñƒαñ┐αñò αñ╕αñ╛αñùαñ░ αñ«αÑçαñé αñ¿αñ╛αñƒαÑï αñªαÑçαñ╢αÑïαñé αñ¿αÑç αñòαñ┐αñ»αñ╛ αñ╕αÑêαñ¿αÑìαñ» αñàαñ¡αÑìαñ»αñ╛αñ╕αÑñ 20 αñ¿αÑîαñ╕αÑêαñ¿αñ┐αñòαÑïαñé αñ¿αÑîαñ╕αÑêαñ¿αñ┐αñò αñ£αñ╣αñ╛αñ£αÑïαñé αñòαñ╛ αñ½αÑëαñ░αÑìαñ«αÑçαñ╢αñ¿ αñªαñ┐αñûαñ╛αñ»αñ╛ αñùαñ»αñ╛αÑñ αñàαñ«αÑçαñ░αñ┐αñòαñ╛, αñ»αÑéαñòαÑç, αñ½αÑìαñ░αñ╛αñéαñ╕, αñçαñƒαñ▓αÑÇ [αñ╕αñéαñùαÑÇαññ] αñ╕αñ«αÑçαññ αñòαÑüαñ▓ 15 αñªαÑçαñ╢αÑïαñé αñ¿αÑç αñ▓αñ┐αñ»αñ╛ αñ╣αñ┐αñ╕αÑìαñ╕αñ╛αÑñ\n1:40\n1 minute, 40 seconds\nαñ░αñ╛αñ╖αÑìαñƒαÑìαñ░αñ¬αññαñ┐ αñƒαÑìαñ░αñéαñ¬ αñ¬αñ░ αñ¡αñíαñ╝αñòαÑÇ αñçαñƒαñ▓αÑÇ αñòαÑç αñ¬αÑìαñ░αñºαñ╛αñ¿αñ«αñéαññαÑìαñ░αÑÇ αñ£αÑëαñ░αÑìαñ£αñ┐αñ»αñ╛ αñ«αÑçαñ▓αÑïαñ¿αÑÇαÑñ αñƒαÑìαñ░αñéαñ¬ αñòαÑç αñ¼αñ»αñ╛αñ¿ αñòαÑï αñ«αñ¿αñùαñóαñ╝αñéαññ αñ¼αññαñ╛αñ»αñ╛αÑñ αñƒαÑìαñ░αñéαñ¬ αñ¿αÑç αñòαñ╣αñ╛ αñÑαñ╛ αñ«αÑçαñ▓αÑïαñ¿αÑÇ αñ¿αÑç αñ╕αñ╛αñÑ αñ«αÑçαñé αññαñ╕αÑìαñ╡αÑÇαñ░ αñûαñ┐αñéαñÜαñ╡αñ╛αñ¿αÑç αñòαÑç αñ▓αñ┐αñÅ αñ«αñ╛αñéαñùαÑÇ αñÑαÑÇ αñ¡αÑÇαñûαÑñ\n1:51\n1 minute, 51 seconds\nαñ¬αÑÇαñô αñ£αÑçαñòαÑç αñ«αÑçαñé αñ¬αñ╛αñòαñ┐αñ╕αÑìαññαñ╛αñ¿αÑÇ αñ░αÑçαñéαñ£αñ░αÑìαñ╕ αñ¿αÑç αñ½αñ┐αñ░ αñ▓αÑïαñùαÑïαñé αñ¬αñ░ αñòαñ╣αñ░ αñ¼αñ░αñ¬αñ╛αñ»αñ╛αÑñ αñàαñéαñºαñ╛αñºαÑüαñéαñº αñùαÑïαñ▓αñ┐αñ»αñ╛αñé αñ¼αñ░αñ╕αñ╛αñêαÑñ αñ╣αñ«αñ▓αÑç αñ«αÑçαñé αñªαÑï αñ▓αÑïαñùαÑïαñé αñòαÑÇ αñ«αÑîαññ, αñåαñá αñÿαñ╛αñ»αñ▓αÑñ αñùαÑïαñ▓αÑÇαñ¼αñ╛αñ░αÑÇ αñ«αÑçαñé αñàαñ¼ αññαñò 58 αñ¬αÑìαñ░αñªαñ░αÑìαñ╢αñ¿αñòαñ╛αñ░αñ┐αñ»αÑïαñé [αñ╕αñéαñùαÑÇαññ] αñòαÑÇ αñ£αñ╛αñ¿ αñùαñêαÑñ\n2:03\n2 minutes, 3 seconds\nαñ¬αñ╢αÑìαñÜαñ┐αñ« αñ¼αñéαñùαñ╛αñ▓ αñ«αÑçαñé αññαÑÇαñ¿ αñ»αÑüαñªαÑìαñº αñ¬αÑïαññ, αñ¿αÑî αñ╕αÑçαñ¿αñ╛ [αñ╕αñéαñùαÑÇαññ] αñ«αÑçαñé αñ╣αÑïαñéαñùαÑç αñ╢αñ╛αñ«αñ┐αñ▓αÑñ 21 αñ£αÑéαñ¿ αñòαÑï αñªαÑéαñ¿αñ╛αñùαñ┐αñ░αÑÇ, αñ╕αñéαñ╢αÑïαñºαñò αñöαñ░ αñàαñùαÑìαñ░αÑïαññ αñ╣αÑïαñéαñùαÑç αñòαñ«αÑÇαñ╢αñ¿αÑñ\n2:11\n2 minutes, 11 seconds\nαñ¬αÑÇαñÅαñ« αñ«αÑïαñªαÑÇ αñ¡αÑÇ αñòαñ╛αñ░αÑìαñ»αñòαÑìαñ░αñ« αñ«αÑçαñé αñ╣αÑïαñéαñùαÑç αñ╢αñ╛αñ«αñ┐αñ▓αÑñ\n2:15\n2 minutes, 15 seconds\nαñàαñ¡αñ┐αñ╖αÑçαñò αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñ¿αÑç αñ▓αÑïαñòαñ╕αñ¡αñ╛ αñ╕αÑìαñ¬αÑÇαñòαñ░ αñôαñ« [αñ╕αñéαñùαÑÇαññ] αñ¼αñ┐αñ░αñ▓αñ╛ αñ╕αÑç αñòαÑÇ αñ«αÑüαñ▓αñ╛αñòαñ╛αññαÑñ αñ¼αñ╛αñùαÑÇ αñ╕αñ╛αñéαñ╕αñªαÑïαñé αñòαÑï αñàαñ▓αñù αñùαÑüαñƒ αñòαÑÇ αñ«αñ╛αñ¿αÑìαñ»αññαñ╛ αñªαÑçαñ¿αÑç αñ¬αñ░ αñ£αññαñ╛αñ»αñ╛ αñÉαññαñ░αñ╛αñ£αÑñ 20 αñàαñ▓αñù-αñàαñ▓αñù αñ»αñ╛αñÜαñ┐αñòαñ╛αñÅαñé αñªαÑÇαÑñ\n2:23\n2 minutes, 23 seconds\nαñ«αÑüαñ▓αñ╛αñòαñ╛αññ αñòαÑç αñªαÑîαñ░αñ╛αñ¿ αñòαñ▓αÑìαñ»αñ╛αñú αñ¼αñ¿αñ░αÑìαñ£αÑÇ αñöαñ░ αñ«αñ╣αñ╡αñ╛ αñ«αÑïαñ╣αñ┐αññαÑìαñ░αñ╛ αñ¡αÑÇ αñÑαÑç αñ«αÑîαñ£αÑéαñªαÑñ\n2:29\n2 minutes, 29 seconds\nαñƒαÑÇαñÅαñ«αñ╕αÑÇ αñòαÑç 20 αñ¼αñ╛αñùαÑÇ αñ╕αñ╛αñéαñ╕αñªαÑïαñé αñòαÑç αñ«αñ╛αñ«αñ▓αÑç αñ¬αñ░ αñ╕αÑìαñ¬αÑÇαñòαñ░ αñ£αñ▓αÑìαñª αñòαñ░αÑçαñéαñùαÑç αñ½αÑêαñ╕αñ▓αñ╛αÑñ αñ╕αÑéαññαÑìαñ░αÑïαñé αñ╕αÑç αñûαñ¼αñ░αÑñ αñ╕αñªαñ¿ αñ«αÑçαñé αñàαñ▓αñù αñ¼αÑêαñáαñ¿αÑç [αñ╕αñéαñùαÑÇαññ] αñöαñ░ αñÅαñ¿αñ╕αÑÇαñ¬αÑÇαñåαñê αñòαÑç αñ╕αñªαñ╕αÑìαñ» αñòαÑç αññαÑîαñ░ αñ¬αñ░ αñ«αñ╛αñ¿αÑìαñ»αññαñ╛ αñªαÑçαñ¿αÑç αñòαÑÇ αñ»αñ╛αñÜαñ┐αñòαñ╛ αñ¬αñ░ αñ£αñ▓αÑìαñª αñ▓αÑçαñéαñùαÑç αñ¿αñ┐αñ░αÑìαñúαñ»αÑñ\n2:42\n2 minutes, 42 seconds\nαñ¬αñ╢αÑìαñÜαñ┐αñ« αñ¼αñéαñùαñ╛αñ▓ αñ«αÑçαñé αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ¿αÑçαññαñ╛αñôαñé αñ¬αñ░ αñàαñéαñíαñ╛ αñ½αÑçαñéαñò αñ╣αñ«αñ▓αñ╛ αñ£αñ╛αñ░αÑÇ αñ╣αÑêαÑñ αñåαñ╕αñ¿αñ╕αÑïαñ▓ αñ«αÑçαñé αñòαÑïαñ░αÑìαñƒ αñ«αÑçαñé αñ¬αÑçαñ╢αÑÇ αñòαÑç αñ▓αñ┐αñÅ αñ▓αÑç αñ£αñ╛αñ¿αÑç αñòαÑç αñªαÑîαñ░αñ╛αñ¿ αñƒαÑÇαñÅαñ«αñ╕αÑÇ αñ¿αÑçαññαñ╛ αñ¡αÑïαñ▓αñ╛ αñ╕αñ┐αñéαñ╣ αñ¬αñ░ αñ▓αÑïαñùαÑïαñé αñ¿αÑç αñàαñéαñíαÑç αñ½αÑçαñéαñòαÑçαÑñ αñ╣αÑçαñ▓αñ«αÑçαñƒ αñ¬αñ╣αñ¿αñ╛αñòαñ░ αñ¬αÑüαñ▓αñ┐αñ╕ αñ¿αÑç αñ¼αñÜαñ╛αñ»αñ╛αÑñ\n2:56\n2 minutes, 56 seconds\nαñ¬αÑÇαñÅαñ« αñ«αÑïαñªαÑÇ αñ¿αÑç αñ¬αÑìαñ░αñºαñ╛αñ¿αñ«αñéαññαÑìαñ░αÑÇ αñ╡αñ┐αñòαñ╕αñ┐αññ αñ¡αñ╛αñ░αññ αñ░αÑïαñ£αñùαñ╛αñ░ αñ»αÑïαñ£αñ¿αñ╛ αñòαÑç αññαñ╣αññ αñ▓αñùαñ¡αñù Γé╣2400 αñòαñ░αÑïαñíαñ╝ αñòαÑÇ αñ¬αÑìαñ░αÑïαññαÑìαñ╕αñ╛αñ╣αñ¿ αñ░αñ╛αñ╢αñ┐ αñ╡αñ┐αññαñ░αñ┐αññ αñòαÑÇαÑñ αñ▓αñ╛αñ¡αñ╛αñ░αÑìαñÑαñ┐αñ»αÑïαñé αñ╕αÑç αñòαñ┐αñ»αñ╛ αñ╕αñéαñ╡αñ╛αñªαÑñ\n3:07\n3 minutes, 7 seconds\nαñ╣αñ¿αÑüαñ«αñ╛αñ¿αñùαñóαñ╝αÑÇ αñ«αÑçαñé αñ╣αñ╛αñ£αñ┐αñ░αÑÇ αñ▓αñùαñ╛αñ¿αÑç αñòαÑç αñ¼αñ╛αñª αñ╕αÑÇαñÅαñ« αñ»αÑïαñùαÑÇ αñ¿αÑç αñàαñ»αÑïαñºαÑìαñ»αñ╛ αñ«αñéαñªαñ┐αñ░ αñ«αÑçαñé αñòαñ┐αñÅ αñ╢αÑìαñ░αÑÇ αñ░αñ╛αñ« αñòαÑç αñªαñ░αÑìαñ╢αñ¿αÑñ αñ░αñ╛αñ«αñ▓αñ▓αñ╛ αñòαÑÇ αñåαñ░αññαÑÇ αñëαññαñ╛αñ░αÑÇαÑñ αñÜαñéαñ¬αññ αñ░αñ╛αñ» αñòαÑï αñòαñ╛αñ░αÑìαñ»αñòαÑìαñ░αñ« αñ╕αÑç αñ░αñûαñ╛ αñùαñ»αñ╛ αñªαÑéαñ░αÑñ\n3:17\n3 minutes, 17 seconds\nαñàαñ»αÑïαñºαÑìαñ»αñ╛ αñ«αÑçαñé αñÜαñóαñ╝αñ╛αñ╡αñ╛ αñÜαÑïαñ░αÑÇ αñ╡αñ┐αñ╡αñ╛αñª αñ¬αñ░ αñ¼αÑïαñ▓αÑç αñ╕αÑÇαñÅαñ« αñ»αÑïαñùαÑÇαÑñ αñÅαñ╕αñåαñêαñƒαÑÇ αñ£αñ╛αñéαñÜ αñ«αÑçαñé αñ╣αÑïαñùαñ╛ αñªαÑéαñº αñòαñ╛ αñªαÑéαñº αñ¬αñ╛αñ¿αÑÇ [αñ╕αñéαñùαÑÇαññ] αñòαñ╛ αñ¬αñ╛αñ¿αÑÇαÑñ αñòαÑïαñê αñ¡αÑÇ αñªαÑïαñ╖αÑÇ αñ¿αñ╣αÑÇαñé αñ¼αñÜαÑçαñùαñ╛αÑñ\n3:26\n3 minutes, 26 seconds\nαñëαññαÑìαññαñ░ αñ¬αÑìαñ░αñªαÑçαñ╢ αñòαÑç αñ¼αñ╛αñùαñ¬αññ [αñ╕αñéαñùαÑÇαññ] αñ«αÑçαñé αñ«αñ╣αñéαñùαñ╛αñê αñ¡αÑìαñ░αñ╖αÑìαñƒαñ╛αñÜαñ╛αñ░ αñòαÑï αñ▓αÑçαñòαñ░ αñ╕αñ«αñ╛αñ£αñ╡αñ╛αñªαÑÇ αñ¬αñ╛αñ░αÑìαñƒαÑÇ αñòαÑç αñ¿αÑçαññαñ╛αñôαñé αñ¿αÑç αñ¼αÑêαñ▓αñùαñ╛αñíαñ╝αÑÇ αñ¬αñ░ αñ╕αñ╡αñ╛αñ░ αñ╣αÑïαñòαñ░ αñòαñ┐αñ»αñ╛ αñ¬αÑìαñ░αñªαñ░αÑìαñ╢αñ¿αÑñ αñ░αñ╛αñ£αÑìαñ»αñ¬αñ╛αñ▓ αñòαÑç αñ¿αñ╛αñ« αñÅαñ╕αñíαÑÇαñÅαñ« αñòαÑï αñ╕αÑîαñéαñ¬αñ╛ αñ£αÑìαñ₧αñ╛αñ¬αñ¿αÑñ\n3:38\n3 minutes, 38 seconds\nαñ¼αñ╛αñùαñ¬αññ αñòαÑç αñ¼αñíαñ╝αÑîαññ αñ«αÑçαñé αñ«αñ╣αñ┐αñ▓αñ╛αñôαñé αñ¿αÑç αñ«αñ╕αÑìαñ£αñ┐αñª αñòαÑç αñ¼αñ╛αñ╣αñ░ αñªαñ┐αñ»αñ╛ αñºαñ░αñ¿αñ╛αÑñ αñ╕αÑÇαñÅαñ« αñ»αÑïαñùαÑÇ αñ╕αÑç αñ▓αñùαñ╛αñê αñ╕αÑüαñ░αñòαÑìαñ╖αñ╛ αñòαÑÇ αñùαÑüαñ╣αñ╛αñ░αÑñ αñ«αñ╕αÑìαñ£αñ┐αñª αñ¿αñ┐αñ░αÑìαñ«αñ╛αñú αñòαÑï αñ▓αÑçαñòαñ░ αñ¡αÑÇ αñëαñáαñ╛αñÅ αñ╕αñ╡αñ╛αñ▓αÑñ [αñ╕αñéαñùαÑÇαññ]\n3:50\n3 minutes, 50 seconds\n[αñ╕αñéαñùαÑÇαññ]\n3:52\n3 minutes, 52 seconds\nαñÅαñ¼αÑÇαñ¬αÑÇ αñ¿αÑìαñ»αÑéαñ£αñ╝ αñåαñ¬αñòαÑï αñ░αñûαÑç αñåαñùαÑçαÑñ	f	2026-06-19 21:52:53.27462
\.


--
-- Data for Name: districts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.districts (id, state_id, name) FROM stdin;
133	42	Bahraich
134	77	Nalbari
109	15	North Delhi
136	81	Kishanganj
137	42	Chitrakoot
110	15	North East Delhi
107	42	Moradabad
140	42	Saharanpur
141	42	Fatehpur
142	42	Gautam Buddh Nagar
143	42	Mathura
144	42	Varanasi
145	42	Muzaffarnagar
146	177	Bhiwani
147	43	Ujjain
12	15	NCR
148	161	Nainital
101	42	Balrampur
16	19	Bengaluru
35	38	Murshidabad
36	39	Bikaner
38	15	Central Delhi
39	43	Bhopal
40	45	Patiala
43	48	Ranga Reddy
44	43	Panna
45	14	Nashik
59	38	Hooghly
60	38	Paschim Bardhaman
63	15	North West Delhi
65	14	Chhatrapati Sambhaji Nagar
66	14	Palghar
67	14	Pune
68	14	Jalna
69	79	Chamba
70	39	Churu
71	81	Nalanda
72	14	Satara
74	40	Poonch
15	15	New Delhi
41	45	Ludhiana
96	42	Bareilly
97	110	Surat
99	112	Daman
100	114	Agartala
102	42	Sambhal
91	38	Kolkata
61	15	South Delhi
106	81	Muzaffarpur
11	14	Mumbai
111	42	Baghpat
104	15	South West Delhi
113	42	Agra
115	38	North 24 Parganas
93	14	Beed
117	42	Prayagraj
37	40	Rajouri
114	42	Kanpur
42	42	Ghaziabad
122	39	Baran
123	42	Jhansi
124	42	Kanpur Dehat
125	42	Ghazipur
126	42	Lucknow
127	110	Ahmedabad
128	119	Vellore
129	43	Mauganj
130	161	Rudraprayag
131	42	Mahoba
132	109	Wayanad
\.


--
-- Data for Name: news_all_2026_04; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2026_04 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2026_05; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2026_05 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
98	Action Against Bangladeshi Infiltrators in West Bengal	Authorities have detained several Bangladeshi nationals in Murshidabad and Malda, West Bengal. The individuals are currently being held in designated holding centers following a crackdown on illegal infiltration.	Crime	State	7	Negative	MODERATE	NONE	f	38	35	["infiltration", "border_security", "holding_center"]	{"people": null, "organizations": ["Border Security Force"], "monetary_values": null}	{"broadcast_date": "2024-06-16", "original_timestamp": "00:02"}	\N	\N	\N	\N	\N	[]	2026-05-26	2026-05-27 03:13:48.690197
99	Central Government Forms High-Level Committee on Demographic Change	Union Home Minister Amit Shah announced the formation of a high-level committee to review demographic shifts in India. The committee will analyze population changes and provide a comprehensive report.	Politics	National	8	Neutral	NONE	NONE	t	\N	\N	["demographics", "population_policy", "home_ministry"]	{"people": ["Amit Shah"], "organizations": ["Ministry of Home Affairs"], "monetary_values": null}	{"broadcast_date": "2024-06-16", "original_timestamp": "00:11"}	\N	\N	\N	\N	\N	[]	2026-05-26	2026-05-27 03:13:49.912915
100	Amit Shah Praises BSF for Operation Sindoor in Bikaner	Home Minister Amit Shah met with BSF jawans in Bikaner, Rajasthan, to commend their efforts. He specifically praised 'Operation Sindoor' for providing a strong response to cross-border challenges from Pakistan.	Geopolitics	National	7	Positive	NONE	NONE	f	39	36	["BSF", "border_security", "Operation_Sindoor"]	{"people": ["Amit Shah"], "organizations": ["Border Security Force"], "monetary_values": null}	{"broadcast_date": "2024-06-16", "original_timestamp": "00:22"}	\N	\N	\N	\N	\N	[]	2026-05-26	2026-05-27 03:13:50.926643
101	Anti-Terror Search Operation Launched in Rajouri	Security forces have initiated a massive anti-terror search operation in the forest areas of Rajouri, Jammu and Kashmir. The operation involves vehicle checks and cordoning off areas following reports of intermittent firing.	Emergency	District	8	Negative	EXTREME	WAR_CONFLICT	f	40	37	["counter_terrorism", "search_operation", "security_forces"]	{"people": null, "organizations": ["Indian Army", "Jammu and Kashmir Police"], "monetary_values": null}	{"broadcast_date": "2024-06-16", "original_timestamp": "00:34"}	\N	\N	\N	\N	\N	[]	2026-05-26	2026-05-27 03:13:51.938455
102	Education Ministry Intervenes to Fix CBSE Website Payment Issues	The Education Minister held a meeting with officials from four government banks to address technical glitches on the CBSE website. The focus was on improving the digital payment system for students and parents.	Infrastructure	National	6	Positive	NONE	NONE	t	\N	\N	["CBSE", "digital_payments", "education_ministry"]	{"people": null, "organizations": ["Ministry of Education", "CBSE"], "monetary_values": null}	{"broadcast_date": "2024-06-16", "original_timestamp": "00:54"}	\N	\N	\N	\N	\N	[]	2026-05-26	2026-05-27 03:13:52.94504
103	Delhi Police Conduct Flag March Ahead of Bakrid	Delhi Police, led by DCP Central, conducted a flag march in sensitive areas of the capital to ensure security for the upcoming Bakrid festival. Security measures have been intensified to maintain peace.	Politics	Local	5	Neutral	NONE	NONE	f	15	38	["Bakrid", "security", "flag_march"]	{"people": null, "organizations": ["Delhi Police"], "monetary_values": null}	{"broadcast_date": "2024-06-16", "original_timestamp": "01:06"}	\N	\N	\N	\N	\N	[]	2026-05-26	2026-05-27 03:13:53.952963
104	UP CM Yogi Adityanath Criticizes Opposition Over Power Crisis	Uttar Pradesh CM Yogi Adityanath took a swipe at Akhilesh Yadav regarding the state's electricity issues, claiming the previous government failed to build infrastructure. He assured that the current government is working on a permanent solution.	Politics	State	6	Negative	NONE	NONE	f	42	\N	["power_crisis", "political_rivalry", "electricity"]	{"people": ["Yogi Adityanath", "Akhilesh Yadav"], "organizations": ["Uttar Pradesh Government"], "monetary_values": null}	{"broadcast_date": "2024-06-16", "original_timestamp": "01:15"}	\N	\N	\N	\N	\N	[]	2026-05-26	2026-05-27 03:13:54.965946
105	CBI Intensifies Investigation into Tusha Case in Bhopal	The CBI has accelerated its probe into the Tusha case in Bhopal, recording statements from family members. Interrogations of suspects Samarth and Giribala Singh are expected to follow soon.	Crime	District	7	Neutral	EXTREME	NONE	f	43	39	["CBI", "investigation", "Tusha_case"]	{"people": ["Samarth", "Giribala Singh"], "organizations": ["CBI"], "monetary_values": null}	{"broadcast_date": "2024-06-16", "original_timestamp": "01:27"}	\N	\N	\N	\N	\N	[]	2026-05-26	2026-05-27 03:13:55.972826
106	Quad Foreign Ministers Meet in Delhi to Discuss Global Security	Foreign Ministers from Quad nations met in Delhi to discuss the West Asia crisis, Indo-Pacific stability, and counter-terrorism. The nations reaffirmed their commitment to a united front against global terrorism.	Geopolitics	International	9	Positive	NONE	NONE	t	15	\N	["Quad", "Indo-Pacific", "counter_terrorism"]	{"people": null, "organizations": ["Quad"], "monetary_values": null}	{"broadcast_date": "2024-06-16", "original_timestamp": "01:37"}	\N	\N	\N	\N	\N	[]	2026-05-26	2026-05-27 03:13:56.979879
107	Violence and Lathi Charge During Municipal Polls in Patiala	Clashes broke out during the Samana Municipal Council voting in Patiala, Punjab, leading to a chaotic situation. Police were forced to use a lathi charge to disperse the crowd and restore order.	Emergency	District	7	Negative	MODERATE	CIVIL_UNREST	f	45	40	["election_violence", "lathi_charge", "municipal_polls"]	{"people": null, "organizations": ["Samana Municipal Council", "Punjab Police"], "monetary_values": null}	{"broadcast_date": "2024-06-16", "original_timestamp": "01:48"}	\N	\N	\N	\N	\N	[]	2026-05-26	2026-05-27 03:13:57.995983
108	Congress Candidate Attacked and Injured in Ludhiana	Jagdev Singh, a Congress candidate, was seriously injured after being attacked in Raikot, Ludhiana. He is currently undergoing treatment at a hospital as police investigate the assault.	Crime	District	8	Negative	EXTREME	NONE	f	45	41	["political_violence", "assault", "Congress"]	{"people": ["Jagdev Singh"], "organizations": ["Indian National Congress"], "monetary_values": null}	{"broadcast_date": "2024-06-16", "original_timestamp": "01:57"}	\N	\N	\N	\N	\N	[]	2026-05-26	2026-05-27 03:13:59.002874
109	Fire Breaks Out in Ghaziabad High-Rise Building	A major fire erupted on the top floor of a high-rise residential building in Ghaziabad, causing panic among residents. Firefighters managed to bring the blaze under control after a difficult operation.	Emergency	Local	6	Negative	NONE	NONE	f	42	42	["fire_accident", "high_rise", "fire_safety"]	{"people": null, "organizations": ["Fire Brigade"], "monetary_values": null}	{"broadcast_date": "2024-06-16", "original_timestamp": "02:06"}	\N	\N	\N	\N	\N	[]	2026-05-26	2026-05-27 03:14:00.015145
110	Air India Bus Catches Fire in Telangana Due to Short Circuit	An Air India bus caught fire in the Ranga Reddy district of Telangana, reportedly due to a short circuit. All passengers were safely evacuated, and no injuries were reported.	Emergency	Local	5	Negative	NONE	NONE	f	48	43	["Air_India", "bus_fire", "short_circuit"]	{"people": null, "organizations": ["Air India"], "monetary_values": null}	{"broadcast_date": "2024-06-16", "original_timestamp": "02:16"}	\N	\N	\N	\N	\N	[]	2026-05-26	2026-05-27 03:14:01.031503
111	Five Laborers Killed in Well Collapse in Panna	A tragic accident in Panna, Madhya Pradesh, resulted in the deaths of five laborers after a portion of a well under construction collapsed. The incident has caused widespread grief in the local community.	Emergency	District	8	Negative	NONE	NONE	f	43	44	["laborer_deaths", "well_collapse", "accident"]	{"people": null, "organizations": null, "monetary_values": null}	{"broadcast_date": "2024-06-16", "original_timestamp": "02:26"}	\N	\N	\N	\N	\N	[]	2026-05-26	2026-05-27 03:14:02.040656
112	Onion Farmers Protest Price Drop in Nashik	Farmers in Nashik, Maharashtra, staged a protest and blocked highways due to a sharp decline in onion prices. They are demanding government intervention to address the economic crisis facing growers.	Economy	State	7	Negative	NONE	CIVIL_UNREST	f	14	45	["farmer_protest", "onion_prices", "highway_jam"]	{"people": null, "organizations": null, "monetary_values": null}	{"broadcast_date": "2024-06-16", "original_timestamp": "02:37"}	\N	\N	\N	\N	\N	[]	2026-05-26	2026-05-27 03:14:03.053144
113	Shivraj Singh Chouhan Releases Book on 35-Year Journey with PM Modi	Union Minister Shivraj Singh Chouhan released his book 'Khitaab Apnapan' in Delhi, detailing his 35-year professional relationship with PM Narendra Modi. He described the Prime Minister as a 'Karmayogi'.	Politics	National	4	Positive	NONE	NONE	t	15	\N	["book_release", "Shivraj_Singh_Chouhan", "Narendra_Modi"]	{"people": ["Shivraj Singh Chouhan", "Narendra Modi"], "organizations": null, "monetary_values": null}	{"broadcast_date": "2024-06-16", "original_timestamp": "02:50"}	\N	\N	\N	\N	\N	[]	2026-05-26	2026-05-27 03:14:04.064261
114	Action Against Bangladeshi Infiltrators in West Bengal	Authorities have detained several Bangladeshi nationals in Murshidabad and Malda for illegal entry. They are currently being held in designated holding centers following a major crackdown.	Crime	State	7	Negative	MODERATE	NONE	f	38	35	["infiltration", "border_security", "West_Bengal"]	{"people": null, "organizations": ["Border Security Force"], "monetary_values": null}	{"broadcast_date": "2024-06-16", "original_timestamp": "00:02"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:23:07.95684
115	High-Level Committee Formed to Review Demographic Changes	The Central Government has constituted a high-level committee to study demographic shifts in India. Home Minister Amit Shah stated the committee will review population changes and their implications.	Politics	National	8	Neutral	NONE	NONE	t	\N	\N	["demographics", "population_policy", "Amit_Shah"]	{"people": ["Amit Shah"], "organizations": ["Ministry of Home Affairs"], "monetary_values": null}	{"broadcast_date": "2024-06-16", "original_timestamp": "00:11"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:23:09.176688
116	Amit Shah Commends BSF for Operation Sindoor in Bikaner	Home Minister Amit Shah visited BSF personnel in Bikaner to praise their performance in Operation Sindoor. He emphasized that the forces have provided a strong response to Pakistan's activities.	Geopolitics	National	7	Positive	NONE	NONE	f	39	36	["BSF", "border_security", "Operation_Sindoor"]	{"people": ["Amit Shah"], "organizations": ["Border Security Force"], "monetary_values": null}	{"broadcast_date": "2024-06-16", "original_timestamp": "00:22"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:23:10.249783
117	Anti-Terror Operations Intensify in Rajouri	Security forces have launched a massive search operation in the forested areas of Rajouri following intermittent firing. Authorities are conducting strict vehicle checks and surveillance in the region.	Emergency	District	8	Negative	EXTREME	CIVIL_UNREST	f	40	37	["terrorism", "counter_insurgency", "Rajouri"]	{"people": null, "organizations": ["Indian Army", "Jammu and Kashmir Police"], "monetary_values": null}	{"broadcast_date": "2024-06-16", "original_timestamp": "00:34"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:23:11.262139
118	Government Intervenes Over CBSE Website Payment Issues	The Education Minister held a meeting with officials from four public sector banks to address technical glitches on the CBSE website. The discussion focused on improving the digital payment system for students.	Infrastructure	National	6	Neutral	NONE	NONE	t	\N	\N	["CBSE", "digital_payments", "education_ministry"]	{"people": null, "organizations": ["CBSE", "Ministry of Education"], "monetary_values": null}	{"broadcast_date": "2024-06-16", "original_timestamp": "00:54"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:23:12.338478
119	Delhi Police Conduct Flag March Ahead of Bakrid	A flag march was led by the DCP Central in Delhi to ensure security and peace during the upcoming Bakrid festival. Police reviewed security arrangements in sensitive areas of the city.	Politics	Local	5	Neutral	NONE	NONE	f	15	38	["Bakrid", "security", "Delhi_Police"]	{"people": null, "organizations": ["Delhi Police"], "monetary_values": null}	{"broadcast_date": "2024-06-16", "original_timestamp": "01:06"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:23:13.354103
120	CM Yogi Adityanath Addresses Power Crisis in Uttar Pradesh	Chief Minister Yogi Adityanath criticized the opposition regarding electricity issues, claiming previous administrations neglected infrastructure. He assured that the government is working on a swift resolution to the current power shortage.	Infrastructure	State	6	Negative	NONE	NONE	f	42	\N	["power_crisis", "electricity", "Yogi_Adityanath"]	{"people": ["Yogi Adityanath", "Akhilesh Yadav"], "organizations": ["UP Government"], "monetary_values": null}	{"broadcast_date": "2024-06-16", "original_timestamp": "01:15"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:23:14.426153
121	CBI Intensifies Investigation into Tusha Case in Bhopal	The Central Bureau of Investigation has accelerated its probe into the Tusha case by recording statements from family members. Suspects Samarth and Giribala Singh are scheduled for further questioning.	Crime	District	7	Neutral	EXTREME	NONE	f	43	39	["CBI", "investigation", "Bhopal"]	{"people": ["Samarth Singh", "Giribala Singh"], "organizations": ["CBI"], "monetary_values": null}	{"broadcast_date": "2024-06-16", "original_timestamp": "01:27"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:23:15.43898
122	Quad Foreign Ministers Meet in Delhi to Discuss Global Security	Foreign Ministers from Quad nations met in Delhi to discuss the West Asia crisis, Indo-Pacific stability, and counter-terrorism. The member nations reaffirmed their united stance against global terrorism.	Geopolitics	International	9	Positive	NONE	NONE	t	15	15	["Quad", "diplomacy", "counter_terrorism"]	{"people": null, "organizations": ["Quad"], "monetary_values": null}	{"broadcast_date": "2024-06-16", "original_timestamp": "01:37"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:23:16.450834
123	Violence Erupts During Municipal Council Voting in Patiala	Clashes broke out during the Samana Municipal Council elections in Punjab, leading to a chaotic situation. Police resorted to a lathi charge to disperse the crowd and regain control.	Emergency	Local	6	Negative	MODERATE	CIVIL_UNREST	f	45	40	["election_violence", "Patiala", "lathi_charge"]	{"people": null, "organizations": ["Punjab Police"], "monetary_values": null}	{"broadcast_date": "2024-06-16", "original_timestamp": "01:48"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:23:17.466475
124	Congress Candidate Attacked During Elections in Ludhiana	Jagdev Singh, a Congress candidate, was seriously injured after being attacked in Raikot, Ludhiana. He is currently undergoing treatment at a local hospital as police investigate the assault.	Crime	Local	7	Negative	EXTREME	NONE	f	45	41	["political_violence", "Ludhiana", "Congress"]	{"people": ["Jagdev Singh"], "organizations": ["Indian National Congress"], "monetary_values": null}	{"broadcast_date": "2024-06-16", "original_timestamp": "01:57"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:23:18.541807
125	Fire Breaks Out in Ghaziabad High-Rise Building	A fire erupted on the top floor of a high-rise residential building in Ghaziabad, causing panic among residents. Firefighters managed to bring the blaze under control after a difficult operation.	Emergency	Local	5	Negative	NONE	NONE	f	42	42	["fire_accident", "Ghaziabad", "public_safety"]	{"people": null, "organizations": ["Fire Brigade"], "monetary_values": null}	{"broadcast_date": "2024-06-16", "original_timestamp": "02:06"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:23:19.605452
126	Air India Bus Catches Fire in Telangana	An Air India bus caught fire in the Ranga Reddy district of Telangana due to a suspected short circuit. All passengers were evacuated safely, and no injuries were reported.	Emergency	Local	5	Negative	NONE	NONE	f	48	43	["Air_India", "bus_fire", "short_circuit"]	{"people": null, "organizations": ["Air India"], "monetary_values": null}	{"broadcast_date": "2024-06-16", "original_timestamp": "02:16"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:23:20.65109
127	Five Laborers Killed in Well Collapse in Panna	A tragic accident in Panna, Madhya Pradesh, resulted in the deaths of five laborers when a portion of a well under construction collapsed. The incident has caused widespread mourning in the local village.	Emergency	District	7	Negative	NONE	NATURAL_DISASTER	f	43	44	["well_collapse", "laborer_deaths", "Panna"]	{"people": null, "organizations": null, "monetary_values": null}	{"broadcast_date": "2024-06-16", "original_timestamp": "02:26"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:23:21.72736
128	Onion Farmers Protest Price Crash in Nashik	Farmers in Nashik, Maharashtra, blocked highways to protest a significant drop in onion prices. The protesters are demanding government intervention to address the economic crisis facing onion growers.	Economy	State	7	Negative	NONE	NONE	f	14	45	["farmer_protest", "onion_prices", "Nashik"]	{"people": null, "organizations": null, "monetary_values": null}	{"broadcast_date": "2024-06-16", "original_timestamp": "02:37"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:23:22.741614
129	Shivraj Singh Chouhan Releases Book on 35-Year Journey with PM Modi	Union Minister Shivraj Singh Chouhan released his book 'Khitaab Apnapan' in Delhi, detailing his long-standing professional relationship with PM Narendra Modi. He described the Prime Minister as a 'Karmayogi' based on their 35 years of collaboration.	Politics	National	4	Positive	NONE	NONE	t	15	15	["book_release", "Shivraj_Singh_Chouhan", "Narendra_Modi"]	{"people": ["Shivraj Singh Chouhan", "Narendra Modi"], "organizations": ["Government of India"], "monetary_values": null}	{"broadcast_date": "2024-06-16", "original_timestamp": "02:50"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:23:23.8148
130	TMC MP Kalyan Banerjee Attacked in Hooghly	TMC MP Kalyan Banerjee faced an attack and 'chor-chor' slogans in Hooghly, West Bengal, while attempting to free party workers.	Politics	District	6	Negative	MODERATE	NONE	f	38	59	["TMC", "Political Violence", "West Bengal"]	{"people": ["Kalyan Banerjee"], "organizations": ["TMC"], "monetary_values": []}	{"broadcast_date": "2024-06-23", "original_timestamp": "00:02"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:25:12.288136
131	TMC MP Abhishek Banerjee Attacked in Salanpur; Five Arrested	TMC MP Abhishek Banerjee was attacked while visiting post-poll violence victims in Salanpur. Police have arrested five suspects in connection with the incident.	Politics	District	7	Negative	MODERATE	NONE	f	38	60	["Abhishek Banerjee", "Political Attack", "Post-Poll Violence"]	{"people": ["Abhishek Banerjee"], "organizations": ["TMC", "BJP"], "monetary_values": []}	{"broadcast_date": "2024-06-23", "original_timestamp": "00:14"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:25:13.401948
132	Mamata Banerjee Condemns Attack on Abhishek Banerjee	West Bengal CM Mamata Banerjee criticized the attack on Abhishek Banerjee, alleging that the BJP and police negligence could have led to a fatal outcome.	Politics	State	6	Negative	NONE	NONE	f	38	\N	["Mamata Banerjee", "Political Statement"]	{"people": ["Mamata Banerjee", "Abhishek Banerjee"], "organizations": ["BJP"], "monetary_values": []}	{"broadcast_date": "2024-06-23", "original_timestamp": "00:40"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:25:14.418991
133	Two Dead in Five-Story Building Collapse in Saket, Delhi	A five-story building collapsed in Saket, Delhi, resulting in two fatalities and ten rescues. CM Rekha Gupta visited the site and promised action against illegal constructions.	Emergency	Local	8	Negative	NONE	NATURAL_DISASTER	f	15	61	["Building Collapse", "Saket", "Rescue Operation"]	{"people": ["Rekha Gupta"], "organizations": [], "monetary_values": []}	{"broadcast_date": "2024-06-23", "original_timestamp": "00:51"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:25:15.447235
134	Murder Accused Asad Killed in Ghaziabad Encounter	Asad, the main accused in the Surya murder case, was killed during a police encounter in Ghaziabad. A police constable was injured during the exchange of fire.	Crime	District	8	Neutral	EXTREME	NONE	f	42	42	["Encounter", "Ghaziabad Police", "Criminal Justice"]	{"people": ["Asad"], "organizations": ["Uttar Pradesh Police"], "monetary_values": []}	{"broadcast_date": "2024-06-23", "original_timestamp": "01:15"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:25:16.526522
135	Massive Demolition Drive in Shalimar Bagh, Delhi	Following High Court orders, 157 houses are being demolished in Shalimar Bagh, Delhi. The area has been heavily secured by police forces.	Infrastructure	Local	7	Negative	NONE	NONE	f	15	63	["Bulldozer Action", "Demolition", "High Court Order"]	{"people": [], "organizations": ["Delhi High Court"], "monetary_values": []}	{"broadcast_date": "2024-06-23", "original_timestamp": "01:36"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:25:17.540338
136	Anti-Terror Operations Continue in Rajouri Forests	Security forces are conducting extensive search operations in the dense forests of Rajouri, Jammu and Kashmir, to track down terrorists.	Geopolitics	District	8	Neutral	EXTREME	WAR_CONFLICT	f	40	37	["Counter-Terrorism", "Rajouri", "Security Forces"]	{"people": [], "organizations": ["Indian Army", "Jammu and Kashmir Police"], "monetary_values": []}	{"broadcast_date": "2024-06-23", "original_timestamp": "01:48"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:25:18.553637
137	NIA Detains Suspect in Chhatrapati Sambhaji Nagar	The National Investigation Agency (NIA) detained an individual in Chhatrapati Sambhaji Nagar, Maharashtra, for suspected links to terrorist organizations.	Crime	District	8	Neutral	EXTREME	NONE	f	14	65	["NIA", "Terror Links", "Maharashtra"]	{"people": [], "organizations": ["NIA"], "monetary_values": []}	{"broadcast_date": "2024-06-23", "original_timestamp": "01:58"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:25:19.629044
138	Illegal Liquor Factory Busted in Vasai	Police and excise departments raided an illegal liquor factory in Vasai, Maharashtra, seizing goods worth over Γé╣1 lakh.	Crime	Local	5	Neutral	MODERATE	NONE	f	14	66	["Illegal Liquor", "Raid", "Excise Department"]	{"people": [], "organizations": ["Maharashtra Police"], "monetary_values": ["Γé╣1 Lakh"]}	{"broadcast_date": "2024-06-23", "original_timestamp": "02:12"}	\N	100000.00	INR	Lakh	Completed	["Alcohol"]	2026-05-31	2026-05-31 21:25:20.708663
139	Pune Hooch Tragedy Death Toll Rises to 23	The death toll in the Pune poisonous liquor case has reached 23. Authorities have arrested 52 individuals as raids continue against illegal alcohol.	Emergency	District	9	Negative	EXTREME	PUBLIC_HEALTH	f	14	67	["Hooch Tragedy", "Pune", "Illegal Liquor"]	{"people": [], "organizations": [], "monetary_values": []}	{"broadcast_date": "2024-06-23", "original_timestamp": "02:25"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:25:21.786644
140	Manoj Jarange Ends Hunger Strike in Jalna	Manoj Jarange ended his hunger strike in Jalna after reaching an agreement with the Maharashtra government regarding Maratha reservation issues.	Politics	State	7	Positive	NONE	CIVIL_UNREST	f	14	68	["Maratha Reservation", "Manoj Jarange", "Hunger Strike"]	{"people": ["Manoj Jarange"], "organizations": ["Maharashtra Government"], "monetary_values": []}	{"broadcast_date": "2024-06-23", "original_timestamp": "02:38"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:25:22.881868
141	General N S Raja Subramani Takes Charge as Chief of Defence Staff	General N S Raja Subramani has officially assumed the role of India's new Chief of Defence Staff (CDS), receiving a Guard of Honour.	Geopolitics	National	9	Positive	NONE	NONE	t	\N	\N	["CDS", "Indian Armed Forces", "Appointment"]	{"people": ["N S Raja Subramani"], "organizations": ["Indian Armed Forces"], "monetary_values": []}	{"broadcast_date": "2024-06-23", "original_timestamp": "02:50"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:25:23.896193
142	PM Modi Praises Athletes in Mann Ki Baat	In his Mann Ki Baat program, PM Modi highlighted the National Senior Athletics Federation competition and congratulated athletes Gurinder and Animesh for their records.	Politics	National	6	Positive	NONE	NONE	t	\N	\N	["Mann Ki Baat", "Athletics", "PM Modi"]	{"people": ["Narendra Modi", "Gurinder", "Animesh"], "organizations": ["National Senior Athletics Federation"], "monetary_values": []}	{"broadcast_date": "2024-06-23", "original_timestamp": "03:02"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:25:24.908658
143	Assam CM Himanta Biswa Sarma Meets Rajnath Singh	Assam Chief Minister Himanta Biswa Sarma met with Union Defence Minister Rajnath Singh in Delhi to seek his blessings and discuss state matters.	Politics	National	5	Positive	NONE	NONE	f	77	\N	["Political Meeting", "Assam", "Defence Ministry"]	{"people": ["Himanta Biswa Sarma", "Rajnath Singh"], "organizations": [], "monetary_values": []}	{"broadcast_date": "2024-06-23", "original_timestamp": "03:18"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:25:25.920642
144	PM Modi to Chair High-Level Meeting on Rajya Sabha Elections	PM Modi will hold a meeting with top BJP leaders, including Amit Shah and J.P. Nadda, to discuss strategies for the upcoming Rajya Sabha elections.	Politics	National	7	Neutral	NONE	NONE	t	\N	\N	["Rajya Sabha Elections", "BJP", "Political Strategy"]	{"people": ["Narendra Modi", "Amit Shah", "J P Nadda", "Nitin Naveen"], "organizations": ["BJP"], "monetary_values": []}	{"broadcast_date": "2024-06-23", "original_timestamp": "03:29"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:25:26.946804
145	UPPCS Exams Conducted Under Tight Security	The UPPCS examination for 1,253 posts was held across various cities in Uttar Pradesh with millions of candidates appearing under strict security measures.	Infrastructure	State	6	Neutral	NONE	NONE	f	42	\N	["UPPCS", "Exams", "Education"]	{"people": [], "organizations": ["UPPSC"], "monetary_values": []}	{"broadcast_date": "2024-06-23", "original_timestamp": "03:42"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:25:27.956032
146	Five Dead as Car Plunges into Gorge in Chamba	A tragic accident in Chamba, Himachal Pradesh, resulted in five deaths after a car fell into a 500-meter deep gorge. Rescue operations are ongoing.	Emergency	District	7	Negative	NONE	NATURAL_DISASTER	f	79	69	["Road Accident", "Chamba", "Himachal Pradesh"]	{"people": [], "organizations": [], "monetary_values": []}	{"broadcast_date": "2024-06-23", "original_timestamp": "04:13"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:25:28.964605
147	IMD Issues Storm and Rain Alert for 21 States	The India Meteorological Department has issued alerts for storms and rain across 21 states, with specific warnings for 10 states regarding severe weather.	Emergency	National	7	Neutral	NONE	NATURAL_DISASTER	t	\N	\N	["Weather Alert", "IMD", "Monsoon"]	{"people": [], "organizations": ["IMD"], "monetary_values": []}	{"broadcast_date": "2024-06-23", "original_timestamp": "04:24"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:25:29.976674
148	Dust Storms Cause Havoc in Rajasthan	Severe dust storms hit Churu, Hanumangarh, and Sri Ganganagar in Rajasthan, reducing visibility and causing a significant drop in temperature.	Emergency	State	6	Negative	NONE	NATURAL_DISASTER	f	39	70	["Dust Storm", "Rajasthan Weather", "Natural Phenomenon"]	{"people": [], "organizations": [], "monetary_values": []}	{"broadcast_date": "2024-06-23", "original_timestamp": "06:05"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:25:30.990286
149	Man Beaten to Death in Nalanda Over Children's Dispute	A middle-aged man was beaten to death in Nalanda, Bihar, following a dispute between children. Police are currently investigating the incident.	Crime	Local	7	Negative	EXTREME	NONE	f	81	71	["Murder", "Nalanda", "Mob Violence"]	{"people": [], "organizations": ["Bihar Police"], "monetary_values": []}	{"broadcast_date": "2024-06-23", "original_timestamp": "07:09"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:25:32.065083
150	Three Arrested with Drugs Worth Γé╣3 Lakh in Satara	Satara police arrested three individuals and seized 95 grams of drugs valued at approximately Γé╣3 lakh.	Crime	District	6	Neutral	MODERATE	NONE	f	14	72	["Drug Seizure", "Satara Police", "Narcotics"]	{"people": [], "organizations": ["Maharashtra Police"], "monetary_values": ["Γé╣3 Lakh"]}	{"broadcast_date": "2024-06-23", "original_timestamp": "07:19"}	\N	300000.00	INR	Lakh	Completed	["Narcotics"]	2026-05-31	2026-05-31 21:25:33.07753
151	Husband Arrested for Acid Attack and Torture in Mumbai	A man was arrested in Mumbai for allegedly attacking his wife with acid, stabbing her, and subjecting her to four hours of physical torture.	Crime	Local	8	Negative	EXTREME	NONE	f	14	11	["Acid Attack", "Domestic Violence", "Mumbai Police"]	{"people": [], "organizations": ["Mumbai Police"], "monetary_values": []}	{"broadcast_date": "2024-06-23", "original_timestamp": "08:32"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:25:34.090823
152	Pakistani Mortar Shell Defused in Poonch	The Indian Army recovered and defused a live Pakistani mortar shell found in a park in Poonch, Jammu and Kashmir. A search operation is underway in the area.	Geopolitics	District	8	Neutral	EXTREME	WAR_CONFLICT	f	40	74	["Mortar Shell", "Poonch", "Border Security"]	{"people": [], "organizations": ["Indian Army"], "monetary_values": []}	{"broadcast_date": "2024-06-23", "original_timestamp": "10:07"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:25:35.107858
153	Eight Terror Suspects Linked to ISI and Underworld Arrested	Delhi Police have arrested a total of eight individuals linked to ISI and the Mumbai underworld. Four suspects are currently in seven-day custody following the seizure of explosives.	Crime	National	9	Neutral	EXTREME	NONE	t	15	\N	["Terrorism", "ISI", "Delhi Police"]	{"people": [], "organizations": ["Delhi Police", "ISI"], "monetary_values": []}	{"broadcast_date": "2024-06-23", "original_timestamp": "10:19"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:25:36.184597
154	Elderly Couple Found Dead in Ludhiana Home	An elderly couple was found dead with head injuries in their Ludhiana home. Police suspect murder and have initiated an investigation.	Crime	Local	7	Negative	EXTREME	NONE	f	45	41	["Double Murder", "Ludhiana", "Crime Investigation"]	{"people": [], "organizations": ["Punjab Police"], "monetary_values": []}	{"broadcast_date": "2024-06-23", "original_timestamp": "10:55"}	\N	\N	\N	\N	\N	[]	2026-05-31	2026-05-31 21:25:37.195775
\.


--
-- Data for Name: news_all_2026_06; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2026_06 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
173	Iran Claims Retaliatory Strike on US-Israel Linked Vessel in Sea of Oman	The Iranian Navy has claimed responsibility for an attack on the vessel MSC Saras in response to a strike on the Iranian ship Lian Star. Reports also indicate an explosion on a cargo ship near Iraq's Umm Qasr port, initially attributed to technical failure.	Geopolitics	International	9	Negative	NONE	WAR_CONFLICT	f	\N	\N	["Iran Navy", "Sea of Oman", "Maritime Security", "Israel-Hamas Conflict"]	{"people": [], "organizations": ["Iranian Navy", "MSC"], "monetary_values": []}	{"broadcast_date": "2024-06-03", "original_timestamp": "00:02"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:35:22.372624
174	Trump Claims Breakthrough in Lebanon Ceasefire Talks Amid Netanyahu Criticism	Donald Trump stated that both sides have agreed to a ceasefire in Lebanon, claiming his intervention prevented a major military operation in Beirut. However, Israeli Prime Minister Netanyahu maintains that operations in Southern Lebanon will continue as planned.	Geopolitics	International	9	Neutral	NONE	WAR_CONFLICT	f	\N	\N	["Donald Trump", "Netanyahu", "Hezbollah", "Lebanon Ceasefire"]	{"people": ["Donald Trump", "Benjamin Netanyahu"], "organizations": ["Hezbollah"], "monetary_values": []}	{"broadcast_date": "2024-06-03", "original_timestamp": "01:57"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:35:23.617129
175	Mamata Banerjee to Protest in Kolkata Against Post-Poll Violence and BJP Tactics	West Bengal CM Mamata Banerjee is set to hold a sit-in protest in Kolkata against alleged violence targeting TMC workers and the removal of street hawkers. She accused the BJP of using money to influence TMC MLAs.	Politics	State	7	Negative	NONE	CIVIL_UNREST	f	38	91	["Mamata Banerjee", "TMC", "West Bengal Politics", "Post-Poll Violence"]	{"people": ["Mamata Banerjee"], "organizations": ["Trinamool Congress", "BJP"], "monetary_values": []}	{"broadcast_date": "2024-06-03", "original_timestamp": "04:18"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:35:24.63661
176	CID Issues Second Notice to Abhishek Banerjee in Fake Signature Case	The West Bengal CID has issued a second notice to TMC MP Abhishek Banerjee, summoning him for questioning on June 8 regarding a fake signature case. This follows a CID team visit to his residence after he requested a 15-day extension.	Crime	State	7	Negative	MODERATE	NONE	f	38	91	["Abhishek Banerjee", "CID", "Forgery Case", "West Bengal"]	{"people": ["Abhishek Banerjee"], "organizations": ["CID"], "monetary_values": []}	{"broadcast_date": "2024-06-03", "original_timestamp": "05:01"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:35:25.677605
177	CM Yogi Adityanath Sparks Debate Over Declaring Cow as National Animal	Uttar Pradesh CM Yogi Adityanath questioned the need for a formal declaration of the cow as the national animal, citing a spiritual bond. Opposition parties like SP and Congress accused him of using the issue for electoral polarization.	Politics	National	6	Neutral	NONE	NONE	t	42	\N	["Yogi Adityanath", "Cow Protection", "National Animal", "UP Politics"]	{"people": ["Yogi Adityanath", "Mrityunjay Tiwari", "Shadab Chauhan"], "organizations": ["Samajwadi Party", "Congress", "RJD", "AIMIM"], "monetary_values": []}	{"broadcast_date": "2024-06-03", "original_timestamp": "06:23"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:35:26.689736
178	CBSE Portal Restored After Glitch; Parliamentary Committee to Discuss Exam Issues	The CBSE portal resumed operations on June 2 after a technical failure caused widespread distress among students. A parliamentary committee is scheduled to meet today to discuss the OSM system and the three-language formula.	Science	National	7	Neutral	NONE	NONE	t	\N	\N	["CBSE", "Education", "Exam Portal", "Parliamentary Committee"]	{"people": ["Dharmendra Pradhan"], "organizations": ["CBSE", "Ministry of Education"], "monetary_values": []}	{"broadcast_date": "2024-06-03", "original_timestamp": "08:06"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:35:27.700099
179	NEET Paper Leak: Demolition of Accused's Property in Beed; Protests Intensify	Authorities in Beed, Maharashtra, demolished an illegal bungalow belonging to NEET paper leak accused PV Kulkarni. Meanwhile, student organizations and opposition leaders continue to demand the resignation of Education Minister Dharmendra Pradhan.	Crime	National	8	Negative	EXTREME	NONE	t	14	93	["NEET Paper Leak", "Beed", "AISA", "Education Reform"]	{"people": ["PV Kulkarni", "Dharmendra Pradhan", "Digvijaya Singh"], "organizations": ["AISA", "Ministry of Education"], "monetary_values": []}	{"broadcast_date": "2024-06-03", "original_timestamp": "10:37"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:35:28.706342
180	Five New Supreme Court Judges to Take Oath Today	Chief Justice of India will administer the oath of office to five new judges today, bringing the total strength of the Supreme Court to 37. This move is expected to assist in clearing the judicial backlog.	Politics	National	8	Positive	NONE	NONE	t	15	15	["Supreme Court", "Judiciary", "CJI", "Oath Ceremony"]	{"people": ["Suryakant"], "organizations": ["Supreme Court of India"], "monetary_values": []}	{"broadcast_date": "2024-06-03", "original_timestamp": "12:04"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:35:29.726939
181	Three Dead in Ludhiana Factory Gas Leak Incident	A fatal gas leak at a machine tools manufacturing factory in Ludhiana has resulted in the deaths of three individuals. Authorities are investigating the cause of the leak which turned the facility into a gas chamber.	Emergency	Local	8	Negative	NONE	PUBLIC_HEALTH	f	45	41	["Ludhiana", "Gas Leak", "Industrial Accident", "Punjab"]	{"people": [], "organizations": [], "monetary_values": []}	{"broadcast_date": "2024-06-03", "original_timestamp": "16:50"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:35:30.775115
182	Mega Food Park Construction Underway in Bareilly to Boost Industrial Growth	The construction of a Mega Food Park in Bareilly, Uttar Pradesh, is progressing to enhance industrial development and provide a boost to the local economy. The project aims to transform the region's industrial landscape.	Infrastructure	District	6	Positive	NONE	NONE	f	42	96	["Bareilly", "Mega Food Park", "Industrial Development", "UP Economy"]	{"people": [], "organizations": [], "monetary_values": []}	{"broadcast_date": "2024-06-03", "original_timestamp": "17:50"}	Capex	\N	INR	Crore	Ongoing	["Food Processing", "Infrastructure"]	2026-06-17	2026-06-17 12:35:31.83582
183	Monsoon Expected to Hit Kerala in Next 2-3 Days; Relief from Heatwave	The India Meteorological Department (IMD) has announced that the Southwest Monsoon is likely to arrive in Kerala within the next 48 to 72 hours. Several states including Gujarat and Madhya Pradesh have already experienced pre-monsoon showers and storms.	Emergency	National	7	Positive	NONE	NATURAL_DISASTER	t	109	\N	["Monsoon", "IMD", "Weather Update", "Kerala"]	{"people": [], "organizations": ["IMD"], "monetary_values": []}	{"broadcast_date": "2024-06-03", "original_timestamp": "19:32"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:35:32.910698
184	US and Iran Clash in Gulf of Oman	Iran's IRGC claims to have launched drone and missile attacks on two US warships in the Gulf of Oman, forcing them to retreat.	Geopolitics	International	8	Negative	NONE	WAR_CONFLICT	f	\N	\N	["US-Iran Conflict", "IRGC", "Gulf of Oman", "Drone Attack"]	{"people": [], "organizations": ["IRGC", "US Navy"], "monetary_values": []}	{"broadcast_date": "2024-06-05", "original_timestamp": "00:02"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:37:50.721209
185	Donald Trump Comments on Ongoing Iran Nuclear Talks	US President Donald Trump stated that negotiations with Iran are continuous, focusing on preventing nuclear weapons and keeping the Strait of Hormuz open.	Geopolitics	International	7	Neutral	NONE	NONE	f	\N	\N	["Donald Trump", "Iran Nuclear Deal", "Strait of Hormuz"]	{"people": ["Donald Trump"], "organizations": [], "monetary_values": []}	{"broadcast_date": "2024-06-05", "original_timestamp": "00:13"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:37:51.780385
186	Massive Rallies in Iran for Eid al-Ghadir	Large crowds gathered in Iran to celebrate Eid al-Ghadir, waving flags of Iran, Palestine, and Hezbollah while protesting against the US and Israel.	Politics	International	6	Negative	NONE	NONE	f	\N	\N	["Eid al-Ghadir", "Iran Protest", "Hezbollah", "Palestine"]	{"people": [], "organizations": ["Hezbollah"], "monetary_values": []}	{"broadcast_date": "2024-06-05", "original_timestamp": "00:25"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:37:52.802112
187	Drone Attack Hits Romanian Port Near Ukraine Border	A Romanian port bordering Ukraine was targeted by a drone attack for the first time since the start of the Russia-Ukraine conflict.	Emergency	International	9	Negative	NONE	WAR_CONFLICT	f	\N	\N	["Romania", "Drone Attack", "Russia-Ukraine War"]	{"people": [], "organizations": [], "monetary_values": []}	{"broadcast_date": "2024-06-05", "original_timestamp": "00:37"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:37:53.813219
188	Russian Strike on Zaporizhzhia Kills One, Injures 15	A heavy Russian attack on the southeastern Ukrainian city of Zaporizhzhia destroyed several buildings, resulting in one death and over 15 injuries.	Emergency	International	9	Negative	NONE	WAR_CONFLICT	f	\N	\N	["Zaporizhzhia", "Russian Attack", "Ukraine War casualties"]	{"people": [], "organizations": [], "monetary_values": []}	{"broadcast_date": "2024-06-05", "original_timestamp": "00:50"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:37:54.826018
189	Putin Praises PM Modi as a Reliable Partner	Russian President Vladimir Putin lauded Prime Minister Narendra Modi, calling India a trustworthy partner and stating that external pressure on Modi is counterproductive.	Geopolitics	International	7	Positive	NONE	NONE	t	\N	\N	["Vladimir Putin", "Narendra Modi", "India-Russia Relations"]	{"people": ["Vladimir Putin", "Narendra Modi"], "organizations": [], "monetary_values": []}	{"broadcast_date": "2024-06-05", "original_timestamp": "01:00"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:37:55.836109
190	PM Modi Inspects Zorawar Tank at L&T Complex in Surat	Prime Minister Modi visited the L&T Armed System Complex in Surat to review the 'Zorawar' light tank, developed under the Make in India initiative.	Science	National	7	Positive	NONE	NONE	t	110	97	["Zorawar Tank", "Make in India", "L&T", "Surat"]	{"people": ["Narendra Modi"], "organizations": ["Larsen & Toubro", "Indian Army"], "monetary_values": []}	{"broadcast_date": "2024-06-05", "original_timestamp": "01:10"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:37:56.847247
191	PM Modi Launches Projects Worth Γé╣18,800 Crore in Surat	Prime Minister Modi inaugurated multiple development projects in Surat totaling Γé╣18,800 crore and promoted environmental conservation on World Environment Day.	Infrastructure	District	8	Positive	NONE	NONE	f	110	97	["Surat Development", "World Environment Day", "Infrastructure"]	{"people": ["Narendra Modi"], "organizations": [], "monetary_values": ["Γé╣18,800 Crore"]}	{"broadcast_date": "2024-06-05", "original_timestamp": "01:23"}	Budget Allocation	18800.00	INR	Crore	Announced	["Infrastructure", "Environment"]	2026-06-17	2026-06-17 12:37:57.874834
192	PM Modi Inaugurates Namo Airport and Hospital in Daman	A development package worth Γé╣10,340 crore was gifted to Daman by PM Modi, including the inauguration of the Namo Airport terminal and Namo Hospital.	Infrastructure	District	8	Positive	NONE	NONE	f	112	99	["Namo Airport", "Namo Hospital", "Daman Development"]	{"people": ["Narendra Modi"], "organizations": [], "monetary_values": ["Γé╣10,340 Crore"]}	{"broadcast_date": "2024-06-05", "original_timestamp": "01:34"}	Budget Allocation	10340.00	INR	Crore	Completed	["Aviation", "Healthcare"]	2026-06-17	2026-06-17 12:37:58.938215
193	Major Gas Reserve Discovered off Andaman Coast	The Samudra Manthan mission has successfully located a gas reserve 15 km off the Andaman coast, leading to praise for Oil India Limited from Minister Hardeep Singh Puri.	Science	National	7	Positive	NONE	NONE	t	113	\N	["Gas Discovery", "Andaman", "Oil India Limited", "Samudra Manthan"]	{"people": ["Hardeep Singh Puri"], "organizations": ["Oil India Limited"], "monetary_values": []}	{"broadcast_date": "2024-06-05", "original_timestamp": "01:44"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:38:00.022434
194	Amit Shah Reviews Border Security in Tripura	Home Minister Amit Shah visited the India-Bangladesh border in Tripura to interact with BSF personnel and discuss border security issues at the Agartala HQ.	Politics	State	6	Neutral	NONE	NONE	f	114	100	["Amit Shah", "BSF", "Tripura", "Border Security"]	{"people": ["Amit Shah"], "organizations": ["BSF"], "monetary_values": []}	{"broadcast_date": "2024-06-05", "original_timestamp": "01:55"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:38:01.102596
195	CM Yogi Launches Projects Worth Γé╣294 Crore in Balrampur	UP CM Yogi Adityanath inaugurated 75 development projects in Balrampur and warned against the influence of casteism and mafia elements.	Infrastructure	District	6	Positive	NONE	NONE	f	42	101	["Yogi Adityanath", "Balrampur", "Infrastructure Projects"]	{"people": ["Yogi Adityanath"], "organizations": [], "monetary_values": ["Γé╣294 Crore"]}	{"broadcast_date": "2024-06-05", "original_timestamp": "02:04"}	Budget Allocation	294.00	INR	Crore	Announced	["Infrastructure"]	2026-06-17	2026-06-17 12:38:02.11066
196	Illegal Mazar Demolished in Sambhal, Uttar Pradesh	District administration in Sambhal used bulldozers to demolish an illegal mazar built on government land near the Khandeshwar Shiva temple.	Politics	District	5	Neutral	LOW	NONE	f	42	102	["Sambhal", "Demolition Drive", "Illegal Encroachment"]	{"people": [], "organizations": [], "monetary_values": []}	{"broadcast_date": "2024-06-05", "original_timestamp": "02:25"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:38:03.131725
197	TMC to Challenge Leader of Opposition Appointment in Court	Following a meeting at Mamata Banerjee's residence, TMC MP Kalyan Banerjee declared the Speaker's appointment of the Leader of Opposition as illegal and announced a court challenge.	Politics	State	6	Negative	NONE	NONE	f	38	91	["TMC", "Mamata Banerjee", "Kalyan Banerjee", "Leader of Opposition"]	{"people": ["Mamata Banerjee", "Kalyan Banerjee"], "organizations": ["Trinamool Congress"], "monetary_values": []}	{"broadcast_date": "2024-06-05", "original_timestamp": "02:37"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:38:04.14914
198	BJP and JDU Announce Candidates for Bihar MLC Elections	The BJP and JDU have released their candidate lists for the Bihar MLC elections, featuring actor Pawan Singh and Nitish Kumar's son Nishant.	Politics	State	6	Neutral	NONE	NONE	f	81	\N	["Bihar MLC Elections", "Pawan Singh", "Nitish Kumar", "BJP", "JDU"]	{"people": ["Pawan Singh", "Sanjay Mayukh", "Nishant Kumar", "Nitish Kumar"], "organizations": ["BJP", "JDU"], "monetary_values": []}	{"broadcast_date": "2024-06-05", "original_timestamp": "02:49"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:38:05.180282
199	K. Annamalai Announces New Political Party for 2031	Former Tamil Nadu BJP President K. Annamalai has announced the formation of a new political party to contest the 2031 elections.	Politics	State	5	Neutral	NONE	NONE	f	119	\N	["K. Annamalai", "Tamil Nadu Politics", "New Political Party"]	{"people": ["K. Annamalai"], "organizations": ["BJP"], "monetary_values": []}	{"broadcast_date": "2024-06-05", "original_timestamp": "03:03"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:38:06.18705
200	Delhi Govt to Recover Damages from Officials for Illegal Construction	The Delhi government has decided to hold officials accountable for illegal constructions, recovering public losses from their salaries, pensions, and assets.	Politics	State	7	Neutral	NONE	NONE	f	15	\N	["Delhi Government", "Illegal Construction", "Official Accountability"]	{"people": [], "organizations": ["Delhi Government"], "monetary_values": []}	{"broadcast_date": "2024-06-05", "original_timestamp": "03:13"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:38:07.197597
201	Demolition Drive in Delhi Following Fatal Fire Incident	After a fire killed 21 people in Delhi, authorities have launched a demolition drive against illegal buildings in the Ghitorni area.	Emergency	Local	9	Negative	NONE	PUBLIC_HEALTH	f	15	104	["Delhi Fire", "Ghitorni", "Demolition Drive", "Illegal Buildings"]	{"people": [], "organizations": [], "monetary_values": []}	{"broadcast_date": "2024-06-05", "original_timestamp": "03:26"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:38:08.207674
202	Sealing Drive in Hauz Khas and Malviya Nagar	Following the Malviya Nagar fire, Delhi authorities have sealed several shops and buildings in Hauz Khas for violating safety regulations.	Emergency	Local	8	Negative	NONE	PUBLIC_HEALTH	f	15	61	["Hauz Khas", "Malviya Nagar", "Sealing Drive", "Safety Violations"]	{"people": [], "organizations": [], "monetary_values": []}	{"broadcast_date": "2024-06-05", "original_timestamp": "03:37"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:38:09.227457
203	Atishi Alleges Entry Denial at Max Hospital	Former Delhi Minister Atishi claimed she was blocked by security from meeting fire victims at Max Hospital, accusing the BJP of concealing the truth.	Politics	Local	5	Negative	NONE	NONE	f	15	\N	["Atishi", "Max Hospital", "Delhi Fire Victims", "BJP"]	{"people": ["Atishi"], "organizations": ["Aam Aadmi Party", "BJP", "Max Hospital"], "monetary_values": []}	{"broadcast_date": "2024-06-05", "original_timestamp": "03:46"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:38:10.238186
204	Three Arrested in Muzaffarpur Hospital Fire Case	Police arrested a doctor and two others following a hospital fire in Muzaffarpur that resulted in the deaths of six patients.	Crime	District	9	Negative	EXTREME	PUBLIC_HEALTH	f	81	106	["Muzaffarpur", "Hospital Fire", "Arrests", "Medical Negligence"]	{"people": [], "organizations": [], "monetary_values": []}	{"broadcast_date": "2024-06-05", "original_timestamp": "03:58"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:38:11.243839
205	Massive Fire Breaks Out in Moradabad Warehouse	A major fire erupted in a warehouse in Moradabad, Uttar Pradesh, causing panic in the area. The fire brigade successfully controlled the blaze, though goods worth lakhs were destroyed.	Emergency	Local	6	Negative	NONE	NONE	f	42	107	["fire", "warehouse", "property_damage"]	{"people": null, "organizations": ["Fire Brigade"], "monetary_values": ["Lakhs of rupees"]}	{"broadcast_date": "2024-06-02", "original_timestamp": "00:03"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:40:39.047974
206	Demolition of Illegal Mazar in Goregaon, Mumbai	Authorities have initiated action against an illegal mazar in Goregaon, Mumbai, following concerns raised by BJP leader Kirit Somaiya. Heavy police force was deployed to maintain order during the demolition.	Politics	District	7	Neutral	NONE	NONE	f	14	11	["demolition", "illegal_structure", "encroachment"]	{"people": ["Kirit Somaiya"], "organizations": ["Mumbai Police", "BJP"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "00:15"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:40:40.095629
207	Cylinder Blast in Mukundpur, Delhi; Rescue Operations Underway	A cylinder explosion in a building in Delhi's Mukundpur area caused a partial collapse, trapping several people under debris. Fire brigade teams have rescued several individuals from the site.	Emergency	Local	8	Negative	NONE	NONE	f	15	109	["cylinder_blast", "rescue", "accident"]	{"people": null, "organizations": ["Fire Brigade"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "00:29"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:40:41.155555
208	Teenager Stabbed to Death in New Usmanpur, Delhi	A 17-year-old boy was fatally stabbed in Delhi's New Usmanpur area. Police have arrested three suspects after the incident was captured on CCTV.	Crime	Local	9	Negative	EXTREME	NONE	f	15	110	["murder", "stabbing", "arrest"]	{"people": null, "organizations": ["Delhi Police"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "00:39"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:40:42.210183
209	Sword Attack in Baghpat Captured on CCTV	A youth was attacked with a sword in Baghpat, Uttar Pradesh. The assailant fled the scene, and police are currently investigating the CCTV footage to identify the culprit.	Crime	Local	7	Negative	MODERATE	NONE	f	42	111	["assault", "sword_attack", "cctv"]	{"people": null, "organizations": ["Uttar Pradesh Police"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "00:50"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:40:43.224751
210	Extortion Firing Outside Builder's House in Dwarka	Panic spread in Delhi's Dwarka after eight rounds were fired outside the residence of Mahavir Builder. Police suspect the attack was intended to intimidate the builder for extortion.	Crime	Local	8	Negative	MODERATE	NONE	f	15	104	["firing", "extortion", "builder"]	{"people": ["Mahavir Builder"], "organizations": ["Delhi Police"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "01:03"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:40:44.244574
211	Road Collapse in Agra Exposes Poor Infrastructure	A 15-foot section of a road collapsed in Agra due to a faulty sewer line project following pre-monsoon rains. A tractor-trolley loaded with bricks fell into the crater.	Infrastructure	District	6	Negative	NONE	NONE	f	42	113	["road_collapse", "monsoon", "sewer_project"]	{"people": null, "organizations": ["Jal Nigam"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "01:15"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:40:45.316826
212	Controversy Over Namaz in Maharashtra Park	A video of people offering Namaz in a park in Aryan Nagar, Maharashtra, went viral. In response, Hindu organizations performed 'purification' by reciting Hanuman Chalisa and demanded action.	Politics	Local	6	Negative	NONE	CIVIL_UNREST	f	14	\N	["communal_tension", "namaz", "hanuman_chalisa"]	{"people": null, "organizations": ["Hindu Organizations"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "01:30"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:40:46.323772
213	British-Era Bridge Collapses in Kanpur	A dilapidated bridge from the British era collapsed in Kanpur, Uttar Pradesh, due to heavy water flow. Traffic has been diverted to an under-construction bridge nearby.	Infrastructure	District	6	Negative	NONE	NONE	f	42	114	["bridge_collapse", "infrastructure_failure", "british_era"]	{"people": null, "organizations": null, "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "01:41"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:40:47.395372
214	Speculation of Split in TMC as MLAs Meet Expelled Leaders	Six TMC MLAs in West Bengal met with expelled party members, fueling rumors of a split in Mamata Banerjee's party. The BJP stated that its doors are closed for TMC defectors.	Politics	State	8	Neutral	NONE	NONE	f	38	\N	["tmc", "political_split", "west_bengal_politics"]	{"people": ["Mamata Banerjee"], "organizations": ["TMC", "BJP"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "01:52"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:40:48.406983
215	TMC Councilor Arrested for Extortion in North 24 Parganas	A TMC councilor was arrested in West Bengal's North 24 Parganas on charges of extortion and issuing threats. Local residents protested against the leader, chanting slogans and vandalizing property.	Crime	District	7	Negative	MODERATE	NONE	f	38	115	["extortion", "arrest", "tmc_leader"]	{"people": null, "organizations": ["TMC"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "02:04"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:40:49.447051
216	CID Intensifies Signature Scam Probe; Abhishek Banerjee Summoned	The CID has accelerated its investigation into the West Bengal signature scam, recording statements from 13 TMC MLAs. TMC leader Abhishek Banerjee has been summoned in connection with the alleged forged letters.	Crime	State	8	Negative	MODERATE	NONE	f	38	\N	["signature_scam", "cid", "abhishek_banerjee"]	{"people": ["Abhishek Banerjee"], "organizations": ["CID", "TMC"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "02:16"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:40:50.454481
217	K. Annamalai Meets BL Santhosh Amid Exit Rumors	Tamil Nadu BJP President K. Annamalai met with senior leader BL Santhosh at the BJP headquarters. The meeting occurred amidst speculation regarding Annamalai's future within the party.	Politics	National	7	Neutral	NONE	NONE	t	15	\N	["bjp", "annamalai", "political_meeting"]	{"people": ["K. Annamalai", "BL Santhosh"], "organizations": ["BJP"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "02:31"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:40:51.473927
218	Bihar Government to Probe Grant-Aided Madrasas	The Bihar government has ordered an investigation into the functioning of madrasas that receive government grants. District Education Officers have been directed to conduct the probe.	Politics	State	7	Neutral	NONE	NONE	f	81	\N	["madrasa_probe", "bihar_government", "education"]	{"people": ["Samrat Choudhary"], "organizations": ["Bihar Government"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "02:41"}	Grant	\N	INR	\N	Announced	["Education"]	2026-06-17	2026-06-17 12:40:52.482
219	Supreme Court Reaches Strength of 37 with 5 New Judges	Five new judges were sworn into the Supreme Court of India, bringing the total strength to 37. Chief Justice administered the oath to Justices Sheel Nagu, Chandrashekhar, Sanjiv Sachdeva, Arun Palli, and V. Mohana.	Politics	National	9	Positive	NONE	NONE	t	15	\N	["supreme_court", "judiciary", "appointments"]	{"people": ["Sheel Nagu", "Chandrashekhar", "Sanjiv Sachdeva", "Arun Palli", "V. Mohana"], "organizations": ["Supreme Court of India"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "02:50"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:40:53.556796
220	CBSE Portal Resumes Operations for Student Applications	The CBSE portal has resumed functioning as of June 2nd after a long wait. Students can now easily apply for various services through the official website.	Science	National	6	Positive	NONE	NONE	t	\N	\N	["cbse", "education_portal", "students"]	{"people": null, "organizations": ["CBSE"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "03:06"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:40:54.625931
221	Bulldozer Action on NEET Paper Leak Accused's Property	Authorities in Beed, Maharashtra, demolished the illegal bungalow of PV Kulkarni, an accused in the NEET paper leak case. The action followed a one-week notice regarding illegal construction.	Crime	District	8	Neutral	MODERATE	NONE	f	14	93	["neet_paper_leak", "bulldozer_action", "illegal_construction"]	{"people": ["PV Kulkarni"], "organizations": null, "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "03:18"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:40:55.642339
222	AISA Protests Outside Education Ministry Over Exam Irregularities	The All India Students Association (AISA) staged a protest outside the Education Ministry against irregularities in NEET and CBSE exams. Protesters demanded the resignation of Education Minister Dharmendra Pradhan.	Politics	National	7	Negative	NONE	CIVIL_UNREST	t	15	\N	["aisa", "protest", "neet_scam", "dharmendra_pradhan"]	{"people": ["Dharmendra Pradhan"], "organizations": ["AISA", "Ministry of Education"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "03:31"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:40:56.730082
223	Sanjay Singh Clashes with ADM Over Paper Leak Meeting	AAP leader Sanjay Singh had a heated exchange with the ADM City in Prayagraj over the prevention of a meeting regarding the paper leak issue. Singh argued that no permission is needed for meetings at the Circuit House.	Politics	District	6	Negative	NONE	NONE	f	42	117	["sanjay_singh", "prayagraj", "paper_leak"]	{"people": ["Sanjay Singh"], "organizations": ["AAP"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "03:44"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:40:57.743614
224	BJP to Launch Nationwide Public Outreach Campaign	The BJP will conduct a nationwide campaign from June 5 to 21, where MPs and MLAs will visit villages. The goal is to inform citizens about major decisions taken in the public interest over the last 12 years.	Politics	National	7	Positive	NONE	NONE	t	\N	\N	["bjp", "outreach_campaign", "governance"]	{"people": null, "organizations": ["BJP"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "03:57"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:40:58.813838
225	CM Yogi Adityanath on Declaring Cow as National Animal	Uttar Pradesh CM Yogi Adityanath stated that the cow is a mother and there is no need to formally declare the relationship between a mother and son. He criticized those demanding a formal status for political reasons.	Politics	State	6	Neutral	NONE	NONE	f	42	\N	["yogi_adityanath", "cow_protection", "national_animal"]	{"people": ["Yogi Adityanath"], "organizations": ["BJP"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "04:08"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:40:59.892549
255	Gambling Racket Busted in Noida Hotel; 20 Arrested	Police busted a gambling racket operating out of a hotel in Noida, arresting 20 individuals. Cash, luxury cars, and mobile phones were seized during the raid.	Crime	District	7	Negative	MODERATE	NONE	f	42	142	["gambling_racket", "noida", "arrest"]	{"people": null, "organizations": ["Noida Police"], "monetary_values": ["Lakhs of cash"]}	{"broadcast_date": "2024-06-02", "original_timestamp": "10:30"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:30.997205
226	Opposition Attacks BJP Over Cow Smuggling and National Animal Issue	The Samajwadi Party and Congress have criticized CM Yogi Adityanath, alleging that the cow is used as a political tool. They questioned the government's failure to stop cow smuggling in Uttar Pradesh.	Politics	State	6	Negative	NONE	NONE	f	42	\N	["opposition", "cow_smuggling", "political_criticism"]	{"people": ["Yogi Adityanath"], "organizations": ["Samajwadi Party", "Congress"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "04:22"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:00.966308
227	Lookout Circular Issued Against SAD Leader Bikram Majithia	Punjab Police have issued a lookout circular against Shiromani Akali Dal leader Bikram Singh Majithia, preventing him from leaving the country. Majithia has been absconding following an incident at a police station.	Crime	State	8	Negative	MODERATE	NONE	f	45	\N	["bikram_majithia", "lookout_circular", "punjab_police"]	{"people": ["Bikram Singh Majithia"], "organizations": ["Punjab Police", "Shiromani Akali Dal"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "04:49"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:01.97701
228	PM Modi Meets Myanmar President to Discuss Security and Connectivity	Prime Minister Modi met with the President of Myanmar to discuss bilateral issues. Myanmar assured that its territory would not be used against India's security interests, and both nations emphasized increasing connectivity.	Geopolitics	International	9	Positive	NONE	NONE	t	15	\N	["modi", "myanmar", "bilateral_talks", "security"]	{"people": ["Narendra Modi"], "organizations": ["Ministry of External Affairs"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "05:01"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:02.99907
229	UP Minister Warns Criminals of Encounters	Uttar Pradesh Minister JPS Rathore issued a stern warning to criminals, advising them to surrender to avoid police encounters. He noted that police personnel also face risks during such confrontations.	Politics	State	7	Neutral	NONE	NONE	f	42	\N	["jps_rathore", "encounters", "crime_control"]	{"people": ["JPS Rathore"], "organizations": ["Uttar Pradesh Government"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "05:24"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:04.086914
230	Relief for UP Electricity Consumers as Surcharge Hike Ruled Illegal	The Electricity Regulatory Commission has questioned UPPCL's decision to increase fuel surcharge by 10%, calling it illegal. This provides significant relief to electricity consumers in Uttar Pradesh.	Economy	State	8	Positive	NONE	NONE	f	42	\N	["electricity_bill", "uppcl", "regulatory_commission"]	{"people": null, "organizations": ["UPPCL", "Electricity Regulatory Commission"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "05:35"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:05.156239
231	Anti-Terror Operation Intensified in Rajouri	Security forces have launched a massive search operation in the forest areas of Rajouri, Jammu and Kashmir, to track down terrorists. Deployment has been increased across the region.	Emergency	District	9	Neutral	EXTREME	WAR_CONFLICT	f	40	37	["anti_terror_operation", "rajouri", "security_forces"]	{"people": null, "organizations": ["Indian Army", "Jammu and Kashmir Police"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "05:50"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:06.162892
232	Protest in Kanpur Over Death of Social Media Influencer	Family and relatives of social media influencer Mansi staged a protest in Kanpur, demanding justice for her death. The case has drawn significant local attention.	Politics	Local	6	Negative	NONE	CIVIL_UNREST	f	42	114	["protest", "influencer_death", "justice"]	{"people": ["Mansi"], "organizations": null, "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "06:03"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:07.207144
233	Fire in Ghaziabad Multi-Story Building; Residents Rescued	A fire broke out in a multi-story building in Ghaziabad, forcing residents to evacuate via stairs. Two fire engines successfully brought the blaze under control.	Emergency	Local	6	Negative	NONE	NONE	f	42	42	["fire", "ghaziabad", "rescue"]	{"people": null, "organizations": ["Fire Brigade"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "06:12"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:08.276009
234	Fatal Road Accident in Balrampur; One Dead	A speeding pickup truck collided with a motorcycle in Balrampur, Uttar Pradesh, resulting in the death of the rider. Police are investigating the incident.	Crime	Local	5	Negative	MODERATE	NONE	f	42	101	["road_accident", "balrampur", "fatality"]	{"people": null, "organizations": ["Uttar Pradesh Police"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "06:23"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:09.287252
235	Sleeper Bus Overturns in Baran, Rajasthan; 2 Dead	A sleeper bus carrying passengers overturned on a highway in Baran, Rajasthan. The accident claimed two lives, including a child, and left 12 others injured.	Emergency	District	7	Negative	NONE	NONE	f	39	122	["bus_accident", "baran", "fatalities"]	{"people": null, "organizations": null, "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "06:32"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:10.374599
236	Tractor Falls into Well in Jhansi; Driver Survives	A tractor lost control and fell into a well in Jhansi, Uttar Pradesh. The driver narrowly escaped with his life, and the vehicle was later pulled out using a crane.	Emergency	Local	4	Neutral	NONE	NONE	f	42	123	["accident", "jhansi", "rescue"]	{"people": null, "organizations": null, "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "06:42"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:11.427556
237	Self-Immolation Attempt Over Unpaid Bills in Kanpur Dehat	A youth who ran a government canteen attempted self-immolation at Vikas Bhavan in Kanpur Dehat. He alleged that his payments for lunch packets have been pending for four years.	Politics	District	7	Negative	NONE	NONE	f	42	124	["self_immolation", "unpaid_dues", "kanpur_dehat"]	{"people": null, "organizations": ["Vikas Bhavan"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "06:54"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:12.433887
238	Man Climbs Tower Over Land Dispute in Ghazipur	A man climbed a high-tension tower in Ghazipur after failing to get justice in a land dispute. He eventually climbed down after persuasion from the local administration.	Politics	Local	5	Negative	NONE	NONE	f	42	125	["land_dispute", "protest", "ghazipur"]	{"people": null, "organizations": null, "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "07:07"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:13.443923
239	Lucknow Police Inspect Security for Muharram	Lucknow Police conducted inspections at Bada Imambara and Chhota Imambara to review security arrangements for Muharram. DCP West Kamlesh Dixit led the foot patrol.	Politics	District	6	Neutral	NONE	NONE	f	42	126	["muharram", "security_inspection", "lucknow_police"]	{"people": ["Kamlesh Dixit"], "organizations": ["Lucknow Police"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "07:19"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:14.455425
240	Sabarmati River Cleaning Drive in Ahmedabad	Gujarat Minister Rishikesh Patel led a cleaning drive for the Sabarmati River in Ahmedabad ahead of the monsoon. The initiative aimed to clear debris from the riverbanks.	Infrastructure	District	6	Positive	NONE	NONE	f	110	127	["sabarmati_river", "cleaning_drive", "gujarat_government"]	{"people": ["Rishikesh Patel"], "organizations": ["Gujarat Government"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "07:34"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:15.464371
241	Farmers Protest in Tamil Nadu for Loan Waiver	Around 600 farmers staged a protest in Vellore, Tamil Nadu, demanding a complete waiver of agricultural loans. The farmers took to the streets to voice their grievances.	Politics	State	7	Negative	NONE	CIVIL_UNREST	f	119	128	["farmers_protest", "loan_waiver", "vellore"]	{"people": null, "organizations": null, "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "07:46"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:16.538132
242	NEET Aspirant Commits Suicide in Mauganj, MP	A student preparing for the NEET exam committed suicide in Mauganj, Madhya Pradesh. In a suicide note, she expressed that she did not have the courage to take the re-exam.	Crime	Local	8	Negative	EXTREME	NONE	f	43	129	["suicide", "neet_exam", "student_pressure"]	{"people": null, "organizations": null, "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "07:55"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:17.608757
243	Over 10 Lakh Pilgrims Visit Kedarnath Dham	More than 10 lakh devotees have visited the Kedarnath Dham since the pilgrimage began on April 22. There is significant enthusiasm among the followers of Baba Kedar.	Politics	National	7	Positive	NONE	NONE	f	161	130	["kedarnath", "pilgrimage", "char_dham_yatra"]	{"people": null, "organizations": null, "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "08:08"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:18.614418
244	Police Officer Rides Bullock Cart in Mahoba	A video of CO Ravikant Gaud riding a bullock cart in uniform has gone viral in Mahoba. The officer reportedly left his official vehicle to ride the cart.	Politics	Local	3	Positive	NONE	NONE	f	42	131	["viral_video", "mahoba", "police_officer"]	{"people": ["Ravikant Gaud"], "organizations": ["Uttar Pradesh Police"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "08:18"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:19.633295
245	Wayanad Forest Staff Bottle-Feed Lost Fawn	The Wayanad Forest Department released a video showing two female forest workers bottle-feeding a fawn that had been separated from its mother.	Science	Local	4	Positive	NONE	NONE	f	109	132	["wildlife_rescue", "wayanad", "forest_department"]	{"people": null, "organizations": ["Kerala Forest Department"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "08:29"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:20.65314
246	Python Rescued from Residential Area in Bahraich	A python caused panic in a residential area of Bahraich, Uttar Pradesh. The forest department successfully rescued the snake and released it back into the wild.	Emergency	Local	4	Neutral	NONE	NONE	f	42	133	["python_rescue", "bahraich", "wildlife"]	{"people": null, "organizations": ["Forest Department"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "08:43"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:21.672809
247	Student Leader Murder Accused Killed in Assam Encounter	The main accused in the murder of a student leader was killed in a police encounter in Nalbari, Assam. The accused had previously attacked the leader and his sister.	Crime	District	8	Neutral	EXTREME	NONE	f	77	134	["encounter", "murder_accused", "assam_police"]	{"people": ["Mridu Vardhan Barman"], "organizations": ["Assam Police"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "08:57"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:22.694074
248	Man Kills Colleague with Scissors in Mukherjee Nagar	A man working in a mattress shop in Delhi's Mukherjee Nagar killed his colleague with a pair of scissors. Police have arrested the accused, identified as Ashfaq.	Crime	Local	8	Negative	EXTREME	NONE	f	15	109	["murder", "mukherjee_nagar", "arrest"]	{"people": ["Ashfaq"], "organizations": ["Delhi Police"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "09:12"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:23.703252
249	Suspicious Death of 7th Grade Girl in Kishanganj	A 7th-grade student died under suspicious circumstances in Kishanganj, Bihar. Police have registered a case based on the family's complaint and are investigating.	Crime	Local	8	Negative	EXTREME	NONE	f	81	136	["suspicious_death", "kishanganj", "investigation"]	{"people": null, "organizations": ["Bihar Police"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "09:24"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:24.780619
250	12-Year-Old Boy Murdered in Chitrakoot	A 12-year-old boy was murdered in Chitrakoot, Uttar Pradesh, leaving his family in shock. Police are currently investigating the case to find the perpetrators.	Crime	Local	8	Negative	EXTREME	NONE	f	42	137	["murder", "chitrakoot", "child_victim"]	{"people": null, "organizations": ["Uttar Pradesh Police"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "09:36"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:25.80166
251	Child Injured in Firing Outside Shop in New Usmanpur	Brave criminals opened fire outside a businessman's shop in Delhi's New Usmanpur. A child passing by was hit by a bullet and injured.	Crime	Local	9	Negative	EXTREME	NONE	f	15	110	["firing", "child_injured", "new_usmanpur"]	{"people": null, "organizations": ["Delhi Police"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "09:47"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:26.813881
252	Youth Injured in Firing in Moradabad	A youth was injured after bike-borne assailants opened fire in Moradabad. The incident is reportedly linked to an ongoing dispute between two parties.	Crime	Local	7	Negative	MODERATE	NONE	f	42	107	["firing", "moradabad", "dispute"]	{"people": null, "organizations": ["Uttar Pradesh Police"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "10:00"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:27.879487
253	Businessman's Wife Murdered in Saharanpur	The wife of a businessman was murdered in Saharanpur while she was alone at home. Police have launched an investigation into the sensational crime.	Crime	Local	8	Negative	EXTREME	NONE	f	42	140	["murder", "saharanpur", "crime_against_women"]	{"people": null, "organizations": ["Uttar Pradesh Police"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "10:09"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:28.896139
254	Husband and Wife Arrested for Murdering Lover in Fatehpur	In Fatehpur, a man killed his wife's lover after inviting him to their home. The wife reportedly assisted in the murder, and both have been arrested by the police.	Crime	Local	8	Negative	EXTREME	NONE	f	42	141	["murder", "fatehpur", "arrest"]	{"people": null, "organizations": ["Uttar Pradesh Police"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "10:19"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:29.973829
256	Man Arrested for Harassing Women in Vrindavan	An individual was arrested for harassing women on the Parikrama Marg in Vrindavan, Mathura. A video of the police making him apologize has gone viral on social media.	Crime	Local	5	Neutral	LOW	NONE	f	42	143	["harassment", "vrindavan", "arrest"]	{"people": null, "organizations": ["Uttar Pradesh Police"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "10:43"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:32.017197
257	20 Crore Worth Ganja Seized at Varanasi Airport	Customs officials at Varanasi Airport seized cannabis worth approximately 20 crore rupees. Six foreign smugglers arriving from Bangkok were arrested in the operation.	Crime	International	9	Negative	EXTREME	NONE	f	42	144	["drug_seizure", "varanasi_airport", "smuggling"]	{"people": null, "organizations": ["Customs Department"], "monetary_values": ["Γé╣20 Crore"]}	{"broadcast_date": "2024-06-02", "original_timestamp": "10:55"}	\N	20.00	INR	Crore	Completed	["Illegal Narcotics"]	2026-06-17	2026-06-17 12:41:33.029661
258	Injured Criminal Asks for Bidi After Muzaffarnagar Encounter	A criminal arrested after an encounter in Muzaffarnagar was seen asking police for a 'bidi' while injured. The video of the incident has surfaced online.	Crime	Local	4	Neutral	MODERATE	NONE	f	42	145	["encounter", "muzaffarnagar", "viral_video"]	{"people": null, "organizations": ["Uttar Pradesh Police"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "11:06"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:34.087876
259	Six Arrested in Haryana's Pradeep Murder Case	Bhiwani Police have arrested six individuals, including the main accused, in connection with the murder of Pradeep. The investigation is ongoing.	Crime	District	7	Neutral	EXTREME	NONE	f	177	146	["murder", "bhiwani", "arrest"]	{"people": ["Pradeep"], "organizations": ["Haryana Police"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "11:17"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:35.097653
260	Monsoon Expected to Hit Kerala in 2-3 Days	The India Meteorological Department (IMD) has announced that the Southwest Monsoon is expected to arrive in Kerala within the next two to three days, providing relief from the heat.	Science	National	8	Positive	NONE	NONE	t	109	\N	["monsoon", "weather_update", "imd"]	{"people": null, "organizations": ["IMD"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "11:25"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:36.108099
261	Rain and Storms Bring Relief from Heat in Madhya Pradesh	Heavy rain and storms in Ujjain, Burhanpur, and Neemuch have led to a drop in temperatures, providing much-needed relief from the scorching summer heat.	Science	State	5	Positive	NONE	NONE	f	43	147	["rain", "weather", "madhya_pradesh"]	{"people": null, "organizations": null, "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "11:35"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:37.122837
262	Pleasant Weather in Nainital After Rainfall	Nainital experienced a change in weather with heavy rainfall, making the climate pleasant. However, some areas faced waterlogging on the roads.	Science	Local	4	Positive	NONE	NONE	f	161	148	["nainital", "rain", "weather"]	{"people": null, "organizations": null, "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "12:11"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:38.180339
263	Elephants Bathe in River to Escape Heat in Balrampur	A video from Balrampur, Uttar Pradesh, shows elephants bathing in a river to escape the intense heat. The herd has taken up residence along the riverbanks.	Science	Local	3	Positive	NONE	NONE	f	42	101	["elephants", "wildlife", "heatwave"]	{"people": null, "organizations": null, "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "12:19"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:39.262614
264	Iran Claims Counter-Attack on US-Israel Linked Ship	The Iranian Navy claims to have retaliated against an attack on its vessel 'Lian Star' by targeting the US-Israel linked ship 'MSC Sarah V' in the Sea of Oman.	Geopolitics	International	10	Negative	NONE	WAR_CONFLICT	f	\N	\N	["iran", "israel", "maritime_conflict", "msc_sarah_v"]	{"people": null, "organizations": ["Iranian Navy", "IRGC"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "12:28"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:40.271833
265	Hezbollah Drone Attack on Israeli Bunker	Hezbollah targeted an Israeli military bunker near Beaufort Castle with a drone. The attack follows Israel's move to raise its flag over the Lebanese fortress.	Geopolitics	International	10	Negative	NONE	WAR_CONFLICT	f	\N	\N	["hezbollah", "israel", "drone_attack", "lebanon"]	{"people": null, "organizations": ["Hezbollah", "Israeli Defense Forces"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "13:02"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:41.279539
266	Iran Suspends Talks with US Over Ceasefire Violations	Iran has reportedly suspended talks with the United States, citing repeated ceasefire violations and Israeli attacks on Lebanon as major obstacles to peace negotiations.	Geopolitics	International	10	Negative	NONE	WAR_CONFLICT	f	\N	\N	["iran_us_talks", "ceasefire", "geopolitics"]	{"people": ["Donald Trump"], "organizations": ["US Government", "Iranian Government"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "13:15"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:42.288941
267	Iran Asserts Control Over Strait of Hormuz	The Iranian military claims full control over the Strait of Hormuz and warns that a maritime blockade will continue. They reported that 15 ships, including four oil tankers, passed through in the last 24 hours.	Geopolitics	International	10	Negative	NONE	WAR_CONFLICT	f	\N	\N	["strait_of_hormuz", "iran_military", "oil_tankers"]	{"people": null, "organizations": ["Iranian Armed Forces"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "13:50"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:43.315858
268	Consideration to Close Bab-el-Mandeb Strait	There are reports of considerations to completely close the Bab-el-Mandeb Strait, which is currently under the control of Yemen's Houthi rebels.	Geopolitics	International	10	Negative	NONE	WAR_CONFLICT	f	\N	\N	["bab_el_mandeb", "houthi_rebels", "maritime_security"]	{"people": null, "organizations": ["Houthi Rebels"], "monetary_values": null}	{"broadcast_date": "2024-06-02", "original_timestamp": "14:10"}	\N	\N	\N	\N	\N	[]	2026-06-17	2026-06-17 12:41:44.321764
\.


--
-- Data for Name: news_all_2026_07; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2026_07 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2026_08; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2026_08 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2026_09; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2026_09 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2026_10; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2026_10 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2026_11; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2026_11 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2026_12; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2026_12 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2027_01; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2027_01 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2027_02; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2027_02 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2027_03; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2027_03 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2027_04; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2027_04 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2027_05; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2027_05 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2027_06; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2027_06 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2027_07; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2027_07 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2027_08; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2027_08 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2027_09; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2027_09 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2027_10; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2027_10 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2027_11; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2027_11 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2027_12; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2027_12 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2028_01; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2028_01 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2028_02; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2028_02 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2028_03; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2028_03 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2028_04; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2028_04 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2028_05; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2028_05 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2028_06; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2028_06 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2028_07; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2028_07 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2028_08; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2028_08 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2028_09; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2028_09 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2028_10; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2028_10 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2028_11; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2028_11 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2028_12; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2028_12 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2029_01; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2029_01 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2029_02; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2029_02 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2029_03; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2029_03 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2029_04; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2029_04 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2029_05; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2029_05 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2029_06; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2029_06 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2029_07; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2029_07 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2029_08; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2029_08 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2029_09; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2029_09 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2029_10; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2029_10 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2029_11; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2029_11 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2029_12; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2029_12 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2030_01; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2030_01 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2030_02; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2030_02 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2030_03; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2030_03 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2030_04; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2030_04 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2030_05; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2030_05 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2030_06; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2030_06 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2030_07; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2030_07 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2030_08; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2030_08 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2030_09; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2030_09 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2030_10; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2030_10 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2030_11; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2030_11 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: news_all_2030_12; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_all_2030_12 (id, headline, summary, category, impact_scope, importance_score, sentiment, crime_severity, emergency_type, is_national, state_id, district_id, tags, entities, source_context, financial_type, financial_amount, financial_currency, financial_denomination, financial_status, financial_industries, broadcast_date, created_at) FROM stdin;
\.


--
-- Data for Name: plans; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.plans (id, name, token_per_day, token_per_minute, created_at, max_key) FROM stdin;
1	Free	100	10	2026-06-11 17:47:09.899497	5
2	Pro	1000	100	2026-06-11 17:47:09.899497	10
3	Enterprise	10000	1000	2026-06-11 17:47:09.899497	21
\.


--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.refresh_tokens (id, user_id, token_hash, expires_at, created_at, ip, user_agent, jwt_id, revoked_at) FROM stdin;
71506632-c62c-4dfe-9c81-ffe683967a47	2cfef765-be93-4f01-b96f-88f2b2b2ec39	$2b$10$j3ciWK0inFQuBc.N3WqDruap7rxXcCqeNcXwgdQjM1GTZY9ThOLua	2026-06-23 22:51:23.85775	2026-06-16 22:51:23.85775	::1	{"cookie":"accessToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMmNmZWY3NjUtYmU5My00ZjAxLWI5NmYtODhmMmIyYjJlYzM5IiwiZ29vZ2xlX2lkIjoiMTAyOTg2NzMzMTM1NTI2MDc1NjIyIiwiZW1haWwiOiJhLmkubS5sLnN0YXJrLjMwMDBAZ21haWwuY29tIiwicGljdHVyZSI6Imh0dHBzOi8vbGgzLmdvb2dsZXVzZXJjb250ZW50LmNvbS9hL0FDZzhvY0xjTWNhMllKNXFXMjdGUldmWmJ0VnRiXzFwMWlBajUtX1RjUHY2V1F0SUZyX1kydz1zOTYtYyIsImRpc3BsYXlfbmFtZSI6IkEuSS4gTS5sLiIsInBsYW4iOjEsImlhdCI6MTc4MTYyOTg5NiwiZXhwIjoxNzgxNjI5OTU2fQ._MTbnoQbGh1RI8fyIxfA1wdkGuZ0KNEkYr5ide-1xvY; refreshToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjJjZmVmNzY1LWJlOTMtNGYwMS1iOTZmLTg4ZjJiMmIyZWMzOSIsImp3dF9pZCI6ImUxZTExYjIxLTU2MGItNDAzNC1iYjdhLWM3YmU3ZjI5MTZkMCIsImlhdCI6MTc4MTYyOTg5NiwiZXhwIjoxNzgyMjM0Njk2fQ.zngSZKEhbJLhnzAy7jmnkb4g82O9S65GU-GNPv1c4lM","accept-language":"en-US,en;q=0.9","accept-encoding":"gzip, deflate, br, zstd","referer":"http://localhost:3000/","sec-fetch-dest":"empty","sec-fetch-mode":"cors","sec-fetch-site":"same-origin","origin":"http://localhost:3000","sec-ch-ua-mobile":"?0","sec-ch-ua":"\\"Google Chrome\\";v=\\"149\\", \\"Chromium\\";v=\\"149\\", \\"Not)A;Brand\\";v=\\"24\\"","accept":"application/json","user-agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36","sec-ch-ua-platform":"\\"Windows\\"","content-length":"0","connection":"close","host":"localhost:5000"}	3462f608-374c-4354-9642-b543fddb7771	2026-06-16 22:51:24.569675
2083d510-6473-4afd-b29e-f02edac306f5	2cfef765-be93-4f01-b96f-88f2b2b2ec39	$2b$10$OrxuHzl1B7oCFJrK18TYNOPpnYB04cXjJUl80mT4xCG9mKnOUc.pe	2026-07-16 22:51:27.943063	2026-06-16 22:51:27.943063	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36	5c6fe870-79df-49b4-a75d-c5ac8e13ce12	2026-06-16 22:52:37.339846
48bc33fc-cb2b-4415-b490-b40cb0c269ce	2cfef765-be93-4f01-b96f-88f2b2b2ec39	$2b$10$8GEZmwZXd0fUyduyIkJr3.lsqXL.4.5Bf1Yo8v8SSOjWoSvJw0aQ.	2026-06-23 22:52:38.528846	2026-06-16 22:52:38.528846	::1	{"cookie":"accessToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMmNmZWY3NjUtYmU5My00ZjAxLWI5NmYtODhmMmIyYjJlYzM5IiwiZ29vZ2xlX2lkIjoiMTAyOTg2NzMzMTM1NTI2MDc1NjIyIiwiZW1haWwiOiJhLmkubS5sLnN0YXJrLjMwMDBAZ21haWwuY29tIiwicGljdHVyZSI6Imh0dHBzOi8vbGgzLmdvb2dsZXVzZXJjb250ZW50LmNvbS9hL0FDZzhvY0xjTWNhMllKNXFXMjdGUldmWmJ0VnRiXzFwMWlBajUtX1RjUHY2V1F0SUZyX1kydz1zOTYtYyIsImRpc3BsYXlfbmFtZSI6IkEuSS4gTS5sLiIsInBsYW4iOjEsImlhdCI6MTc4MTYzMDQ4NywiZXhwIjoxNzgxNjMwNTQ3fQ.ulrTeKwwqw8W7GdVvqKggMpOpX7Z3E-Ik5PCf4o9VE8; refreshToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjJjZmVmNzY1LWJlOTMtNGYwMS1iOTZmLTg4ZjJiMmIyZWMzOSIsImp3dF9pZCI6IjA2Njk3ODVhLTdmODQtNDBlNi1iMzM0LTgzYmM5MDZmZmI5ZiIsImlhdCI6MTc4MTYzMDU1OCwiZXhwIjoxNzgyMjM1MzU4fQ.4FiQcaWhqqedVfEYlERSO3exUwBW3xvKajfYkXLeTdk","accept-language":"en-US,en;q=0.9","accept-encoding":"gzip, deflate, br, zstd","referer":"http://localhost:3000/","sec-fetch-dest":"empty","sec-fetch-mode":"cors","sec-fetch-site":"same-origin","origin":"http://localhost:3000","sec-ch-ua-mobile":"?0","sec-ch-ua":"\\"Google Chrome\\";v=\\"149\\", \\"Chromium\\";v=\\"149\\", \\"Not)A;Brand\\";v=\\"24\\"","accept":"application/json","user-agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36","sec-ch-ua-platform":"\\"Windows\\"","content-length":"0","connection":"close","host":"localhost:5000"}	1f1676ea-11c7-4dc7-93dd-3488345d06a0	2026-06-16 22:52:54.866917
115f67e2-81e6-47fb-a8a2-38dd4ac6ddfd	2cfef765-be93-4f01-b96f-88f2b2b2ec39	$2b$10$y8H2jp.WlT.iW2gVgpWlmebDQZ98KEyXCYh/5GLZ4da.Qy6t1LHqy	2026-06-23 22:52:54.866917	2026-06-16 22:52:54.866917	::1	{"cookie":"accessToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMmNmZWY3NjUtYmU5My00ZjAxLWI5NmYtODhmMmIyYjJlYzM5IiwiZ29vZ2xlX2lkIjoiMTAyOTg2NzMzMTM1NTI2MDc1NjIyIiwiZW1haWwiOiJhLmkubS5sLnN0YXJrLjMwMDBAZ21haWwuY29tIiwicGljdHVyZSI6Imh0dHBzOi8vbGgzLmdvb2dsZXVzZXJjb250ZW50LmNvbS9hL0FDZzhvY0xjTWNhMllKNXFXMjdGUldmWmJ0VnRiXzFwMWlBajUtX1RjUHY2V1F0SUZyX1kydz1zOTYtYyIsImRpc3BsYXlfbmFtZSI6IkEuSS4gTS5sLiIsInBsYW4iOjEsImlhdCI6MTc4MTYzMDQ4NywiZXhwIjoxNzgxNjMwNTQ3fQ.ulrTeKwwqw8W7GdVvqKggMpOpX7Z3E-Ik5PCf4o9VE8; refreshToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjJjZmVmNzY1LWJlOTMtNGYwMS1iOTZmLTg4ZjJiMmIyZWMzOSIsImp3dF9pZCI6IjFmMTY3NmVhLTExYzctNGRjNy05M2RkLTM0ODgzNDVkMDZhMCIsImlhdCI6MTc4MTYzMDU1OCwiZXhwIjoxNzgyMjM1MzU4fQ.4obeVDHfJ5ZSfsXyWKX3IJwzPzDyz1Vjfd_FXcvL6ek","accept-language":"en-US,en;q=0.9","accept-encoding":"gzip, deflate, br, zstd","referer":"http://localhost:3000/","sec-fetch-dest":"empty","sec-fetch-mode":"cors","sec-fetch-site":"same-origin","origin":"http://localhost:3000","sec-ch-ua-mobile":"?0","sec-ch-ua":"\\"Google Chrome\\";v=\\"149\\", \\"Chromium\\";v=\\"149\\", \\"Not)A;Brand\\";v=\\"24\\"","accept":"application/json","user-agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36","sec-ch-ua-platform":"\\"Windows\\"","content-length":"0","connection":"close","host":"localhost:5000"}	8f0dee8f-84e9-4f34-93eb-f87b82e95f18	2026-06-16 22:52:55.488701
7ab9d7fa-4152-4d9c-a15b-9642f6c50423	2cfef765-be93-4f01-b96f-88f2b2b2ec39	$2b$10$G4crGea.OOGyXm1cvnxV2OrbIKJ8xhI14cG1zK4z078Cv9lIjIaMa	2026-06-23 22:52:56.358468	2026-06-16 22:52:56.358468	::1	{"cookie":"accessToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMmNmZWY3NjUtYmU5My00ZjAxLWI5NmYtODhmMmIyYjJlYzM5IiwiZ29vZ2xlX2lkIjoiMTAyOTg2NzMzMTM1NTI2MDc1NjIyIiwiZW1haWwiOiJhLmkubS5sLnN0YXJrLjMwMDBAZ21haWwuY29tIiwicGljdHVyZSI6Imh0dHBzOi8vbGgzLmdvb2dsZXVzZXJjb250ZW50LmNvbS9hL0FDZzhvY0xjTWNhMllKNXFXMjdGUldmWmJ0VnRiXzFwMWlBajUtX1RjUHY2V1F0SUZyX1kydz1zOTYtYyIsImRpc3BsYXlfbmFtZSI6IkEuSS4gTS5sLiIsInBsYW4iOjEsImlhdCI6MTc4MTYzMDQ4NywiZXhwIjoxNzgxNjMwNTQ3fQ.ulrTeKwwqw8W7GdVvqKggMpOpX7Z3E-Ik5PCf4o9VE8; refreshToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjJjZmVmNzY1LWJlOTMtNGYwMS1iOTZmLTg4ZjJiMmIyZWMzOSIsImp3dF9pZCI6ImYyZTNmNDFmLTUyNmQtNGRkYS1hZTlkLWY5MWRhYzllNDJjYSIsImlhdCI6MTc4MTYzMDU3NSwiZXhwIjoxNzgyMjM1Mzc1fQ.XviGFdB_-FZ1kIM1-88SyIyop1keeQMy5YxdQOTSkE4","accept-language":"en-US,en;q=0.9","accept-encoding":"gzip, deflate, br, zstd","referer":"http://localhost:3000/","sec-fetch-dest":"empty","sec-fetch-mode":"cors","sec-fetch-site":"same-origin","origin":"http://localhost:3000","sec-ch-ua-mobile":"?0","sec-ch-ua":"\\"Google Chrome\\";v=\\"149\\", \\"Chromium\\";v=\\"149\\", \\"Not)A;Brand\\";v=\\"24\\"","accept":"application/json","user-agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36","sec-ch-ua-platform":"\\"Windows\\"","content-length":"0","connection":"close","host":"localhost:5000"}	b84cc0bd-64c9-4287-967a-b3c9293297cc	2026-06-16 23:27:44.811014
2a233ac2-4425-4c90-88ac-eebecc347b7b	2cfef765-be93-4f01-b96f-88f2b2b2ec39	$2b$10$BjuE3YQVZ.g.Fq7/jWkwk.EJSIQkzz.1Mgsz5XKbji5SgM3SvtLkO	2026-07-17 01:28:50.406046	2026-06-17 01:28:50.406046	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36	2ac5f8eb-d086-4916-b425-c0874b6675ce	2026-06-17 01:31:48.607731
dbd9cf7f-7daf-43c1-bb6e-357a8eab93ee	2cfef765-be93-4f01-b96f-88f2b2b2ec39	$2b$10$nncSgB295MB0UIeCxYSI9O/HJwB8z4E.aMheBIVqef5RlVoSRDq1i	2026-07-17 02:03:17.806392	2026-06-17 02:03:17.806392	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36	44b26712-cb26-42c6-9eda-5e6fe69351f9	2026-06-17 02:03:17.806392
e3cc53b4-0c4c-4ae6-b09c-5510644d6cf9	2cfef765-be93-4f01-b96f-88f2b2b2ec39	$2b$10$FdCQJGgWggcKGcw9knEvzeZlJBnpJxEnN3ZR2KPSYOvOn0Ba.6B1.	2026-07-17 02:27:35.069435	2026-06-17 02:27:35.069435	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36	ec71e580-a20b-4cff-96eb-245e593329c7	2026-06-17 02:32:05.945494
d10f63a1-1e71-4190-a4b8-a9b3fcc81c34	2cfef765-be93-4f01-b96f-88f2b2b2ec39	$2b$10$98QTTa8Vg8b/rs9E63Bp4utP85sD3Dy5LNcCerRBdQNzlEDMfCXDm	2026-07-16 22:34:44.999157	2026-06-16 22:34:44.999157	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36	908c705b-df7a-4cce-9e05-62ecaa389594	2026-06-16 22:34:44.999157
6da7d644-3b95-4dab-b11d-aa2d7ab76a2f	2cfef765-be93-4f01-b96f-88f2b2b2ec39	$2b$10$oI179FSq./qEHF2LoKj.j.Q/ZaGp.bDmcq0stJFIN5Vg5W0i.gX5.	2026-06-23 22:51:24.569675	2026-06-16 22:51:24.569675	::1	{"cookie":"accessToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMmNmZWY3NjUtYmU5My00ZjAxLWI5NmYtODhmMmIyYjJlYzM5IiwiZ29vZ2xlX2lkIjoiMTAyOTg2NzMzMTM1NTI2MDc1NjIyIiwiZW1haWwiOiJhLmkubS5sLnN0YXJrLjMwMDBAZ21haWwuY29tIiwicGljdHVyZSI6Imh0dHBzOi8vbGgzLmdvb2dsZXVzZXJjb250ZW50LmNvbS9hL0FDZzhvY0xjTWNhMllKNXFXMjdGUldmWmJ0VnRiXzFwMWlBajUtX1RjUHY2V1F0SUZyX1kydz1zOTYtYyIsImRpc3BsYXlfbmFtZSI6IkEuSS4gTS5sLiIsInBsYW4iOjEsImlhdCI6MTc4MTYyOTg5NiwiZXhwIjoxNzgxNjI5OTU2fQ._MTbnoQbGh1RI8fyIxfA1wdkGuZ0KNEkYr5ide-1xvY; refreshToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjJjZmVmNzY1LWJlOTMtNGYwMS1iOTZmLTg4ZjJiMmIyZWMzOSIsImp3dF9pZCI6IjM0NjJmNjA4LTM3NGMtNDM1NC05NjQyLWI1NDNmZGRiNzc3MSIsImlhdCI6MTc4MTYzMDQ4NCwiZXhwIjoxNzgyMjM1Mjg0fQ.FT-zULMzkUZ1oBNxFEUPry7tseiYpDahxUnfWSA7luM","accept-language":"en-US,en;q=0.9","accept-encoding":"gzip, deflate, br, zstd","referer":"http://localhost:3000/","sec-fetch-dest":"empty","sec-fetch-mode":"cors","sec-fetch-site":"same-origin","origin":"http://localhost:3000","sec-ch-ua-mobile":"?0","sec-ch-ua":"\\"Google Chrome\\";v=\\"149\\", \\"Chromium\\";v=\\"149\\", \\"Not)A;Brand\\";v=\\"24\\"","accept":"application/json","user-agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36","sec-ch-ua-platform":"\\"Windows\\"","content-length":"0","connection":"close","host":"localhost:5000"}	0e3315a4-68f3-4c4c-8acb-ed8e22a67a29	2026-06-16 22:51:25.154024
b5bea3c8-cb9a-4882-bf38-0b0e35247aad	2cfef765-be93-4f01-b96f-88f2b2b2ec39	$2b$10$5dPqYNqgsS/yw0TBDOUBluAIZKK5uugbsk3ex9QzEFh.6r1E3L3Jm	2026-06-23 22:52:37.339846	2026-06-16 22:52:37.339846	::1	{"cookie":"accessToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMmNmZWY3NjUtYmU5My00ZjAxLWI5NmYtODhmMmIyYjJlYzM5IiwiZ29vZ2xlX2lkIjoiMTAyOTg2NzMzMTM1NTI2MDc1NjIyIiwiZW1haWwiOiJhLmkubS5sLnN0YXJrLjMwMDBAZ21haWwuY29tIiwicGljdHVyZSI6Imh0dHBzOi8vbGgzLmdvb2dsZXVzZXJjb250ZW50LmNvbS9hL0FDZzhvY0xjTWNhMllKNXFXMjdGUldmWmJ0VnRiXzFwMWlBajUtX1RjUHY2V1F0SUZyX1kydz1zOTYtYyIsImRpc3BsYXlfbmFtZSI6IkEuSS4gTS5sLiIsInBsYW4iOjEsImlhdCI6MTc4MTYzMDQ4NywiZXhwIjoxNzgxNjMwNTQ3fQ.ulrTeKwwqw8W7GdVvqKggMpOpX7Z3E-Ik5PCf4o9VE8; refreshToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjJjZmVmNzY1LWJlOTMtNGYwMS1iOTZmLTg4ZjJiMmIyZWMzOSIsImp3dF9pZCI6IjVjNmZlODcwLTc5ZGYtNDliNC1hNzVkLWM1YWM4ZTEzY2UxMiIsImlhdCI6MTc4MTYzMDQ4NywiZXhwIjoxNzgyMjM1Mjg3fQ.BaEOTGb3ER4kt0oZRsU_yo_bPs7vuUx-lbrGOHDaVBk","accept-language":"en-US,en;q=0.9","accept-encoding":"gzip, deflate, br, zstd","referer":"http://localhost:3000/","sec-fetch-dest":"empty","sec-fetch-mode":"cors","sec-fetch-site":"same-origin","origin":"http://localhost:3000","sec-ch-ua-mobile":"?0","sec-ch-ua":"\\"Google Chrome\\";v=\\"149\\", \\"Chromium\\";v=\\"149\\", \\"Not)A;Brand\\";v=\\"24\\"","accept":"application/json","user-agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36","sec-ch-ua-platform":"\\"Windows\\"","content-length":"0","connection":"close","host":"localhost:5000"}	3be319d1-d870-4627-81b5-2ef6843e2f59	2026-06-16 22:52:37.949182
4419c77d-44ee-49c2-a40e-e50944cf5fd2	2cfef765-be93-4f01-b96f-88f2b2b2ec39	$2b$10$6yhqOw6soSD/rwI3raWU1.lIr0IWssnP6kB57oOlFf1EVwSlpCwQa	2026-06-23 22:52:55.488701	2026-06-16 22:52:55.488701	::1	{"cookie":"accessToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMmNmZWY3NjUtYmU5My00ZjAxLWI5NmYtODhmMmIyYjJlYzM5IiwiZ29vZ2xlX2lkIjoiMTAyOTg2NzMzMTM1NTI2MDc1NjIyIiwiZW1haWwiOiJhLmkubS5sLnN0YXJrLjMwMDBAZ21haWwuY29tIiwicGljdHVyZSI6Imh0dHBzOi8vbGgzLmdvb2dsZXVzZXJjb250ZW50LmNvbS9hL0FDZzhvY0xjTWNhMllKNXFXMjdGUldmWmJ0VnRiXzFwMWlBajUtX1RjUHY2V1F0SUZyX1kydz1zOTYtYyIsImRpc3BsYXlfbmFtZSI6IkEuSS4gTS5sLiIsInBsYW4iOjEsImlhdCI6MTc4MTYzMDQ4NywiZXhwIjoxNzgxNjMwNTQ3fQ.ulrTeKwwqw8W7GdVvqKggMpOpX7Z3E-Ik5PCf4o9VE8; refreshToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjJjZmVmNzY1LWJlOTMtNGYwMS1iOTZmLTg4ZjJiMmIyZWMzOSIsImp3dF9pZCI6IjhmMGRlZThmLTg0ZTktNGYzNC05M2ViLWY4N2I4MmU5NWYxOCIsImlhdCI6MTc4MTYzMDU3NSwiZXhwIjoxNzgyMjM1Mzc1fQ.QIjT0azVpV6Ugk40dii5v_2B9NUzBvvTqoYq-B2GEYc","accept-language":"en-US,en;q=0.9","accept-encoding":"gzip, deflate, br, zstd","referer":"http://localhost:3000/","sec-fetch-dest":"empty","sec-fetch-mode":"cors","sec-fetch-site":"same-origin","origin":"http://localhost:3000","sec-ch-ua-mobile":"?0","sec-ch-ua":"\\"Google Chrome\\";v=\\"149\\", \\"Chromium\\";v=\\"149\\", \\"Not)A;Brand\\";v=\\"24\\"","accept":"application/json","user-agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36","sec-ch-ua-platform":"\\"Windows\\"","content-length":"0","connection":"close","host":"localhost:5000"}	f2e3f41f-526d-4dda-ae9d-f91dac9e42ca	2026-06-16 22:52:56.358468
3832819d-c248-48fc-aa11-834b01c12fc0	2cfef765-be93-4f01-b96f-88f2b2b2ec39	$2b$10$F9V1dxpPImNvGEb2D7yetOkgyGWfLKTiJcOhW5YX0JBoL0hKTEDwC	2026-06-23 23:27:44.811014	2026-06-16 23:27:44.811014	::1	{"cookie":"refreshToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjJjZmVmNzY1LWJlOTMtNGYwMS1iOTZmLTg4ZjJiMmIyZWMzOSIsImp3dF9pZCI6ImI4NGNjMGJkLTY0YzktNDI4Ny05NjdhLWIzYzkyOTMyOTdjYyIsImlhdCI6MTc4MTYzMDU3NiwiZXhwIjoxNzgyMjM1Mzc2fQ.163dfWG_7I0Hpf8DWnB53l9PY-MyHogdO82p5sL5s8U","accept-language":"en-US,en;q=0.9","accept-encoding":"gzip, deflate, br, zstd","referer":"http://localhost:3000/","sec-fetch-dest":"empty","sec-fetch-mode":"cors","sec-fetch-site":"same-origin","origin":"http://localhost:3000","sec-ch-ua-mobile":"?0","sec-ch-ua":"\\"Google Chrome\\";v=\\"149\\", \\"Chromium\\";v=\\"149\\", \\"Not)A;Brand\\";v=\\"24\\"","accept":"application/json","user-agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36","sec-ch-ua-platform":"\\"Windows\\"","content-length":"0","connection":"close","host":"localhost:5000"}	8b19cd74-b81a-4753-857c-9100cd806e1e	2026-06-16 23:27:45.790964
592f4c91-6fd9-4d04-9c2f-4ed1b6ddf289	2cfef765-be93-4f01-b96f-88f2b2b2ec39	$2b$10$uTuTkU4v47dPnjfhao9Da..n74vsD2ivfSBlHJQFZwi0HYb9jSdEC	2026-06-23 23:27:45.790964	2026-06-16 23:27:45.790964	::1	{"cookie":"refreshToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjJjZmVmNzY1LWJlOTMtNGYwMS1iOTZmLTg4ZjJiMmIyZWMzOSIsImp3dF9pZCI6IjhiMTljZDc0LWI4MWEtNDc1My04NTdjLTkxMDBjZDgwNmUxZSIsImlhdCI6MTc4MTYzMjY2NSwiZXhwIjoxNzgyMjM3NDY1fQ.5cPFpUesNbnNFgGv4yG-SpcbwKW2MBMFbjE4N48oez0; acessToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMmNmZWY3NjUtYmU5My00ZjAxLWI5NmYtODhmMmIyYjJlYzM5IiwiZ29vZ2xlX2lkIjoiMTAyOTg2NzMzMTM1NTI2MDc1NjIyIiwiZW1haWwiOiJhLmkubS5sLnN0YXJrLjMwMDBAZ21haWwuY29tIiwicGljdHVyZSI6Imh0dHBzOi8vbGgzLmdvb2dsZXVzZXJjb250ZW50LmNvbS9hL0FDZzhvY0xjTWNhMllKNXFXMjdGUldmWmJ0VnRiXzFwMWlBajUtX1RjUHY2V1F0SUZyX1kydz1zOTYtYyIsImRpc3BsYXlfbmFtZSI6IkEuSS4gTS5sLiIsInBsYW5faWQiOjEsImlhdCI6MTc4MTYzMjY2NSwiZXhwIjo0MzczNjMyNjY1fQ.vG0uWvNpvuzbyq9Xn2XS0sdixCESfHFAru2Qs3FziU4","accept-language":"en-US,en;q=0.9","accept-encoding":"gzip, deflate, br, zstd","referer":"http://localhost:3000/","sec-fetch-dest":"empty","sec-fetch-mode":"cors","sec-fetch-site":"same-origin","origin":"http://localhost:3000","sec-ch-ua-mobile":"?0","sec-ch-ua":"\\"Google Chrome\\";v=\\"149\\", \\"Chromium\\";v=\\"149\\", \\"Not)A;Brand\\";v=\\"24\\"","accept":"application/json","user-agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36","sec-ch-ua-platform":"\\"Windows\\"","content-length":"0","connection":"close","host":"localhost:5000"}	53043ac4-aa9f-47f9-b453-79f6cdd7c3ce	2026-06-16 23:27:45.790964
29beffb9-66c4-49f4-9df6-653156a6daa8	fa61f3e0-14ea-4ce1-bfd8-9701f5960dcd	$2b$10$snIfk/4T9pAwjf2RDABQNu/.ZyPHUrt5LXCeWzaFuwvVWRU35CJ.O	2026-07-17 01:52:11.260809	2026-06-17 01:52:11.260809	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36	f7c27434-ba56-4a26-a676-17af42ee1f55	2026-06-17 01:52:11.260809
64a5f08a-f9de-4bb6-914d-19ac68d2a7ca	2cfef765-be93-4f01-b96f-88f2b2b2ec39	$2b$10$utar2hZ8rrisLGAiA.QFHu1Foaxh5VCkvh.BB.Pe6/9PvVVBLJ/8q	2026-07-16 22:41:36.295122	2026-06-16 22:41:36.295122	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36	e1e11b21-560b-4034-bb7a-c7be7f2916d0	2026-06-16 22:51:23.85775
024191f9-1a9e-4300-b5dc-28a7a173c43d	2cfef765-be93-4f01-b96f-88f2b2b2ec39	$2b$10$VPEd/FEARWPv2/Jeud8K0e4foM8QXvg5N.zBleJ2wBwr.Se8t.sqG	2026-06-23 22:51:25.154024	2026-06-16 22:51:25.154024	::1	{"cookie":"accessToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMmNmZWY3NjUtYmU5My00ZjAxLWI5NmYtODhmMmIyYjJlYzM5IiwiZ29vZ2xlX2lkIjoiMTAyOTg2NzMzMTM1NTI2MDc1NjIyIiwiZW1haWwiOiJhLmkubS5sLnN0YXJrLjMwMDBAZ21haWwuY29tIiwicGljdHVyZSI6Imh0dHBzOi8vbGgzLmdvb2dsZXVzZXJjb250ZW50LmNvbS9hL0FDZzhvY0xjTWNhMllKNXFXMjdGUldmWmJ0VnRiXzFwMWlBajUtX1RjUHY2V1F0SUZyX1kydz1zOTYtYyIsImRpc3BsYXlfbmFtZSI6IkEuSS4gTS5sLiIsInBsYW4iOjEsImlhdCI6MTc4MTYyOTg5NiwiZXhwIjoxNzgxNjI5OTU2fQ._MTbnoQbGh1RI8fyIxfA1wdkGuZ0KNEkYr5ide-1xvY; refreshToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjJjZmVmNzY1LWJlOTMtNGYwMS1iOTZmLTg4ZjJiMmIyZWMzOSIsImp3dF9pZCI6IjBlMzMxNWE0LTY4ZjMtNGM0Yy04YWNiLWVkOGUyMmE2N2EyOSIsImlhdCI6MTc4MTYzMDQ4NCwiZXhwIjoxNzgyMjM1Mjg0fQ.CqfxNo2axjNWuPvx_ResAzL_LJWKy7XaaP2mnl8OqQY","accept-language":"en-US,en;q=0.9","accept-encoding":"gzip, deflate, br, zstd","referer":"http://localhost:3000/","sec-fetch-dest":"empty","sec-fetch-mode":"cors","sec-fetch-site":"same-origin","origin":"http://localhost:3000","sec-ch-ua-mobile":"?0","sec-ch-ua":"\\"Google Chrome\\";v=\\"149\\", \\"Chromium\\";v=\\"149\\", \\"Not)A;Brand\\";v=\\"24\\"","accept":"application/json","user-agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36","sec-ch-ua-platform":"\\"Windows\\"","content-length":"0","connection":"close","host":"localhost:5000"}	52bb9357-d1ac-4f41-aee8-f28e2208c47f	2026-06-16 22:51:25.154024
257b3ee6-f11d-47a9-95be-8ed430922dec	2cfef765-be93-4f01-b96f-88f2b2b2ec39	$2b$10$NErmvyv/k//03wG1xzXlA./Sbf1AVja.K2rOG697hGurCTCwNX3XC	2026-06-23 22:52:37.949182	2026-06-16 22:52:37.949182	::1	{"cookie":"accessToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMmNmZWY3NjUtYmU5My00ZjAxLWI5NmYtODhmMmIyYjJlYzM5IiwiZ29vZ2xlX2lkIjoiMTAyOTg2NzMzMTM1NTI2MDc1NjIyIiwiZW1haWwiOiJhLmkubS5sLnN0YXJrLjMwMDBAZ21haWwuY29tIiwicGljdHVyZSI6Imh0dHBzOi8vbGgzLmdvb2dsZXVzZXJjb250ZW50LmNvbS9hL0FDZzhvY0xjTWNhMllKNXFXMjdGUldmWmJ0VnRiXzFwMWlBajUtX1RjUHY2V1F0SUZyX1kydz1zOTYtYyIsImRpc3BsYXlfbmFtZSI6IkEuSS4gTS5sLiIsInBsYW4iOjEsImlhdCI6MTc4MTYzMDQ4NywiZXhwIjoxNzgxNjMwNTQ3fQ.ulrTeKwwqw8W7GdVvqKggMpOpX7Z3E-Ik5PCf4o9VE8; refreshToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjJjZmVmNzY1LWJlOTMtNGYwMS1iOTZmLTg4ZjJiMmIyZWMzOSIsImp3dF9pZCI6IjNiZTMxOWQxLWQ4NzAtNDYyNy04MWI1LTJlZjY4NDNlMmY1OSIsImlhdCI6MTc4MTYzMDU1NywiZXhwIjoxNzgyMjM1MzU3fQ.W0zoIXfbNmVaHh3VHM_27Z9uoDSoboiFPGlGJYSUxA8","accept-language":"en-US,en;q=0.9","accept-encoding":"gzip, deflate, br, zstd","referer":"http://localhost:3000/","sec-fetch-dest":"empty","sec-fetch-mode":"cors","sec-fetch-site":"same-origin","origin":"http://localhost:3000","sec-ch-ua-mobile":"?0","sec-ch-ua":"\\"Google Chrome\\";v=\\"149\\", \\"Chromium\\";v=\\"149\\", \\"Not)A;Brand\\";v=\\"24\\"","accept":"application/json","user-agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36","sec-ch-ua-platform":"\\"Windows\\"","content-length":"0","connection":"close","host":"localhost:5000"}	0669785a-7f84-40e6-b334-83bc906ffb9f	2026-06-16 22:52:38.528846
891d2db6-dc8d-48dc-a441-f19b253ce506	2cfef765-be93-4f01-b96f-88f2b2b2ec39	$2b$10$a5KL7.KUkbJyLp0yRou1texqtG7DxgIboOiFs87Ubc28HGmDnsjRO	2026-07-16 23:27:49.577282	2026-06-16 23:27:49.577282	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36	7b960725-a621-4f1b-aab7-21c94ab5a4e1	2026-06-16 23:30:16.788173
d8a7833e-5334-4ef7-944d-2281152eb363	2cfef765-be93-4f01-b96f-88f2b2b2ec39	$2b$10$.d2lVFVwhOpurrAjSxt2XOlJ7je.8LuR92aJ/0b9F5ivOEElbUWfi	2026-07-17 01:24:22.196311	2026-06-17 01:24:22.196311	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36	38b54fe1-2d62-4d2d-b324-0b8ddc74df15	2026-06-17 01:24:22.196311
c2698be6-bce9-42c4-aeda-53c4b05fa086	2cfef765-be93-4f01-b96f-88f2b2b2ec39	$2b$10$U.I1QfO1ZLuAA1W/teZX7uO5xeUuPPJ1Th5Arz85zuMQy79qBasia	2026-07-17 01:24:26.557272	2026-06-17 01:24:26.557272	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36	3ccb9023-8759-4887-81f0-d427d4e57198	2026-06-17 01:24:26.557272
65232d02-bf40-40cb-b7f0-14c8d3da9035	2cfef765-be93-4f01-b96f-88f2b2b2ec39	$2b$10$2GVZC34a4k4hg5SgTA5qCOjY.al3N1xs4WpdKhN1aYyRcKcycaUG2	2026-07-17 01:24:32.893949	2026-06-17 01:24:32.893949	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36	d5a56e93-e55e-4bc4-ac3a-7bb3f8de77bb	2026-06-17 01:24:32.893949
e623bf5d-0d34-433b-8e8a-f006c657f9fc	fa61f3e0-14ea-4ce1-bfd8-9701f5960dcd	$2b$10$qGVt1XxOzLKhwjTeohCxbufQv41fe./61fbH3CjmWzcCqbuePycOK	2026-07-17 02:02:25.154835	2026-06-17 02:02:25.154835	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36	e77273a9-aee2-4e5d-a5ce-3c03f92cd2eb	2026-06-17 02:02:25.154835
6642f477-88d5-4be3-9177-85274e3a35f1	2cfef765-be93-4f01-b96f-88f2b2b2ec39	$2b$10$IXEmQk/XePFnl80l42JoxeXHD5FSib6het1qNo0Uljv.0Eu4S4YgS	2026-07-17 02:37:18.439694	2026-06-17 02:37:18.439694	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36	828df2a1-d326-4a8b-8f27-eb332fdca44e	2026-06-17 02:41:17.237624
5c262afb-64e4-45aa-af48-b3eba9b0b6b8	fa61f3e0-14ea-4ce1-bfd8-9701f5960dcd	$2b$10$R8szCbNwEB62QiTaK3E3cuMPrmbM3Hl5cWSWVPk6LXg829gCVBvK.	2026-07-17 02:24:05.881228	2026-06-17 02:24:05.881228	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36	c1ca00d2-2155-45b0-9bf4-19d9a90473b8	2026-06-17 12:12:04.812828
0c4c2607-cafd-44e4-848d-96063f21432f	fa61f3e0-14ea-4ce1-bfd8-9701f5960dcd	$2b$10$wHrovuHmhFsfe6/FRhlwR.oUK0vIFw7HVcq37K1MJv7ZUIN2B7JAG	2026-06-24 12:12:04.812828	2026-06-17 12:12:04.812828	::1	{"host":"localhost:5000","connection":"keep-alive","content-length":"0","sec-ch-ua-platform":"\\"Windows\\"","user-agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36 Edg/149.0.0.0","accept":"application/json","sec-ch-ua":"\\"Microsoft Edge\\";v=\\"149\\", \\"Chromium\\";v=\\"149\\", \\"Not)A;Brand\\";v=\\"24\\"","sec-ch-ua-mobile":"?0","origin":"http://localhost:3000","sec-fetch-site":"cross-site","sec-fetch-mode":"cors","sec-fetch-dest":"empty","sec-fetch-storage-access":"active","referer":"http://localhost:3000/","accept-encoding":"gzip, deflate, br, zstd","accept-language":"en-US,en;q=0.9,en-IN;q=0.8","cookie":"refreshToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImZhNjFmM2UwLTE0ZWEtNGNlMS1iZmQ4LTk3MDFmNTk2MGRjZCIsImp3dF9pZCI6ImMxY2EwMGQyLTIxNTUtNDViMC05YmY0LTE5ZDlhOTA0NzNiOCIsImlhdCI6MTc4MTY0MzI0NSwiZXhwIjo0MzczNjQzMjQ1fQ.DVcU-YhGqGSDaFZtrbah6aoMtS1oY858EI6Toh_krog"}	8c11dfd1-eeb0-49b7-b234-a0dad5401476	2026-06-17 12:12:04.812828
68a031da-4dbc-46c6-9dbf-823d1cacd310	fa61f3e0-14ea-4ce1-bfd8-9701f5960dcd	$2b$10$yckoPs14pC2AaTktUK1PC.1hdtxsvXonVu4CH1JnMzDkK.iJMxeqy	2026-07-17 12:15:12.876767	2026-06-17 12:15:12.876767	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36 Edg/149.0.0.0	0e818764-9bb3-46e5-a5f6-e4c6544a4791	2026-06-19 18:16:04.222694
ffc5d7cd-50c2-4564-82ef-3faeae2fbae6	2cfef765-be93-4f01-b96f-88f2b2b2ec39	$2b$10$MB7BmYuRkyNRJpRwpzTghuVx1nfB.YH1uSZRtDj/4DEcJJqf3OSuq	2026-06-23 23:30:16.788173	2026-06-16 23:30:16.788173	::1	{"cookie":"acessToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMmNmZWY3NjUtYmU5My00ZjAxLWI5NmYtODhmMmIyYjJlYzM5IiwiZ29vZ2xlX2lkIjoiMTAyOTg2NzMzMTM1NTI2MDc1NjIyIiwiZW1haWwiOiJhLmkubS5sLnN0YXJrLjMwMDBAZ21haWwuY29tIiwicGljdHVyZSI6Imh0dHBzOi8vbGgzLmdvb2dsZXVzZXJjb250ZW50LmNvbS9hL0FDZzhvY0xjTWNhMllKNXFXMjdGUldmWmJ0VnRiXzFwMWlBajUtX1RjUHY2V1F0SUZyX1kydz1zOTYtYyIsImRpc3BsYXlfbmFtZSI6IkEuSS4gTS5sLiIsInBsYW5faWQiOjEsImlhdCI6MTc4MTYzMjY2NSwiZXhwIjo0MzczNjMyNjY1fQ.vG0uWvNpvuzbyq9Xn2XS0sdixCESfHFAru2Qs3FziU4; refreshToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjJjZmVmNzY1LWJlOTMtNGYwMS1iOTZmLTg4ZjJiMmIyZWMzOSIsImp3dF9pZCI6IjdiOTYwNzI1LWE2MjEtNGYxYi1hYWI3LTIxYzk0YWI1YTRlMSIsImlhdCI6MTc4MTYzMjY2OSwiZXhwIjo0MzczNjMyNjY5fQ.obZRUgfOi5dl1tgkBv-CuIT9XTe_VjjEXvf6d6L2SmQ","accept-language":"en-US,en;q=0.9","accept-encoding":"gzip, deflate, br, zstd","referer":"http://localhost:3000/","sec-fetch-dest":"empty","sec-fetch-mode":"cors","sec-fetch-site":"same-origin","origin":"http://localhost:3000","sec-ch-ua-mobile":"?0","sec-ch-ua":"\\"Google Chrome\\";v=\\"149\\", \\"Chromium\\";v=\\"149\\", \\"Not)A;Brand\\";v=\\"24\\"","accept":"application/json","user-agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36","sec-ch-ua-platform":"\\"Windows\\"","content-length":"0","connection":"close","host":"localhost:5000"}	2418f365-1a4d-44e4-8c01-f89fca45073c	2026-06-16 23:30:17.444069
9570cd9a-0321-4f46-adb8-83864245b79f	2cfef765-be93-4f01-b96f-88f2b2b2ec39	$2b$10$GsAbyIF7PoYrkZuKvTBIOemnYnFoBoTeGctY11GV06Dlgl56mwcE.	2026-06-23 23:30:17.444069	2026-06-16 23:30:17.444069	::1	{"cookie":"refreshToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjJjZmVmNzY1LWJlOTMtNGYwMS1iOTZmLTg4ZjJiMmIyZWMzOSIsImp3dF9pZCI6IjI0MThmMzY1LTFhNGQtNDRlNC04YzAxLWY4OWZjYTQ1MDczYyIsImlhdCI6MTc4MTYzMjgxNiwiZXhwIjoxNzgyMjM3NjE2fQ.6GSFHSgCgNQO7QqJ8powqxSVbK8Brta8Rtrf1YG8iwM; acessToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMmNmZWY3NjUtYmU5My00ZjAxLWI5NmYtODhmMmIyYjJlYzM5IiwiZ29vZ2xlX2lkIjoiMTAyOTg2NzMzMTM1NTI2MDc1NjIyIiwiZW1haWwiOiJhLmkubS5sLnN0YXJrLjMwMDBAZ21haWwuY29tIiwicGljdHVyZSI6Imh0dHBzOi8vbGgzLmdvb2dsZXVzZXJjb250ZW50LmNvbS9hL0FDZzhvY0xjTWNhMllKNXFXMjdGUldmWmJ0VnRiXzFwMWlBajUtX1RjUHY2V1F0SUZyX1kydz1zOTYtYyIsImRpc3BsYXlfbmFtZSI6IkEuSS4gTS5sLiIsInBsYW5faWQiOjEsImlhdCI6MTc4MTYzMjgxNiwiZXhwIjo0MzczNjMyODE2fQ.bcnTCErtKxjvnpmEcxOdtUMFqrP7_goUX11kezocmEE","accept-language":"en-US,en;q=0.9","accept-encoding":"gzip, deflate, br, zstd","referer":"http://localhost:3000/","sec-fetch-dest":"empty","sec-fetch-mode":"cors","sec-fetch-site":"same-origin","origin":"http://localhost:3000","sec-ch-ua-mobile":"?0","sec-ch-ua":"\\"Google Chrome\\";v=\\"149\\", \\"Chromium\\";v=\\"149\\", \\"Not)A;Brand\\";v=\\"24\\"","accept":"application/json","user-agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36","sec-ch-ua-platform":"\\"Windows\\"","content-length":"0","connection":"close","host":"localhost:5000"}	e4c2baa5-a248-4f00-a774-3861dca86c52	2026-06-16 23:30:18.09559
9668f040-b2a0-4562-9754-82222eee02bb	2cfef765-be93-4f01-b96f-88f2b2b2ec39	$2b$10$TBhLH7SaKsRACg1EWMxeDuN0DkK61MHLSDJTZAu2rUuLP4iXPD17m	2026-06-23 23:30:18.09559	2026-06-16 23:30:18.09559	::1	{"cookie":"refreshToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjJjZmVmNzY1LWJlOTMtNGYwMS1iOTZmLTg4ZjJiMmIyZWMzOSIsImp3dF9pZCI6ImU0YzJiYWE1LWEyNDgtNGYwMC1hNzc0LTM4NjFkY2E4NmM1MiIsImlhdCI6MTc4MTYzMjgxNywiZXhwIjoxNzgyMjM3NjE3fQ.iHRmnfpbUD3ZpUGAu5lZpyJpeFVwknTUI7rJtDKR0NE; acessToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMmNmZWY3NjUtYmU5My00ZjAxLWI5NmYtODhmMmIyYjJlYzM5IiwiZ29vZ2xlX2lkIjoiMTAyOTg2NzMzMTM1NTI2MDc1NjIyIiwiZW1haWwiOiJhLmkubS5sLnN0YXJrLjMwMDBAZ21haWwuY29tIiwicGljdHVyZSI6Imh0dHBzOi8vbGgzLmdvb2dsZXVzZXJjb250ZW50LmNvbS9hL0FDZzhvY0xjTWNhMllKNXFXMjdGUldmWmJ0VnRiXzFwMWlBajUtX1RjUHY2V1F0SUZyX1kydz1zOTYtYyIsImRpc3BsYXlfbmFtZSI6IkEuSS4gTS5sLiIsInBsYW5faWQiOjEsImlhdCI6MTc4MTYzMjgxNywiZXhwIjo0MzczNjMyODE3fQ.M8V8RRHKAgLuZFwEEmJqSqL07SHHe2cUS5QrT_ZCsLU","accept-language":"en-US,en;q=0.9","accept-encoding":"gzip, deflate, br, zstd","referer":"http://localhost:3000/","sec-fetch-dest":"empty","sec-fetch-mode":"cors","sec-fetch-site":"same-origin","origin":"http://localhost:3000","sec-ch-ua-mobile":"?0","sec-ch-ua":"\\"Google Chrome\\";v=\\"149\\", \\"Chromium\\";v=\\"149\\", \\"Not)A;Brand\\";v=\\"24\\"","accept":"application/json","user-agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36","sec-ch-ua-platform":"\\"Windows\\"","content-length":"0","connection":"close","host":"localhost:5000"}	5fc91878-fc19-4be7-82a8-c8c890ecc840	2026-06-16 23:38:44.625344
c7cf994b-5833-4cfa-adee-337298ba0705	2cfef765-be93-4f01-b96f-88f2b2b2ec39	$2b$10$ch5MjtyoVj8A1RAciNoKh.wFYM3LuK.puXkeQySeOmJq.ZuQx5FAi	2026-06-23 23:38:44.625344	2026-06-16 23:38:44.625344	::1	{"cookie":"refreshToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjJjZmVmNzY1LWJlOTMtNGYwMS1iOTZmLTg4ZjJiMmIyZWMzOSIsImp3dF9pZCI6IjVmYzkxODc4LWZjMTktNGJlNy04MmE4LWM4Yzg5MGVjYzg0MCIsImlhdCI6MTc4MTYzMjgxOCwiZXhwIjoxNzgyMjM3NjE4fQ.qYC8e7uOMUfRRe0kFf678ljHpVDOCC-eIHHPq4fiI3I; acessToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMmNmZWY3NjUtYmU5My00ZjAxLWI5NmYtODhmMmIyYjJlYzM5IiwiZ29vZ2xlX2lkIjoiMTAyOTg2NzMzMTM1NTI2MDc1NjIyIiwiZW1haWwiOiJhLmkubS5sLnN0YXJrLjMwMDBAZ21haWwuY29tIiwicGljdHVyZSI6Imh0dHBzOi8vbGgzLmdvb2dsZXVzZXJjb250ZW50LmNvbS9hL0FDZzhvY0xjTWNhMllKNXFXMjdGUldmWmJ0VnRiXzFwMWlBajUtX1RjUHY2V1F0SUZyX1kydz1zOTYtYyIsImRpc3BsYXlfbmFtZSI6IkEuSS4gTS5sLiIsInBsYW5faWQiOjEsImlhdCI6MTc4MTYzMjgxOCwiZXhwIjo0MzczNjMyODE4fQ.HUY6DMq3AbZzylffmUqQ4h2ih371DokcZOPQ5-n5-lc","accept-language":"en-US,en;q=0.9","accept-encoding":"gzip, deflate, br, zstd","referer":"http://localhost:3000/","sec-fetch-dest":"empty","sec-fetch-mode":"cors","sec-fetch-site":"same-origin","origin":"http://localhost:3000","sec-ch-ua-mobile":"?0","sec-ch-ua":"\\"Google Chrome\\";v=\\"149\\", \\"Chromium\\";v=\\"149\\", \\"Not)A;Brand\\";v=\\"24\\"","accept":"application/json","user-agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36","sec-ch-ua-platform":"\\"Windows\\"","content-length":"0","connection":"close","host":"localhost:5000"}	b0270228-e7c5-49e5-a787-26b754185749	2026-06-16 23:38:44.625344
b0315c8f-56b7-4d5a-8e88-b315c0585f76	2cfef765-be93-4f01-b96f-88f2b2b2ec39	$2b$10$H99X2XhSi6b7jNAcS/miKuLLGfFClVvxbxERBaXxlVJO5eBCCLqOq	2026-06-24 01:31:48.607731	2026-06-17 01:31:48.607731	::1	{"cookie":"acessToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMmNmZWY3NjUtYmU5My00ZjAxLWI5NmYtODhmMmIyYjJlYzM5IiwiZ29vZ2xlX2lkIjoiMTAyOTg2NzMzMTM1NTI2MDc1NjIyIiwiZW1haWwiOiJhLmkubS5sLnN0YXJrLjMwMDBAZ21haWwuY29tIiwicGljdHVyZSI6Imh0dHBzOi8vbGgzLmdvb2dsZXVzZXJjb250ZW50LmNvbS9hL0FDZzhvY0xjTWNhMllKNXFXMjdGUldmWmJ0VnRiXzFwMWlBajUtX1RjUHY2V1F0SUZyX1kydz1zOTYtYyIsImRpc3BsYXlfbmFtZSI6IkEuSS4gTS5sLiIsInBsYW5faWQiOjEsImlhdCI6MTc4MTYzMjgxOCwiZXhwIjo0MzczNjMyODE4fQ.HUY6DMq3AbZzylffmUqQ4h2ih371DokcZOPQ5-n5-lc; refreshToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjJjZmVmNzY1LWJlOTMtNGYwMS1iOTZmLTg4ZjJiMmIyZWMzOSIsImp3dF9pZCI6IjJhYzVmOGViLWQwODYtNDkxNi1iNDI1LWMwODc0YjY2NzVjZSIsImlhdCI6MTc4MTYzOTkzMCwiZXhwIjo0MzczNjM5OTMwfQ.XZZajG9yPBzZOplrIGYVhgDRe0tL6EZUzZddTSXASc0","accept-language":"en-US,en;q=0.9","accept-encoding":"gzip, deflate, br, zstd","referer":"http://localhost:3000/","sec-fetch-dest":"empty","sec-fetch-mode":"cors","sec-fetch-site":"same-origin","origin":"http://localhost:3000","sec-ch-ua-mobile":"?0","sec-ch-ua":"\\"Google Chrome\\";v=\\"149\\", \\"Chromium\\";v=\\"149\\", \\"Not)A;Brand\\";v=\\"24\\"","accept":"application/json","user-agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36","sec-ch-ua-platform":"\\"Windows\\"","content-length":"0","connection":"close","host":"localhost:5000"}	fea92cba-35cc-4744-97a9-1db39b62230a	2026-06-17 01:31:48.607731
f7394381-b937-441f-951b-6218f4b26d1c	2cfef765-be93-4f01-b96f-88f2b2b2ec39	$2b$10$Ij7PjKNHLbS7i3zJLVzTcusJE562sFTMLyyA/4cGUMW7HhhTKo/fG	2026-06-24 02:32:05.945494	2026-06-17 02:32:05.945494	::1	{"host":"localhost:5000","connection":"keep-alive","content-length":"0","sec-ch-ua-platform":"\\"Windows\\"","user-agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36","accept":"application/json","sec-ch-ua":"\\"Google Chrome\\";v=\\"149\\", \\"Chromium\\";v=\\"149\\", \\"Not)A;Brand\\";v=\\"24\\"","sec-ch-ua-mobile":"?0","origin":"http://localhost:3000","sec-fetch-site":"cross-site","sec-fetch-mode":"cors","sec-fetch-dest":"empty","sec-fetch-storage-access":"active","referer":"http://localhost:3000/","accept-encoding":"gzip, deflate, br, zstd","accept-language":"en-US,en;q=0.9","cookie":"acessToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMmNmZWY3NjUtYmU5My00ZjAxLWI5NmYtODhmMmIyYjJlYzM5IiwiZ29vZ2xlX2lkIjoiMTAyOTg2NzMzMTM1NTI2MDc1NjIyIiwiZW1haWwiOiJhLmkubS5sLnN0YXJrLjMwMDBAZ21haWwuY29tIiwicGljdHVyZSI6Imh0dHBzOi8vbGgzLmdvb2dsZXVzZXJjb250ZW50LmNvbS9hL0FDZzhvY0xjTWNhMllKNXFXMjdGUldmWmJ0VnRiXzFwMWlBajUtX1RjUHY2V1F0SUZyX1kydz1zOTYtYyIsImRpc3BsYXlfbmFtZSI6IkEuSS4gTS5sLiIsInBsYW5faWQiOjEsImlhdCI6MTc4MTYzMjgxOCwiZXhwIjo0MzczNjMyODE4fQ.HUY6DMq3AbZzylffmUqQ4h2ih371DokcZOPQ5-n5-lc; refreshToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjJjZmVmNzY1LWJlOTMtNGYwMS1iOTZmLTg4ZjJiMmIyZWMzOSIsImp3dF9pZCI6ImVjNzFlNTgwLWEyMGItNGNmZi05NmViLTI0NWU1OTMzMjljNyIsImlhdCI6MTc4MTY0MzQ1NCwiZXhwIjo0MzczNjQzNDU0fQ.gkhC_SR5vttvwIemc32U1S03WMMupRIA_9BnM7LHDLs"}	33295107-3633-4279-bd18-3b8a004cf87d	2026-06-17 02:32:05.945494
171c522f-da87-45b0-9d97-76079af01514	2cfef765-be93-4f01-b96f-88f2b2b2ec39	$2b$10$3TzJnAA7WVLvlOGHC9YjY.3MNWhYnicRlI6gsDXG7eXUSLfizG8wm	2026-06-24 02:41:17.237624	2026-06-17 02:41:17.237624	::1	{"host":"localhost:5000","connection":"keep-alive","content-length":"0","sec-ch-ua-platform":"\\"Windows\\"","user-agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36","accept":"application/json","sec-ch-ua":"\\"Google Chrome\\";v=\\"149\\", \\"Chromium\\";v=\\"149\\", \\"Not)A;Brand\\";v=\\"24\\"","sec-ch-ua-mobile":"?0","origin":"http://localhost:3000","sec-fetch-site":"cross-site","sec-fetch-mode":"cors","sec-fetch-dest":"empty","sec-fetch-storage-access":"active","referer":"http://localhost:3000/","accept-encoding":"gzip, deflate, br, zstd","accept-language":"en-US,en;q=0.9","cookie":"acessToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMmNmZWY3NjUtYmU5My00ZjAxLWI5NmYtODhmMmIyYjJlYzM5IiwiZ29vZ2xlX2lkIjoiMTAyOTg2NzMzMTM1NTI2MDc1NjIyIiwiZW1haWwiOiJhLmkubS5sLnN0YXJrLjMwMDBAZ21haWwuY29tIiwicGljdHVyZSI6Imh0dHBzOi8vbGgzLmdvb2dsZXVzZXJjb250ZW50LmNvbS9hL0FDZzhvY0xjTWNhMllKNXFXMjdGUldmWmJ0VnRiXzFwMWlBajUtX1RjUHY2V1F0SUZyX1kydz1zOTYtYyIsImRpc3BsYXlfbmFtZSI6IkEuSS4gTS5sLiIsInBsYW5faWQiOjEsImlhdCI6MTc4MTYzMjgxOCwiZXhwIjo0MzczNjMyODE4fQ.HUY6DMq3AbZzylffmUqQ4h2ih371DokcZOPQ5-n5-lc; refreshToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjJjZmVmNzY1LWJlOTMtNGYwMS1iOTZmLTg4ZjJiMmIyZWMzOSIsImp3dF9pZCI6IjgyOGRmMmExLWQzMjYtNGE4Yi04ZjI3LWViMzMyZmRjYTQ0ZSIsImlhdCI6MTc4MTY0NDAzOCwiZXhwIjo0MzczNjQ0MDM4fQ.eDUe5QfHsSNrfdUaAk1b8SXJULpLLk4wZrfEV8qxxK8"}	e80da2aa-f64c-49b2-803a-d98a71a69d1a	2026-06-17 02:41:17.237624
f9d11353-a77a-4bf1-8f6a-bb3158a009c8	fa61f3e0-14ea-4ce1-bfd8-9701f5960dcd	$2b$10$BNYYT6ldUTvSe1yw3ydy1.Fv1JbNbDdzufnd6pPl6itnKzzOasP0.	2026-06-26 18:16:04.222694	2026-06-19 18:16:04.222694	::1	{"host":"localhost:5000","connection":"keep-alive","content-length":"0","sec-ch-ua-platform":"\\"Windows\\"","user-agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36 Edg/149.0.0.0","accept":"application/json","sec-ch-ua":"\\"Microsoft Edge\\";v=\\"149\\", \\"Chromium\\";v=\\"149\\", \\"Not)A;Brand\\";v=\\"24\\"","sec-ch-ua-mobile":"?0","origin":"http://localhost:3000","sec-fetch-site":"cross-site","sec-fetch-mode":"cors","sec-fetch-dest":"empty","sec-fetch-storage-access":"active","referer":"http://localhost:3000/","accept-encoding":"gzip, deflate, br, zstd","accept-language":"en-US,en;q=0.9,en-IN;q=0.8","cookie":"refreshToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImZhNjFmM2UwLTE0ZWEtNGNlMS1iZmQ4LTk3MDFmNTk2MGRjZCIsImp3dF9pZCI6IjBlODE4NzY0LTliYjMtNDZlNS1hNWY2LWU0YzY1NDRhNDc5MSIsImlhdCI6MTc4MTY3ODcxMiwiZXhwIjo0MzczNjc4NzEyfQ.IefG2Hw2rvG_ygVJP2vnkzAeNEm7hKLaTPCC5Mc-nVE"}	81678b39-9a7a-4f5a-b18a-0eb2abe31a5e	2026-06-19 18:16:04.222694
\.


--
-- Data for Name: state_transcripts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.state_transcripts (state_name, news_transcript, finance_transcript, created_at, is_used, max_cnt) FROM stdin;
\.


--
-- Data for Name: states; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.states (id, name) FROM stdin;
177	Haryana
109	Kerala
43	Madhya Pradesh
161	Uttarakhand
79	Himachal Pradesh
42	Uttar Pradesh
19	Karnataka
112	Dadra and Nagar Haveli and Daman and Diu
113	Andaman and Nicobar Islands
114	Tripura
48	Telangana
38	West Bengal
14	Maharashtra
45	Punjab
40	Jammu and Kashmir
39	Rajasthan
110	Gujarat
119	Tamil Nadu
77	Assam
81	Bihar
15	Delhi
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, google_id, email, name, picture_url, plan_id, created_at, updated_at, user_role) FROM stdin;
2cfef765-be93-4f01-b96f-88f2b2b2ec39	102986733135526075622	a.i.m.l.stark.3000@gmail.com	A.I. M.l.	https://lh3.googleusercontent.com/a/ACg8ocLcMca2YJ5qW27FRWfZbtVtb_1p1iAj5-_TcPv6WQtIFr_Y2w=s96-c	1	2026-06-12 00:14:52.17864	2026-06-12 00:14:52.17864	user
fa61f3e0-14ea-4ce1-bfd8-9701f5960dcd	102979078190918470500	rslikefoot00@gmail.com	Rudresh Singh	https://lh3.googleusercontent.com/a/ACg8ocIk3WbC4PLmvP61ABvevCaRkinG7A5urPs5Ccqhb7ACzkn-93I9=s96-c	1	2026-06-13 21:30:17.911489	2026-06-13 21:30:17.911489	user
\.


--
-- Name: api_keys_new_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.api_keys_new_id_seq', 68, true);


--
-- Name: channel_transcripts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.channel_transcripts_id_seq', 40, true);


--
-- Name: districts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.districts_id_seq', 149, true);


--
-- Name: news_all_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.news_all_id_seq', 268, true);


--
-- Name: plans_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.plans_id_seq', 1, false);


--
-- Name: states_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.states_id_seq', 181, true);


--
-- Name: api_keys api_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_pkey PRIMARY KEY (id);


--
-- Name: channel_transcripts channel_transcripts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.channel_transcripts
    ADD CONSTRAINT channel_transcripts_pkey PRIMARY KEY (id);


--
-- Name: districts districts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.districts
    ADD CONSTRAINT districts_pkey PRIMARY KEY (id);


--
-- Name: districts districts_state_id_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.districts
    ADD CONSTRAINT districts_state_id_name_key UNIQUE (state_id, name);


--
-- Name: news_all news_all_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all
    ADD CONSTRAINT news_all_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2026_04 news_all_2026_04_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2026_04
    ADD CONSTRAINT news_all_2026_04_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2026_05 news_all_2026_05_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2026_05
    ADD CONSTRAINT news_all_2026_05_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2026_06 news_all_2026_06_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2026_06
    ADD CONSTRAINT news_all_2026_06_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2026_07 news_all_2026_07_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2026_07
    ADD CONSTRAINT news_all_2026_07_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2026_08 news_all_2026_08_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2026_08
    ADD CONSTRAINT news_all_2026_08_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2026_09 news_all_2026_09_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2026_09
    ADD CONSTRAINT news_all_2026_09_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2026_10 news_all_2026_10_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2026_10
    ADD CONSTRAINT news_all_2026_10_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2026_11 news_all_2026_11_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2026_11
    ADD CONSTRAINT news_all_2026_11_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2026_12 news_all_2026_12_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2026_12
    ADD CONSTRAINT news_all_2026_12_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2027_01 news_all_2027_01_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2027_01
    ADD CONSTRAINT news_all_2027_01_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2027_02 news_all_2027_02_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2027_02
    ADD CONSTRAINT news_all_2027_02_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2027_03 news_all_2027_03_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2027_03
    ADD CONSTRAINT news_all_2027_03_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2027_04 news_all_2027_04_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2027_04
    ADD CONSTRAINT news_all_2027_04_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2027_05 news_all_2027_05_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2027_05
    ADD CONSTRAINT news_all_2027_05_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2027_06 news_all_2027_06_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2027_06
    ADD CONSTRAINT news_all_2027_06_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2027_07 news_all_2027_07_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2027_07
    ADD CONSTRAINT news_all_2027_07_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2027_08 news_all_2027_08_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2027_08
    ADD CONSTRAINT news_all_2027_08_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2027_09 news_all_2027_09_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2027_09
    ADD CONSTRAINT news_all_2027_09_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2027_10 news_all_2027_10_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2027_10
    ADD CONSTRAINT news_all_2027_10_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2027_11 news_all_2027_11_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2027_11
    ADD CONSTRAINT news_all_2027_11_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2027_12 news_all_2027_12_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2027_12
    ADD CONSTRAINT news_all_2027_12_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2028_01 news_all_2028_01_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2028_01
    ADD CONSTRAINT news_all_2028_01_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2028_02 news_all_2028_02_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2028_02
    ADD CONSTRAINT news_all_2028_02_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2028_03 news_all_2028_03_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2028_03
    ADD CONSTRAINT news_all_2028_03_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2028_04 news_all_2028_04_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2028_04
    ADD CONSTRAINT news_all_2028_04_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2028_05 news_all_2028_05_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2028_05
    ADD CONSTRAINT news_all_2028_05_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2028_06 news_all_2028_06_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2028_06
    ADD CONSTRAINT news_all_2028_06_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2028_07 news_all_2028_07_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2028_07
    ADD CONSTRAINT news_all_2028_07_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2028_08 news_all_2028_08_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2028_08
    ADD CONSTRAINT news_all_2028_08_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2028_09 news_all_2028_09_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2028_09
    ADD CONSTRAINT news_all_2028_09_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2028_10 news_all_2028_10_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2028_10
    ADD CONSTRAINT news_all_2028_10_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2028_11 news_all_2028_11_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2028_11
    ADD CONSTRAINT news_all_2028_11_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2028_12 news_all_2028_12_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2028_12
    ADD CONSTRAINT news_all_2028_12_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2029_01 news_all_2029_01_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2029_01
    ADD CONSTRAINT news_all_2029_01_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2029_02 news_all_2029_02_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2029_02
    ADD CONSTRAINT news_all_2029_02_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2029_03 news_all_2029_03_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2029_03
    ADD CONSTRAINT news_all_2029_03_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2029_04 news_all_2029_04_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2029_04
    ADD CONSTRAINT news_all_2029_04_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2029_05 news_all_2029_05_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2029_05
    ADD CONSTRAINT news_all_2029_05_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2029_06 news_all_2029_06_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2029_06
    ADD CONSTRAINT news_all_2029_06_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2029_07 news_all_2029_07_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2029_07
    ADD CONSTRAINT news_all_2029_07_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2029_08 news_all_2029_08_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2029_08
    ADD CONSTRAINT news_all_2029_08_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2029_09 news_all_2029_09_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2029_09
    ADD CONSTRAINT news_all_2029_09_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2029_10 news_all_2029_10_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2029_10
    ADD CONSTRAINT news_all_2029_10_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2029_11 news_all_2029_11_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2029_11
    ADD CONSTRAINT news_all_2029_11_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2029_12 news_all_2029_12_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2029_12
    ADD CONSTRAINT news_all_2029_12_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2030_01 news_all_2030_01_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2030_01
    ADD CONSTRAINT news_all_2030_01_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2030_02 news_all_2030_02_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2030_02
    ADD CONSTRAINT news_all_2030_02_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2030_03 news_all_2030_03_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2030_03
    ADD CONSTRAINT news_all_2030_03_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2030_04 news_all_2030_04_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2030_04
    ADD CONSTRAINT news_all_2030_04_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2030_05 news_all_2030_05_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2030_05
    ADD CONSTRAINT news_all_2030_05_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2030_06 news_all_2030_06_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2030_06
    ADD CONSTRAINT news_all_2030_06_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2030_07 news_all_2030_07_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2030_07
    ADD CONSTRAINT news_all_2030_07_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2030_08 news_all_2030_08_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2030_08
    ADD CONSTRAINT news_all_2030_08_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2030_09 news_all_2030_09_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2030_09
    ADD CONSTRAINT news_all_2030_09_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2030_10 news_all_2030_10_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2030_10
    ADD CONSTRAINT news_all_2030_10_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2030_11 news_all_2030_11_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2030_11
    ADD CONSTRAINT news_all_2030_11_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2030_12 news_all_2030_12_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_all_2030_12
    ADD CONSTRAINT news_all_2030_12_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: plans plans_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.plans
    ADD CONSTRAINT plans_name_key UNIQUE (name);


--
-- Name: plans plans_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.plans
    ADD CONSTRAINT plans_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_jwt_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_jwt_id_key UNIQUE (jwt_id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: state_transcripts state_transcripts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.state_transcripts
    ADD CONSTRAINT state_transcripts_pkey PRIMARY KEY (state_name);


--
-- Name: states states_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.states
    ADD CONSTRAINT states_name_key UNIQUE (name);


--
-- Name: states states_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.states
    ADD CONSTRAINT states_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_google_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_google_id_key UNIQUE (google_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_channel_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_channel_id ON public.channel_transcripts USING btree (channel_id);


--
-- Name: idx_news_broadcast_date_brin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_broadcast_date_brin ON ONLY public.news_all USING brin (broadcast_date);


--
-- Name: idx_news_category_sentiment; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_category_sentiment ON ONLY public.news_all USING btree (category, sentiment);


--
-- Name: idx_news_entities_gin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_entities_gin ON ONLY public.news_all USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: idx_news_financial_industries; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_financial_industries ON ONLY public.news_all USING gin (financial_industries jsonb_path_ops);


--
-- Name: idx_news_headline_search; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_headline_search ON ONLY public.news_all USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: idx_news_state_district_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_state_district_date ON ONLY public.news_all USING btree (state_id, district_id, broadcast_date);


--
-- Name: idx_news_tags_gin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_tags_gin ON ONLY public.news_all USING gin (tags);


--
-- Name: idx_prefix; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_prefix ON public.api_keys USING btree (key_prefix);


--
-- Name: idx_refresh_jwt_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_refresh_jwt_id ON public.refresh_tokens USING btree (jwt_id);


--
-- Name: idx_refresh_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_refresh_user ON public.refresh_tokens USING btree (user_id);


--
-- Name: idx_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user ON public.api_keys USING btree (user_id);


--
-- Name: idx_users_google_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_users_google_id ON public.users USING btree (google_id);


--
-- Name: news_all_2026_04_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_04_broadcast_date_idx ON public.news_all_2026_04 USING brin (broadcast_date);


--
-- Name: news_all_2026_04_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_04_category_sentiment_idx ON public.news_all_2026_04 USING btree (category, sentiment);


--
-- Name: news_all_2026_04_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_04_entities_idx ON public.news_all_2026_04 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2026_04_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_04_financial_industries_idx ON public.news_all_2026_04 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2026_04_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_04_state_id_district_id_broadcast_date_idx ON public.news_all_2026_04 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2026_04_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_04_tags_idx ON public.news_all_2026_04 USING gin (tags);


--
-- Name: news_all_2026_04_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_04_to_tsvector_idx ON public.news_all_2026_04 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2026_05_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_05_broadcast_date_idx ON public.news_all_2026_05 USING brin (broadcast_date);


--
-- Name: news_all_2026_05_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_05_category_sentiment_idx ON public.news_all_2026_05 USING btree (category, sentiment);


--
-- Name: news_all_2026_05_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_05_entities_idx ON public.news_all_2026_05 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2026_05_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_05_financial_industries_idx ON public.news_all_2026_05 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2026_05_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_05_state_id_district_id_broadcast_date_idx ON public.news_all_2026_05 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2026_05_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_05_tags_idx ON public.news_all_2026_05 USING gin (tags);


--
-- Name: news_all_2026_05_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_05_to_tsvector_idx ON public.news_all_2026_05 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2026_06_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_06_broadcast_date_idx ON public.news_all_2026_06 USING brin (broadcast_date);


--
-- Name: news_all_2026_06_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_06_category_sentiment_idx ON public.news_all_2026_06 USING btree (category, sentiment);


--
-- Name: news_all_2026_06_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_06_entities_idx ON public.news_all_2026_06 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2026_06_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_06_financial_industries_idx ON public.news_all_2026_06 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2026_06_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_06_state_id_district_id_broadcast_date_idx ON public.news_all_2026_06 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2026_06_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_06_tags_idx ON public.news_all_2026_06 USING gin (tags);


--
-- Name: news_all_2026_06_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_06_to_tsvector_idx ON public.news_all_2026_06 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2026_07_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_07_broadcast_date_idx ON public.news_all_2026_07 USING brin (broadcast_date);


--
-- Name: news_all_2026_07_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_07_category_sentiment_idx ON public.news_all_2026_07 USING btree (category, sentiment);


--
-- Name: news_all_2026_07_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_07_entities_idx ON public.news_all_2026_07 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2026_07_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_07_financial_industries_idx ON public.news_all_2026_07 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2026_07_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_07_state_id_district_id_broadcast_date_idx ON public.news_all_2026_07 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2026_07_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_07_tags_idx ON public.news_all_2026_07 USING gin (tags);


--
-- Name: news_all_2026_07_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_07_to_tsvector_idx ON public.news_all_2026_07 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2026_08_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_08_broadcast_date_idx ON public.news_all_2026_08 USING brin (broadcast_date);


--
-- Name: news_all_2026_08_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_08_category_sentiment_idx ON public.news_all_2026_08 USING btree (category, sentiment);


--
-- Name: news_all_2026_08_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_08_entities_idx ON public.news_all_2026_08 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2026_08_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_08_financial_industries_idx ON public.news_all_2026_08 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2026_08_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_08_state_id_district_id_broadcast_date_idx ON public.news_all_2026_08 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2026_08_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_08_tags_idx ON public.news_all_2026_08 USING gin (tags);


--
-- Name: news_all_2026_08_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_08_to_tsvector_idx ON public.news_all_2026_08 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2026_09_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_09_broadcast_date_idx ON public.news_all_2026_09 USING brin (broadcast_date);


--
-- Name: news_all_2026_09_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_09_category_sentiment_idx ON public.news_all_2026_09 USING btree (category, sentiment);


--
-- Name: news_all_2026_09_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_09_entities_idx ON public.news_all_2026_09 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2026_09_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_09_financial_industries_idx ON public.news_all_2026_09 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2026_09_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_09_state_id_district_id_broadcast_date_idx ON public.news_all_2026_09 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2026_09_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_09_tags_idx ON public.news_all_2026_09 USING gin (tags);


--
-- Name: news_all_2026_09_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_09_to_tsvector_idx ON public.news_all_2026_09 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2026_10_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_10_broadcast_date_idx ON public.news_all_2026_10 USING brin (broadcast_date);


--
-- Name: news_all_2026_10_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_10_category_sentiment_idx ON public.news_all_2026_10 USING btree (category, sentiment);


--
-- Name: news_all_2026_10_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_10_entities_idx ON public.news_all_2026_10 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2026_10_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_10_financial_industries_idx ON public.news_all_2026_10 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2026_10_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_10_state_id_district_id_broadcast_date_idx ON public.news_all_2026_10 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2026_10_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_10_tags_idx ON public.news_all_2026_10 USING gin (tags);


--
-- Name: news_all_2026_10_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_10_to_tsvector_idx ON public.news_all_2026_10 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2026_11_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_11_broadcast_date_idx ON public.news_all_2026_11 USING brin (broadcast_date);


--
-- Name: news_all_2026_11_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_11_category_sentiment_idx ON public.news_all_2026_11 USING btree (category, sentiment);


--
-- Name: news_all_2026_11_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_11_entities_idx ON public.news_all_2026_11 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2026_11_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_11_financial_industries_idx ON public.news_all_2026_11 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2026_11_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_11_state_id_district_id_broadcast_date_idx ON public.news_all_2026_11 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2026_11_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_11_tags_idx ON public.news_all_2026_11 USING gin (tags);


--
-- Name: news_all_2026_11_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_11_to_tsvector_idx ON public.news_all_2026_11 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2026_12_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_12_broadcast_date_idx ON public.news_all_2026_12 USING brin (broadcast_date);


--
-- Name: news_all_2026_12_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_12_category_sentiment_idx ON public.news_all_2026_12 USING btree (category, sentiment);


--
-- Name: news_all_2026_12_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_12_entities_idx ON public.news_all_2026_12 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2026_12_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_12_financial_industries_idx ON public.news_all_2026_12 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2026_12_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_12_state_id_district_id_broadcast_date_idx ON public.news_all_2026_12 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2026_12_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_12_tags_idx ON public.news_all_2026_12 USING gin (tags);


--
-- Name: news_all_2026_12_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2026_12_to_tsvector_idx ON public.news_all_2026_12 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2027_01_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_01_broadcast_date_idx ON public.news_all_2027_01 USING brin (broadcast_date);


--
-- Name: news_all_2027_01_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_01_category_sentiment_idx ON public.news_all_2027_01 USING btree (category, sentiment);


--
-- Name: news_all_2027_01_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_01_entities_idx ON public.news_all_2027_01 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2027_01_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_01_financial_industries_idx ON public.news_all_2027_01 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2027_01_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_01_state_id_district_id_broadcast_date_idx ON public.news_all_2027_01 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2027_01_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_01_tags_idx ON public.news_all_2027_01 USING gin (tags);


--
-- Name: news_all_2027_01_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_01_to_tsvector_idx ON public.news_all_2027_01 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2027_02_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_02_broadcast_date_idx ON public.news_all_2027_02 USING brin (broadcast_date);


--
-- Name: news_all_2027_02_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_02_category_sentiment_idx ON public.news_all_2027_02 USING btree (category, sentiment);


--
-- Name: news_all_2027_02_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_02_entities_idx ON public.news_all_2027_02 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2027_02_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_02_financial_industries_idx ON public.news_all_2027_02 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2027_02_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_02_state_id_district_id_broadcast_date_idx ON public.news_all_2027_02 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2027_02_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_02_tags_idx ON public.news_all_2027_02 USING gin (tags);


--
-- Name: news_all_2027_02_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_02_to_tsvector_idx ON public.news_all_2027_02 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2027_03_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_03_broadcast_date_idx ON public.news_all_2027_03 USING brin (broadcast_date);


--
-- Name: news_all_2027_03_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_03_category_sentiment_idx ON public.news_all_2027_03 USING btree (category, sentiment);


--
-- Name: news_all_2027_03_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_03_entities_idx ON public.news_all_2027_03 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2027_03_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_03_financial_industries_idx ON public.news_all_2027_03 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2027_03_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_03_state_id_district_id_broadcast_date_idx ON public.news_all_2027_03 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2027_03_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_03_tags_idx ON public.news_all_2027_03 USING gin (tags);


--
-- Name: news_all_2027_03_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_03_to_tsvector_idx ON public.news_all_2027_03 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2027_04_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_04_broadcast_date_idx ON public.news_all_2027_04 USING brin (broadcast_date);


--
-- Name: news_all_2027_04_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_04_category_sentiment_idx ON public.news_all_2027_04 USING btree (category, sentiment);


--
-- Name: news_all_2027_04_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_04_entities_idx ON public.news_all_2027_04 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2027_04_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_04_financial_industries_idx ON public.news_all_2027_04 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2027_04_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_04_state_id_district_id_broadcast_date_idx ON public.news_all_2027_04 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2027_04_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_04_tags_idx ON public.news_all_2027_04 USING gin (tags);


--
-- Name: news_all_2027_04_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_04_to_tsvector_idx ON public.news_all_2027_04 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2027_05_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_05_broadcast_date_idx ON public.news_all_2027_05 USING brin (broadcast_date);


--
-- Name: news_all_2027_05_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_05_category_sentiment_idx ON public.news_all_2027_05 USING btree (category, sentiment);


--
-- Name: news_all_2027_05_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_05_entities_idx ON public.news_all_2027_05 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2027_05_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_05_financial_industries_idx ON public.news_all_2027_05 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2027_05_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_05_state_id_district_id_broadcast_date_idx ON public.news_all_2027_05 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2027_05_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_05_tags_idx ON public.news_all_2027_05 USING gin (tags);


--
-- Name: news_all_2027_05_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_05_to_tsvector_idx ON public.news_all_2027_05 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2027_06_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_06_broadcast_date_idx ON public.news_all_2027_06 USING brin (broadcast_date);


--
-- Name: news_all_2027_06_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_06_category_sentiment_idx ON public.news_all_2027_06 USING btree (category, sentiment);


--
-- Name: news_all_2027_06_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_06_entities_idx ON public.news_all_2027_06 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2027_06_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_06_financial_industries_idx ON public.news_all_2027_06 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2027_06_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_06_state_id_district_id_broadcast_date_idx ON public.news_all_2027_06 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2027_06_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_06_tags_idx ON public.news_all_2027_06 USING gin (tags);


--
-- Name: news_all_2027_06_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_06_to_tsvector_idx ON public.news_all_2027_06 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2027_07_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_07_broadcast_date_idx ON public.news_all_2027_07 USING brin (broadcast_date);


--
-- Name: news_all_2027_07_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_07_category_sentiment_idx ON public.news_all_2027_07 USING btree (category, sentiment);


--
-- Name: news_all_2027_07_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_07_entities_idx ON public.news_all_2027_07 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2027_07_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_07_financial_industries_idx ON public.news_all_2027_07 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2027_07_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_07_state_id_district_id_broadcast_date_idx ON public.news_all_2027_07 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2027_07_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_07_tags_idx ON public.news_all_2027_07 USING gin (tags);


--
-- Name: news_all_2027_07_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_07_to_tsvector_idx ON public.news_all_2027_07 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2027_08_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_08_broadcast_date_idx ON public.news_all_2027_08 USING brin (broadcast_date);


--
-- Name: news_all_2027_08_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_08_category_sentiment_idx ON public.news_all_2027_08 USING btree (category, sentiment);


--
-- Name: news_all_2027_08_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_08_entities_idx ON public.news_all_2027_08 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2027_08_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_08_financial_industries_idx ON public.news_all_2027_08 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2027_08_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_08_state_id_district_id_broadcast_date_idx ON public.news_all_2027_08 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2027_08_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_08_tags_idx ON public.news_all_2027_08 USING gin (tags);


--
-- Name: news_all_2027_08_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_08_to_tsvector_idx ON public.news_all_2027_08 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2027_09_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_09_broadcast_date_idx ON public.news_all_2027_09 USING brin (broadcast_date);


--
-- Name: news_all_2027_09_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_09_category_sentiment_idx ON public.news_all_2027_09 USING btree (category, sentiment);


--
-- Name: news_all_2027_09_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_09_entities_idx ON public.news_all_2027_09 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2027_09_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_09_financial_industries_idx ON public.news_all_2027_09 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2027_09_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_09_state_id_district_id_broadcast_date_idx ON public.news_all_2027_09 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2027_09_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_09_tags_idx ON public.news_all_2027_09 USING gin (tags);


--
-- Name: news_all_2027_09_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_09_to_tsvector_idx ON public.news_all_2027_09 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2027_10_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_10_broadcast_date_idx ON public.news_all_2027_10 USING brin (broadcast_date);


--
-- Name: news_all_2027_10_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_10_category_sentiment_idx ON public.news_all_2027_10 USING btree (category, sentiment);


--
-- Name: news_all_2027_10_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_10_entities_idx ON public.news_all_2027_10 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2027_10_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_10_financial_industries_idx ON public.news_all_2027_10 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2027_10_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_10_state_id_district_id_broadcast_date_idx ON public.news_all_2027_10 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2027_10_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_10_tags_idx ON public.news_all_2027_10 USING gin (tags);


--
-- Name: news_all_2027_10_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_10_to_tsvector_idx ON public.news_all_2027_10 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2027_11_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_11_broadcast_date_idx ON public.news_all_2027_11 USING brin (broadcast_date);


--
-- Name: news_all_2027_11_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_11_category_sentiment_idx ON public.news_all_2027_11 USING btree (category, sentiment);


--
-- Name: news_all_2027_11_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_11_entities_idx ON public.news_all_2027_11 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2027_11_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_11_financial_industries_idx ON public.news_all_2027_11 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2027_11_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_11_state_id_district_id_broadcast_date_idx ON public.news_all_2027_11 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2027_11_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_11_tags_idx ON public.news_all_2027_11 USING gin (tags);


--
-- Name: news_all_2027_11_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_11_to_tsvector_idx ON public.news_all_2027_11 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2027_12_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_12_broadcast_date_idx ON public.news_all_2027_12 USING brin (broadcast_date);


--
-- Name: news_all_2027_12_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_12_category_sentiment_idx ON public.news_all_2027_12 USING btree (category, sentiment);


--
-- Name: news_all_2027_12_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_12_entities_idx ON public.news_all_2027_12 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2027_12_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_12_financial_industries_idx ON public.news_all_2027_12 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2027_12_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_12_state_id_district_id_broadcast_date_idx ON public.news_all_2027_12 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2027_12_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_12_tags_idx ON public.news_all_2027_12 USING gin (tags);


--
-- Name: news_all_2027_12_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2027_12_to_tsvector_idx ON public.news_all_2027_12 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2028_01_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_01_broadcast_date_idx ON public.news_all_2028_01 USING brin (broadcast_date);


--
-- Name: news_all_2028_01_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_01_category_sentiment_idx ON public.news_all_2028_01 USING btree (category, sentiment);


--
-- Name: news_all_2028_01_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_01_entities_idx ON public.news_all_2028_01 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2028_01_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_01_financial_industries_idx ON public.news_all_2028_01 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2028_01_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_01_state_id_district_id_broadcast_date_idx ON public.news_all_2028_01 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2028_01_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_01_tags_idx ON public.news_all_2028_01 USING gin (tags);


--
-- Name: news_all_2028_01_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_01_to_tsvector_idx ON public.news_all_2028_01 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2028_02_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_02_broadcast_date_idx ON public.news_all_2028_02 USING brin (broadcast_date);


--
-- Name: news_all_2028_02_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_02_category_sentiment_idx ON public.news_all_2028_02 USING btree (category, sentiment);


--
-- Name: news_all_2028_02_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_02_entities_idx ON public.news_all_2028_02 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2028_02_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_02_financial_industries_idx ON public.news_all_2028_02 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2028_02_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_02_state_id_district_id_broadcast_date_idx ON public.news_all_2028_02 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2028_02_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_02_tags_idx ON public.news_all_2028_02 USING gin (tags);


--
-- Name: news_all_2028_02_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_02_to_tsvector_idx ON public.news_all_2028_02 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2028_03_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_03_broadcast_date_idx ON public.news_all_2028_03 USING brin (broadcast_date);


--
-- Name: news_all_2028_03_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_03_category_sentiment_idx ON public.news_all_2028_03 USING btree (category, sentiment);


--
-- Name: news_all_2028_03_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_03_entities_idx ON public.news_all_2028_03 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2028_03_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_03_financial_industries_idx ON public.news_all_2028_03 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2028_03_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_03_state_id_district_id_broadcast_date_idx ON public.news_all_2028_03 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2028_03_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_03_tags_idx ON public.news_all_2028_03 USING gin (tags);


--
-- Name: news_all_2028_03_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_03_to_tsvector_idx ON public.news_all_2028_03 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2028_04_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_04_broadcast_date_idx ON public.news_all_2028_04 USING brin (broadcast_date);


--
-- Name: news_all_2028_04_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_04_category_sentiment_idx ON public.news_all_2028_04 USING btree (category, sentiment);


--
-- Name: news_all_2028_04_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_04_entities_idx ON public.news_all_2028_04 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2028_04_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_04_financial_industries_idx ON public.news_all_2028_04 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2028_04_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_04_state_id_district_id_broadcast_date_idx ON public.news_all_2028_04 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2028_04_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_04_tags_idx ON public.news_all_2028_04 USING gin (tags);


--
-- Name: news_all_2028_04_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_04_to_tsvector_idx ON public.news_all_2028_04 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2028_05_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_05_broadcast_date_idx ON public.news_all_2028_05 USING brin (broadcast_date);


--
-- Name: news_all_2028_05_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_05_category_sentiment_idx ON public.news_all_2028_05 USING btree (category, sentiment);


--
-- Name: news_all_2028_05_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_05_entities_idx ON public.news_all_2028_05 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2028_05_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_05_financial_industries_idx ON public.news_all_2028_05 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2028_05_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_05_state_id_district_id_broadcast_date_idx ON public.news_all_2028_05 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2028_05_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_05_tags_idx ON public.news_all_2028_05 USING gin (tags);


--
-- Name: news_all_2028_05_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_05_to_tsvector_idx ON public.news_all_2028_05 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2028_06_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_06_broadcast_date_idx ON public.news_all_2028_06 USING brin (broadcast_date);


--
-- Name: news_all_2028_06_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_06_category_sentiment_idx ON public.news_all_2028_06 USING btree (category, sentiment);


--
-- Name: news_all_2028_06_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_06_entities_idx ON public.news_all_2028_06 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2028_06_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_06_financial_industries_idx ON public.news_all_2028_06 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2028_06_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_06_state_id_district_id_broadcast_date_idx ON public.news_all_2028_06 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2028_06_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_06_tags_idx ON public.news_all_2028_06 USING gin (tags);


--
-- Name: news_all_2028_06_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_06_to_tsvector_idx ON public.news_all_2028_06 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2028_07_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_07_broadcast_date_idx ON public.news_all_2028_07 USING brin (broadcast_date);


--
-- Name: news_all_2028_07_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_07_category_sentiment_idx ON public.news_all_2028_07 USING btree (category, sentiment);


--
-- Name: news_all_2028_07_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_07_entities_idx ON public.news_all_2028_07 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2028_07_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_07_financial_industries_idx ON public.news_all_2028_07 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2028_07_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_07_state_id_district_id_broadcast_date_idx ON public.news_all_2028_07 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2028_07_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_07_tags_idx ON public.news_all_2028_07 USING gin (tags);


--
-- Name: news_all_2028_07_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_07_to_tsvector_idx ON public.news_all_2028_07 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2028_08_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_08_broadcast_date_idx ON public.news_all_2028_08 USING brin (broadcast_date);


--
-- Name: news_all_2028_08_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_08_category_sentiment_idx ON public.news_all_2028_08 USING btree (category, sentiment);


--
-- Name: news_all_2028_08_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_08_entities_idx ON public.news_all_2028_08 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2028_08_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_08_financial_industries_idx ON public.news_all_2028_08 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2028_08_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_08_state_id_district_id_broadcast_date_idx ON public.news_all_2028_08 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2028_08_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_08_tags_idx ON public.news_all_2028_08 USING gin (tags);


--
-- Name: news_all_2028_08_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_08_to_tsvector_idx ON public.news_all_2028_08 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2028_09_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_09_broadcast_date_idx ON public.news_all_2028_09 USING brin (broadcast_date);


--
-- Name: news_all_2028_09_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_09_category_sentiment_idx ON public.news_all_2028_09 USING btree (category, sentiment);


--
-- Name: news_all_2028_09_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_09_entities_idx ON public.news_all_2028_09 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2028_09_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_09_financial_industries_idx ON public.news_all_2028_09 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2028_09_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_09_state_id_district_id_broadcast_date_idx ON public.news_all_2028_09 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2028_09_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_09_tags_idx ON public.news_all_2028_09 USING gin (tags);


--
-- Name: news_all_2028_09_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_09_to_tsvector_idx ON public.news_all_2028_09 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2028_10_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_10_broadcast_date_idx ON public.news_all_2028_10 USING brin (broadcast_date);


--
-- Name: news_all_2028_10_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_10_category_sentiment_idx ON public.news_all_2028_10 USING btree (category, sentiment);


--
-- Name: news_all_2028_10_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_10_entities_idx ON public.news_all_2028_10 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2028_10_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_10_financial_industries_idx ON public.news_all_2028_10 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2028_10_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_10_state_id_district_id_broadcast_date_idx ON public.news_all_2028_10 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2028_10_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_10_tags_idx ON public.news_all_2028_10 USING gin (tags);


--
-- Name: news_all_2028_10_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_10_to_tsvector_idx ON public.news_all_2028_10 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2028_11_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_11_broadcast_date_idx ON public.news_all_2028_11 USING brin (broadcast_date);


--
-- Name: news_all_2028_11_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_11_category_sentiment_idx ON public.news_all_2028_11 USING btree (category, sentiment);


--
-- Name: news_all_2028_11_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_11_entities_idx ON public.news_all_2028_11 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2028_11_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_11_financial_industries_idx ON public.news_all_2028_11 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2028_11_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_11_state_id_district_id_broadcast_date_idx ON public.news_all_2028_11 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2028_11_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_11_tags_idx ON public.news_all_2028_11 USING gin (tags);


--
-- Name: news_all_2028_11_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_11_to_tsvector_idx ON public.news_all_2028_11 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2028_12_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_12_broadcast_date_idx ON public.news_all_2028_12 USING brin (broadcast_date);


--
-- Name: news_all_2028_12_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_12_category_sentiment_idx ON public.news_all_2028_12 USING btree (category, sentiment);


--
-- Name: news_all_2028_12_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_12_entities_idx ON public.news_all_2028_12 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2028_12_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_12_financial_industries_idx ON public.news_all_2028_12 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2028_12_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_12_state_id_district_id_broadcast_date_idx ON public.news_all_2028_12 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2028_12_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_12_tags_idx ON public.news_all_2028_12 USING gin (tags);


--
-- Name: news_all_2028_12_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2028_12_to_tsvector_idx ON public.news_all_2028_12 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2029_01_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_01_broadcast_date_idx ON public.news_all_2029_01 USING brin (broadcast_date);


--
-- Name: news_all_2029_01_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_01_category_sentiment_idx ON public.news_all_2029_01 USING btree (category, sentiment);


--
-- Name: news_all_2029_01_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_01_entities_idx ON public.news_all_2029_01 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2029_01_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_01_financial_industries_idx ON public.news_all_2029_01 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2029_01_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_01_state_id_district_id_broadcast_date_idx ON public.news_all_2029_01 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2029_01_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_01_tags_idx ON public.news_all_2029_01 USING gin (tags);


--
-- Name: news_all_2029_01_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_01_to_tsvector_idx ON public.news_all_2029_01 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2029_02_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_02_broadcast_date_idx ON public.news_all_2029_02 USING brin (broadcast_date);


--
-- Name: news_all_2029_02_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_02_category_sentiment_idx ON public.news_all_2029_02 USING btree (category, sentiment);


--
-- Name: news_all_2029_02_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_02_entities_idx ON public.news_all_2029_02 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2029_02_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_02_financial_industries_idx ON public.news_all_2029_02 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2029_02_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_02_state_id_district_id_broadcast_date_idx ON public.news_all_2029_02 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2029_02_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_02_tags_idx ON public.news_all_2029_02 USING gin (tags);


--
-- Name: news_all_2029_02_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_02_to_tsvector_idx ON public.news_all_2029_02 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2029_03_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_03_broadcast_date_idx ON public.news_all_2029_03 USING brin (broadcast_date);


--
-- Name: news_all_2029_03_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_03_category_sentiment_idx ON public.news_all_2029_03 USING btree (category, sentiment);


--
-- Name: news_all_2029_03_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_03_entities_idx ON public.news_all_2029_03 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2029_03_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_03_financial_industries_idx ON public.news_all_2029_03 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2029_03_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_03_state_id_district_id_broadcast_date_idx ON public.news_all_2029_03 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2029_03_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_03_tags_idx ON public.news_all_2029_03 USING gin (tags);


--
-- Name: news_all_2029_03_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_03_to_tsvector_idx ON public.news_all_2029_03 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2029_04_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_04_broadcast_date_idx ON public.news_all_2029_04 USING brin (broadcast_date);


--
-- Name: news_all_2029_04_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_04_category_sentiment_idx ON public.news_all_2029_04 USING btree (category, sentiment);


--
-- Name: news_all_2029_04_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_04_entities_idx ON public.news_all_2029_04 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2029_04_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_04_financial_industries_idx ON public.news_all_2029_04 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2029_04_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_04_state_id_district_id_broadcast_date_idx ON public.news_all_2029_04 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2029_04_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_04_tags_idx ON public.news_all_2029_04 USING gin (tags);


--
-- Name: news_all_2029_04_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_04_to_tsvector_idx ON public.news_all_2029_04 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2029_05_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_05_broadcast_date_idx ON public.news_all_2029_05 USING brin (broadcast_date);


--
-- Name: news_all_2029_05_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_05_category_sentiment_idx ON public.news_all_2029_05 USING btree (category, sentiment);


--
-- Name: news_all_2029_05_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_05_entities_idx ON public.news_all_2029_05 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2029_05_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_05_financial_industries_idx ON public.news_all_2029_05 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2029_05_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_05_state_id_district_id_broadcast_date_idx ON public.news_all_2029_05 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2029_05_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_05_tags_idx ON public.news_all_2029_05 USING gin (tags);


--
-- Name: news_all_2029_05_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_05_to_tsvector_idx ON public.news_all_2029_05 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2029_06_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_06_broadcast_date_idx ON public.news_all_2029_06 USING brin (broadcast_date);


--
-- Name: news_all_2029_06_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_06_category_sentiment_idx ON public.news_all_2029_06 USING btree (category, sentiment);


--
-- Name: news_all_2029_06_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_06_entities_idx ON public.news_all_2029_06 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2029_06_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_06_financial_industries_idx ON public.news_all_2029_06 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2029_06_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_06_state_id_district_id_broadcast_date_idx ON public.news_all_2029_06 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2029_06_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_06_tags_idx ON public.news_all_2029_06 USING gin (tags);


--
-- Name: news_all_2029_06_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_06_to_tsvector_idx ON public.news_all_2029_06 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2029_07_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_07_broadcast_date_idx ON public.news_all_2029_07 USING brin (broadcast_date);


--
-- Name: news_all_2029_07_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_07_category_sentiment_idx ON public.news_all_2029_07 USING btree (category, sentiment);


--
-- Name: news_all_2029_07_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_07_entities_idx ON public.news_all_2029_07 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2029_07_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_07_financial_industries_idx ON public.news_all_2029_07 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2029_07_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_07_state_id_district_id_broadcast_date_idx ON public.news_all_2029_07 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2029_07_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_07_tags_idx ON public.news_all_2029_07 USING gin (tags);


--
-- Name: news_all_2029_07_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_07_to_tsvector_idx ON public.news_all_2029_07 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2029_08_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_08_broadcast_date_idx ON public.news_all_2029_08 USING brin (broadcast_date);


--
-- Name: news_all_2029_08_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_08_category_sentiment_idx ON public.news_all_2029_08 USING btree (category, sentiment);


--
-- Name: news_all_2029_08_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_08_entities_idx ON public.news_all_2029_08 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2029_08_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_08_financial_industries_idx ON public.news_all_2029_08 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2029_08_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_08_state_id_district_id_broadcast_date_idx ON public.news_all_2029_08 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2029_08_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_08_tags_idx ON public.news_all_2029_08 USING gin (tags);


--
-- Name: news_all_2029_08_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_08_to_tsvector_idx ON public.news_all_2029_08 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2029_09_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_09_broadcast_date_idx ON public.news_all_2029_09 USING brin (broadcast_date);


--
-- Name: news_all_2029_09_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_09_category_sentiment_idx ON public.news_all_2029_09 USING btree (category, sentiment);


--
-- Name: news_all_2029_09_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_09_entities_idx ON public.news_all_2029_09 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2029_09_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_09_financial_industries_idx ON public.news_all_2029_09 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2029_09_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_09_state_id_district_id_broadcast_date_idx ON public.news_all_2029_09 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2029_09_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_09_tags_idx ON public.news_all_2029_09 USING gin (tags);


--
-- Name: news_all_2029_09_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_09_to_tsvector_idx ON public.news_all_2029_09 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2029_10_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_10_broadcast_date_idx ON public.news_all_2029_10 USING brin (broadcast_date);


--
-- Name: news_all_2029_10_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_10_category_sentiment_idx ON public.news_all_2029_10 USING btree (category, sentiment);


--
-- Name: news_all_2029_10_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_10_entities_idx ON public.news_all_2029_10 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2029_10_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_10_financial_industries_idx ON public.news_all_2029_10 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2029_10_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_10_state_id_district_id_broadcast_date_idx ON public.news_all_2029_10 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2029_10_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_10_tags_idx ON public.news_all_2029_10 USING gin (tags);


--
-- Name: news_all_2029_10_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_10_to_tsvector_idx ON public.news_all_2029_10 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2029_11_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_11_broadcast_date_idx ON public.news_all_2029_11 USING brin (broadcast_date);


--
-- Name: news_all_2029_11_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_11_category_sentiment_idx ON public.news_all_2029_11 USING btree (category, sentiment);


--
-- Name: news_all_2029_11_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_11_entities_idx ON public.news_all_2029_11 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2029_11_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_11_financial_industries_idx ON public.news_all_2029_11 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2029_11_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_11_state_id_district_id_broadcast_date_idx ON public.news_all_2029_11 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2029_11_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_11_tags_idx ON public.news_all_2029_11 USING gin (tags);


--
-- Name: news_all_2029_11_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_11_to_tsvector_idx ON public.news_all_2029_11 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2029_12_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_12_broadcast_date_idx ON public.news_all_2029_12 USING brin (broadcast_date);


--
-- Name: news_all_2029_12_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_12_category_sentiment_idx ON public.news_all_2029_12 USING btree (category, sentiment);


--
-- Name: news_all_2029_12_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_12_entities_idx ON public.news_all_2029_12 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2029_12_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_12_financial_industries_idx ON public.news_all_2029_12 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2029_12_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_12_state_id_district_id_broadcast_date_idx ON public.news_all_2029_12 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2029_12_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_12_tags_idx ON public.news_all_2029_12 USING gin (tags);


--
-- Name: news_all_2029_12_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2029_12_to_tsvector_idx ON public.news_all_2029_12 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2030_01_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_01_broadcast_date_idx ON public.news_all_2030_01 USING brin (broadcast_date);


--
-- Name: news_all_2030_01_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_01_category_sentiment_idx ON public.news_all_2030_01 USING btree (category, sentiment);


--
-- Name: news_all_2030_01_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_01_entities_idx ON public.news_all_2030_01 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2030_01_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_01_financial_industries_idx ON public.news_all_2030_01 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2030_01_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_01_state_id_district_id_broadcast_date_idx ON public.news_all_2030_01 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2030_01_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_01_tags_idx ON public.news_all_2030_01 USING gin (tags);


--
-- Name: news_all_2030_01_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_01_to_tsvector_idx ON public.news_all_2030_01 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2030_02_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_02_broadcast_date_idx ON public.news_all_2030_02 USING brin (broadcast_date);


--
-- Name: news_all_2030_02_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_02_category_sentiment_idx ON public.news_all_2030_02 USING btree (category, sentiment);


--
-- Name: news_all_2030_02_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_02_entities_idx ON public.news_all_2030_02 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2030_02_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_02_financial_industries_idx ON public.news_all_2030_02 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2030_02_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_02_state_id_district_id_broadcast_date_idx ON public.news_all_2030_02 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2030_02_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_02_tags_idx ON public.news_all_2030_02 USING gin (tags);


--
-- Name: news_all_2030_02_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_02_to_tsvector_idx ON public.news_all_2030_02 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2030_03_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_03_broadcast_date_idx ON public.news_all_2030_03 USING brin (broadcast_date);


--
-- Name: news_all_2030_03_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_03_category_sentiment_idx ON public.news_all_2030_03 USING btree (category, sentiment);


--
-- Name: news_all_2030_03_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_03_entities_idx ON public.news_all_2030_03 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2030_03_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_03_financial_industries_idx ON public.news_all_2030_03 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2030_03_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_03_state_id_district_id_broadcast_date_idx ON public.news_all_2030_03 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2030_03_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_03_tags_idx ON public.news_all_2030_03 USING gin (tags);


--
-- Name: news_all_2030_03_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_03_to_tsvector_idx ON public.news_all_2030_03 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2030_04_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_04_broadcast_date_idx ON public.news_all_2030_04 USING brin (broadcast_date);


--
-- Name: news_all_2030_04_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_04_category_sentiment_idx ON public.news_all_2030_04 USING btree (category, sentiment);


--
-- Name: news_all_2030_04_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_04_entities_idx ON public.news_all_2030_04 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2030_04_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_04_financial_industries_idx ON public.news_all_2030_04 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2030_04_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_04_state_id_district_id_broadcast_date_idx ON public.news_all_2030_04 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2030_04_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_04_tags_idx ON public.news_all_2030_04 USING gin (tags);


--
-- Name: news_all_2030_04_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_04_to_tsvector_idx ON public.news_all_2030_04 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2030_05_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_05_broadcast_date_idx ON public.news_all_2030_05 USING brin (broadcast_date);


--
-- Name: news_all_2030_05_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_05_category_sentiment_idx ON public.news_all_2030_05 USING btree (category, sentiment);


--
-- Name: news_all_2030_05_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_05_entities_idx ON public.news_all_2030_05 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2030_05_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_05_financial_industries_idx ON public.news_all_2030_05 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2030_05_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_05_state_id_district_id_broadcast_date_idx ON public.news_all_2030_05 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2030_05_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_05_tags_idx ON public.news_all_2030_05 USING gin (tags);


--
-- Name: news_all_2030_05_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_05_to_tsvector_idx ON public.news_all_2030_05 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2030_06_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_06_broadcast_date_idx ON public.news_all_2030_06 USING brin (broadcast_date);


--
-- Name: news_all_2030_06_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_06_category_sentiment_idx ON public.news_all_2030_06 USING btree (category, sentiment);


--
-- Name: news_all_2030_06_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_06_entities_idx ON public.news_all_2030_06 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2030_06_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_06_financial_industries_idx ON public.news_all_2030_06 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2030_06_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_06_state_id_district_id_broadcast_date_idx ON public.news_all_2030_06 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2030_06_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_06_tags_idx ON public.news_all_2030_06 USING gin (tags);


--
-- Name: news_all_2030_06_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_06_to_tsvector_idx ON public.news_all_2030_06 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2030_07_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_07_broadcast_date_idx ON public.news_all_2030_07 USING brin (broadcast_date);


--
-- Name: news_all_2030_07_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_07_category_sentiment_idx ON public.news_all_2030_07 USING btree (category, sentiment);


--
-- Name: news_all_2030_07_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_07_entities_idx ON public.news_all_2030_07 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2030_07_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_07_financial_industries_idx ON public.news_all_2030_07 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2030_07_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_07_state_id_district_id_broadcast_date_idx ON public.news_all_2030_07 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2030_07_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_07_tags_idx ON public.news_all_2030_07 USING gin (tags);


--
-- Name: news_all_2030_07_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_07_to_tsvector_idx ON public.news_all_2030_07 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2030_08_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_08_broadcast_date_idx ON public.news_all_2030_08 USING brin (broadcast_date);


--
-- Name: news_all_2030_08_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_08_category_sentiment_idx ON public.news_all_2030_08 USING btree (category, sentiment);


--
-- Name: news_all_2030_08_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_08_entities_idx ON public.news_all_2030_08 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2030_08_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_08_financial_industries_idx ON public.news_all_2030_08 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2030_08_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_08_state_id_district_id_broadcast_date_idx ON public.news_all_2030_08 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2030_08_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_08_tags_idx ON public.news_all_2030_08 USING gin (tags);


--
-- Name: news_all_2030_08_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_08_to_tsvector_idx ON public.news_all_2030_08 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2030_09_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_09_broadcast_date_idx ON public.news_all_2030_09 USING brin (broadcast_date);


--
-- Name: news_all_2030_09_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_09_category_sentiment_idx ON public.news_all_2030_09 USING btree (category, sentiment);


--
-- Name: news_all_2030_09_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_09_entities_idx ON public.news_all_2030_09 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2030_09_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_09_financial_industries_idx ON public.news_all_2030_09 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2030_09_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_09_state_id_district_id_broadcast_date_idx ON public.news_all_2030_09 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2030_09_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_09_tags_idx ON public.news_all_2030_09 USING gin (tags);


--
-- Name: news_all_2030_09_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_09_to_tsvector_idx ON public.news_all_2030_09 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2030_10_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_10_broadcast_date_idx ON public.news_all_2030_10 USING brin (broadcast_date);


--
-- Name: news_all_2030_10_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_10_category_sentiment_idx ON public.news_all_2030_10 USING btree (category, sentiment);


--
-- Name: news_all_2030_10_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_10_entities_idx ON public.news_all_2030_10 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2030_10_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_10_financial_industries_idx ON public.news_all_2030_10 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2030_10_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_10_state_id_district_id_broadcast_date_idx ON public.news_all_2030_10 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2030_10_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_10_tags_idx ON public.news_all_2030_10 USING gin (tags);


--
-- Name: news_all_2030_10_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_10_to_tsvector_idx ON public.news_all_2030_10 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2030_11_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_11_broadcast_date_idx ON public.news_all_2030_11 USING brin (broadcast_date);


--
-- Name: news_all_2030_11_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_11_category_sentiment_idx ON public.news_all_2030_11 USING btree (category, sentiment);


--
-- Name: news_all_2030_11_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_11_entities_idx ON public.news_all_2030_11 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2030_11_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_11_financial_industries_idx ON public.news_all_2030_11 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2030_11_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_11_state_id_district_id_broadcast_date_idx ON public.news_all_2030_11 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2030_11_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_11_tags_idx ON public.news_all_2030_11 USING gin (tags);


--
-- Name: news_all_2030_11_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_11_to_tsvector_idx ON public.news_all_2030_11 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2030_12_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_12_broadcast_date_idx ON public.news_all_2030_12 USING brin (broadcast_date);


--
-- Name: news_all_2030_12_category_sentiment_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_12_category_sentiment_idx ON public.news_all_2030_12 USING btree (category, sentiment);


--
-- Name: news_all_2030_12_entities_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_12_entities_idx ON public.news_all_2030_12 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2030_12_financial_industries_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_12_financial_industries_idx ON public.news_all_2030_12 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2030_12_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_12_state_id_district_id_broadcast_date_idx ON public.news_all_2030_12 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2030_12_tags_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_12_tags_idx ON public.news_all_2030_12 USING gin (tags);


--
-- Name: news_all_2030_12_to_tsvector_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_all_2030_12_to_tsvector_idx ON public.news_all_2030_12 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2026_04_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2026_04_broadcast_date_idx;


--
-- Name: news_all_2026_04_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2026_04_category_sentiment_idx;


--
-- Name: news_all_2026_04_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2026_04_entities_idx;


--
-- Name: news_all_2026_04_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2026_04_financial_industries_idx;


--
-- Name: news_all_2026_04_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2026_04_pkey;


--
-- Name: news_all_2026_04_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2026_04_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2026_04_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2026_04_tags_idx;


--
-- Name: news_all_2026_04_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2026_04_to_tsvector_idx;


--
-- Name: news_all_2026_05_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2026_05_broadcast_date_idx;


--
-- Name: news_all_2026_05_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2026_05_category_sentiment_idx;


--
-- Name: news_all_2026_05_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2026_05_entities_idx;


--
-- Name: news_all_2026_05_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2026_05_financial_industries_idx;


--
-- Name: news_all_2026_05_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2026_05_pkey;


--
-- Name: news_all_2026_05_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2026_05_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2026_05_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2026_05_tags_idx;


--
-- Name: news_all_2026_05_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2026_05_to_tsvector_idx;


--
-- Name: news_all_2026_06_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2026_06_broadcast_date_idx;


--
-- Name: news_all_2026_06_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2026_06_category_sentiment_idx;


--
-- Name: news_all_2026_06_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2026_06_entities_idx;


--
-- Name: news_all_2026_06_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2026_06_financial_industries_idx;


--
-- Name: news_all_2026_06_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2026_06_pkey;


--
-- Name: news_all_2026_06_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2026_06_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2026_06_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2026_06_tags_idx;


--
-- Name: news_all_2026_06_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2026_06_to_tsvector_idx;


--
-- Name: news_all_2026_07_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2026_07_broadcast_date_idx;


--
-- Name: news_all_2026_07_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2026_07_category_sentiment_idx;


--
-- Name: news_all_2026_07_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2026_07_entities_idx;


--
-- Name: news_all_2026_07_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2026_07_financial_industries_idx;


--
-- Name: news_all_2026_07_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2026_07_pkey;


--
-- Name: news_all_2026_07_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2026_07_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2026_07_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2026_07_tags_idx;


--
-- Name: news_all_2026_07_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2026_07_to_tsvector_idx;


--
-- Name: news_all_2026_08_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2026_08_broadcast_date_idx;


--
-- Name: news_all_2026_08_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2026_08_category_sentiment_idx;


--
-- Name: news_all_2026_08_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2026_08_entities_idx;


--
-- Name: news_all_2026_08_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2026_08_financial_industries_idx;


--
-- Name: news_all_2026_08_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2026_08_pkey;


--
-- Name: news_all_2026_08_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2026_08_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2026_08_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2026_08_tags_idx;


--
-- Name: news_all_2026_08_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2026_08_to_tsvector_idx;


--
-- Name: news_all_2026_09_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2026_09_broadcast_date_idx;


--
-- Name: news_all_2026_09_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2026_09_category_sentiment_idx;


--
-- Name: news_all_2026_09_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2026_09_entities_idx;


--
-- Name: news_all_2026_09_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2026_09_financial_industries_idx;


--
-- Name: news_all_2026_09_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2026_09_pkey;


--
-- Name: news_all_2026_09_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2026_09_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2026_09_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2026_09_tags_idx;


--
-- Name: news_all_2026_09_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2026_09_to_tsvector_idx;


--
-- Name: news_all_2026_10_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2026_10_broadcast_date_idx;


--
-- Name: news_all_2026_10_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2026_10_category_sentiment_idx;


--
-- Name: news_all_2026_10_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2026_10_entities_idx;


--
-- Name: news_all_2026_10_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2026_10_financial_industries_idx;


--
-- Name: news_all_2026_10_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2026_10_pkey;


--
-- Name: news_all_2026_10_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2026_10_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2026_10_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2026_10_tags_idx;


--
-- Name: news_all_2026_10_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2026_10_to_tsvector_idx;


--
-- Name: news_all_2026_11_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2026_11_broadcast_date_idx;


--
-- Name: news_all_2026_11_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2026_11_category_sentiment_idx;


--
-- Name: news_all_2026_11_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2026_11_entities_idx;


--
-- Name: news_all_2026_11_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2026_11_financial_industries_idx;


--
-- Name: news_all_2026_11_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2026_11_pkey;


--
-- Name: news_all_2026_11_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2026_11_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2026_11_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2026_11_tags_idx;


--
-- Name: news_all_2026_11_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2026_11_to_tsvector_idx;


--
-- Name: news_all_2026_12_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2026_12_broadcast_date_idx;


--
-- Name: news_all_2026_12_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2026_12_category_sentiment_idx;


--
-- Name: news_all_2026_12_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2026_12_entities_idx;


--
-- Name: news_all_2026_12_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2026_12_financial_industries_idx;


--
-- Name: news_all_2026_12_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2026_12_pkey;


--
-- Name: news_all_2026_12_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2026_12_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2026_12_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2026_12_tags_idx;


--
-- Name: news_all_2026_12_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2026_12_to_tsvector_idx;


--
-- Name: news_all_2027_01_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2027_01_broadcast_date_idx;


--
-- Name: news_all_2027_01_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2027_01_category_sentiment_idx;


--
-- Name: news_all_2027_01_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2027_01_entities_idx;


--
-- Name: news_all_2027_01_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2027_01_financial_industries_idx;


--
-- Name: news_all_2027_01_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2027_01_pkey;


--
-- Name: news_all_2027_01_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2027_01_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2027_01_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2027_01_tags_idx;


--
-- Name: news_all_2027_01_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2027_01_to_tsvector_idx;


--
-- Name: news_all_2027_02_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2027_02_broadcast_date_idx;


--
-- Name: news_all_2027_02_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2027_02_category_sentiment_idx;


--
-- Name: news_all_2027_02_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2027_02_entities_idx;


--
-- Name: news_all_2027_02_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2027_02_financial_industries_idx;


--
-- Name: news_all_2027_02_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2027_02_pkey;


--
-- Name: news_all_2027_02_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2027_02_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2027_02_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2027_02_tags_idx;


--
-- Name: news_all_2027_02_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2027_02_to_tsvector_idx;


--
-- Name: news_all_2027_03_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2027_03_broadcast_date_idx;


--
-- Name: news_all_2027_03_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2027_03_category_sentiment_idx;


--
-- Name: news_all_2027_03_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2027_03_entities_idx;


--
-- Name: news_all_2027_03_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2027_03_financial_industries_idx;


--
-- Name: news_all_2027_03_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2027_03_pkey;


--
-- Name: news_all_2027_03_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2027_03_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2027_03_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2027_03_tags_idx;


--
-- Name: news_all_2027_03_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2027_03_to_tsvector_idx;


--
-- Name: news_all_2027_04_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2027_04_broadcast_date_idx;


--
-- Name: news_all_2027_04_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2027_04_category_sentiment_idx;


--
-- Name: news_all_2027_04_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2027_04_entities_idx;


--
-- Name: news_all_2027_04_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2027_04_financial_industries_idx;


--
-- Name: news_all_2027_04_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2027_04_pkey;


--
-- Name: news_all_2027_04_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2027_04_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2027_04_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2027_04_tags_idx;


--
-- Name: news_all_2027_04_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2027_04_to_tsvector_idx;


--
-- Name: news_all_2027_05_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2027_05_broadcast_date_idx;


--
-- Name: news_all_2027_05_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2027_05_category_sentiment_idx;


--
-- Name: news_all_2027_05_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2027_05_entities_idx;


--
-- Name: news_all_2027_05_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2027_05_financial_industries_idx;


--
-- Name: news_all_2027_05_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2027_05_pkey;


--
-- Name: news_all_2027_05_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2027_05_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2027_05_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2027_05_tags_idx;


--
-- Name: news_all_2027_05_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2027_05_to_tsvector_idx;


--
-- Name: news_all_2027_06_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2027_06_broadcast_date_idx;


--
-- Name: news_all_2027_06_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2027_06_category_sentiment_idx;


--
-- Name: news_all_2027_06_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2027_06_entities_idx;


--
-- Name: news_all_2027_06_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2027_06_financial_industries_idx;


--
-- Name: news_all_2027_06_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2027_06_pkey;


--
-- Name: news_all_2027_06_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2027_06_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2027_06_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2027_06_tags_idx;


--
-- Name: news_all_2027_06_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2027_06_to_tsvector_idx;


--
-- Name: news_all_2027_07_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2027_07_broadcast_date_idx;


--
-- Name: news_all_2027_07_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2027_07_category_sentiment_idx;


--
-- Name: news_all_2027_07_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2027_07_entities_idx;


--
-- Name: news_all_2027_07_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2027_07_financial_industries_idx;


--
-- Name: news_all_2027_07_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2027_07_pkey;


--
-- Name: news_all_2027_07_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2027_07_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2027_07_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2027_07_tags_idx;


--
-- Name: news_all_2027_07_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2027_07_to_tsvector_idx;


--
-- Name: news_all_2027_08_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2027_08_broadcast_date_idx;


--
-- Name: news_all_2027_08_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2027_08_category_sentiment_idx;


--
-- Name: news_all_2027_08_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2027_08_entities_idx;


--
-- Name: news_all_2027_08_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2027_08_financial_industries_idx;


--
-- Name: news_all_2027_08_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2027_08_pkey;


--
-- Name: news_all_2027_08_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2027_08_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2027_08_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2027_08_tags_idx;


--
-- Name: news_all_2027_08_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2027_08_to_tsvector_idx;


--
-- Name: news_all_2027_09_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2027_09_broadcast_date_idx;


--
-- Name: news_all_2027_09_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2027_09_category_sentiment_idx;


--
-- Name: news_all_2027_09_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2027_09_entities_idx;


--
-- Name: news_all_2027_09_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2027_09_financial_industries_idx;


--
-- Name: news_all_2027_09_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2027_09_pkey;


--
-- Name: news_all_2027_09_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2027_09_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2027_09_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2027_09_tags_idx;


--
-- Name: news_all_2027_09_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2027_09_to_tsvector_idx;


--
-- Name: news_all_2027_10_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2027_10_broadcast_date_idx;


--
-- Name: news_all_2027_10_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2027_10_category_sentiment_idx;


--
-- Name: news_all_2027_10_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2027_10_entities_idx;


--
-- Name: news_all_2027_10_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2027_10_financial_industries_idx;


--
-- Name: news_all_2027_10_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2027_10_pkey;


--
-- Name: news_all_2027_10_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2027_10_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2027_10_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2027_10_tags_idx;


--
-- Name: news_all_2027_10_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2027_10_to_tsvector_idx;


--
-- Name: news_all_2027_11_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2027_11_broadcast_date_idx;


--
-- Name: news_all_2027_11_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2027_11_category_sentiment_idx;


--
-- Name: news_all_2027_11_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2027_11_entities_idx;


--
-- Name: news_all_2027_11_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2027_11_financial_industries_idx;


--
-- Name: news_all_2027_11_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2027_11_pkey;


--
-- Name: news_all_2027_11_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2027_11_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2027_11_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2027_11_tags_idx;


--
-- Name: news_all_2027_11_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2027_11_to_tsvector_idx;


--
-- Name: news_all_2027_12_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2027_12_broadcast_date_idx;


--
-- Name: news_all_2027_12_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2027_12_category_sentiment_idx;


--
-- Name: news_all_2027_12_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2027_12_entities_idx;


--
-- Name: news_all_2027_12_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2027_12_financial_industries_idx;


--
-- Name: news_all_2027_12_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2027_12_pkey;


--
-- Name: news_all_2027_12_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2027_12_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2027_12_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2027_12_tags_idx;


--
-- Name: news_all_2027_12_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2027_12_to_tsvector_idx;


--
-- Name: news_all_2028_01_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2028_01_broadcast_date_idx;


--
-- Name: news_all_2028_01_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2028_01_category_sentiment_idx;


--
-- Name: news_all_2028_01_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2028_01_entities_idx;


--
-- Name: news_all_2028_01_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2028_01_financial_industries_idx;


--
-- Name: news_all_2028_01_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2028_01_pkey;


--
-- Name: news_all_2028_01_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2028_01_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2028_01_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2028_01_tags_idx;


--
-- Name: news_all_2028_01_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2028_01_to_tsvector_idx;


--
-- Name: news_all_2028_02_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2028_02_broadcast_date_idx;


--
-- Name: news_all_2028_02_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2028_02_category_sentiment_idx;


--
-- Name: news_all_2028_02_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2028_02_entities_idx;


--
-- Name: news_all_2028_02_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2028_02_financial_industries_idx;


--
-- Name: news_all_2028_02_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2028_02_pkey;


--
-- Name: news_all_2028_02_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2028_02_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2028_02_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2028_02_tags_idx;


--
-- Name: news_all_2028_02_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2028_02_to_tsvector_idx;


--
-- Name: news_all_2028_03_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2028_03_broadcast_date_idx;


--
-- Name: news_all_2028_03_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2028_03_category_sentiment_idx;


--
-- Name: news_all_2028_03_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2028_03_entities_idx;


--
-- Name: news_all_2028_03_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2028_03_financial_industries_idx;


--
-- Name: news_all_2028_03_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2028_03_pkey;


--
-- Name: news_all_2028_03_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2028_03_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2028_03_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2028_03_tags_idx;


--
-- Name: news_all_2028_03_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2028_03_to_tsvector_idx;


--
-- Name: news_all_2028_04_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2028_04_broadcast_date_idx;


--
-- Name: news_all_2028_04_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2028_04_category_sentiment_idx;


--
-- Name: news_all_2028_04_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2028_04_entities_idx;


--
-- Name: news_all_2028_04_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2028_04_financial_industries_idx;


--
-- Name: news_all_2028_04_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2028_04_pkey;


--
-- Name: news_all_2028_04_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2028_04_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2028_04_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2028_04_tags_idx;


--
-- Name: news_all_2028_04_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2028_04_to_tsvector_idx;


--
-- Name: news_all_2028_05_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2028_05_broadcast_date_idx;


--
-- Name: news_all_2028_05_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2028_05_category_sentiment_idx;


--
-- Name: news_all_2028_05_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2028_05_entities_idx;


--
-- Name: news_all_2028_05_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2028_05_financial_industries_idx;


--
-- Name: news_all_2028_05_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2028_05_pkey;


--
-- Name: news_all_2028_05_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2028_05_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2028_05_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2028_05_tags_idx;


--
-- Name: news_all_2028_05_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2028_05_to_tsvector_idx;


--
-- Name: news_all_2028_06_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2028_06_broadcast_date_idx;


--
-- Name: news_all_2028_06_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2028_06_category_sentiment_idx;


--
-- Name: news_all_2028_06_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2028_06_entities_idx;


--
-- Name: news_all_2028_06_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2028_06_financial_industries_idx;


--
-- Name: news_all_2028_06_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2028_06_pkey;


--
-- Name: news_all_2028_06_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2028_06_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2028_06_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2028_06_tags_idx;


--
-- Name: news_all_2028_06_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2028_06_to_tsvector_idx;


--
-- Name: news_all_2028_07_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2028_07_broadcast_date_idx;


--
-- Name: news_all_2028_07_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2028_07_category_sentiment_idx;


--
-- Name: news_all_2028_07_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2028_07_entities_idx;


--
-- Name: news_all_2028_07_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2028_07_financial_industries_idx;


--
-- Name: news_all_2028_07_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2028_07_pkey;


--
-- Name: news_all_2028_07_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2028_07_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2028_07_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2028_07_tags_idx;


--
-- Name: news_all_2028_07_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2028_07_to_tsvector_idx;


--
-- Name: news_all_2028_08_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2028_08_broadcast_date_idx;


--
-- Name: news_all_2028_08_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2028_08_category_sentiment_idx;


--
-- Name: news_all_2028_08_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2028_08_entities_idx;


--
-- Name: news_all_2028_08_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2028_08_financial_industries_idx;


--
-- Name: news_all_2028_08_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2028_08_pkey;


--
-- Name: news_all_2028_08_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2028_08_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2028_08_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2028_08_tags_idx;


--
-- Name: news_all_2028_08_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2028_08_to_tsvector_idx;


--
-- Name: news_all_2028_09_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2028_09_broadcast_date_idx;


--
-- Name: news_all_2028_09_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2028_09_category_sentiment_idx;


--
-- Name: news_all_2028_09_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2028_09_entities_idx;


--
-- Name: news_all_2028_09_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2028_09_financial_industries_idx;


--
-- Name: news_all_2028_09_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2028_09_pkey;


--
-- Name: news_all_2028_09_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2028_09_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2028_09_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2028_09_tags_idx;


--
-- Name: news_all_2028_09_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2028_09_to_tsvector_idx;


--
-- Name: news_all_2028_10_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2028_10_broadcast_date_idx;


--
-- Name: news_all_2028_10_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2028_10_category_sentiment_idx;


--
-- Name: news_all_2028_10_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2028_10_entities_idx;


--
-- Name: news_all_2028_10_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2028_10_financial_industries_idx;


--
-- Name: news_all_2028_10_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2028_10_pkey;


--
-- Name: news_all_2028_10_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2028_10_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2028_10_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2028_10_tags_idx;


--
-- Name: news_all_2028_10_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2028_10_to_tsvector_idx;


--
-- Name: news_all_2028_11_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2028_11_broadcast_date_idx;


--
-- Name: news_all_2028_11_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2028_11_category_sentiment_idx;


--
-- Name: news_all_2028_11_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2028_11_entities_idx;


--
-- Name: news_all_2028_11_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2028_11_financial_industries_idx;


--
-- Name: news_all_2028_11_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2028_11_pkey;


--
-- Name: news_all_2028_11_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2028_11_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2028_11_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2028_11_tags_idx;


--
-- Name: news_all_2028_11_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2028_11_to_tsvector_idx;


--
-- Name: news_all_2028_12_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2028_12_broadcast_date_idx;


--
-- Name: news_all_2028_12_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2028_12_category_sentiment_idx;


--
-- Name: news_all_2028_12_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2028_12_entities_idx;


--
-- Name: news_all_2028_12_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2028_12_financial_industries_idx;


--
-- Name: news_all_2028_12_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2028_12_pkey;


--
-- Name: news_all_2028_12_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2028_12_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2028_12_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2028_12_tags_idx;


--
-- Name: news_all_2028_12_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2028_12_to_tsvector_idx;


--
-- Name: news_all_2029_01_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2029_01_broadcast_date_idx;


--
-- Name: news_all_2029_01_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2029_01_category_sentiment_idx;


--
-- Name: news_all_2029_01_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2029_01_entities_idx;


--
-- Name: news_all_2029_01_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2029_01_financial_industries_idx;


--
-- Name: news_all_2029_01_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2029_01_pkey;


--
-- Name: news_all_2029_01_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2029_01_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2029_01_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2029_01_tags_idx;


--
-- Name: news_all_2029_01_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2029_01_to_tsvector_idx;


--
-- Name: news_all_2029_02_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2029_02_broadcast_date_idx;


--
-- Name: news_all_2029_02_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2029_02_category_sentiment_idx;


--
-- Name: news_all_2029_02_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2029_02_entities_idx;


--
-- Name: news_all_2029_02_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2029_02_financial_industries_idx;


--
-- Name: news_all_2029_02_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2029_02_pkey;


--
-- Name: news_all_2029_02_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2029_02_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2029_02_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2029_02_tags_idx;


--
-- Name: news_all_2029_02_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2029_02_to_tsvector_idx;


--
-- Name: news_all_2029_03_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2029_03_broadcast_date_idx;


--
-- Name: news_all_2029_03_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2029_03_category_sentiment_idx;


--
-- Name: news_all_2029_03_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2029_03_entities_idx;


--
-- Name: news_all_2029_03_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2029_03_financial_industries_idx;


--
-- Name: news_all_2029_03_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2029_03_pkey;


--
-- Name: news_all_2029_03_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2029_03_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2029_03_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2029_03_tags_idx;


--
-- Name: news_all_2029_03_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2029_03_to_tsvector_idx;


--
-- Name: news_all_2029_04_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2029_04_broadcast_date_idx;


--
-- Name: news_all_2029_04_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2029_04_category_sentiment_idx;


--
-- Name: news_all_2029_04_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2029_04_entities_idx;


--
-- Name: news_all_2029_04_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2029_04_financial_industries_idx;


--
-- Name: news_all_2029_04_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2029_04_pkey;


--
-- Name: news_all_2029_04_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2029_04_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2029_04_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2029_04_tags_idx;


--
-- Name: news_all_2029_04_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2029_04_to_tsvector_idx;


--
-- Name: news_all_2029_05_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2029_05_broadcast_date_idx;


--
-- Name: news_all_2029_05_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2029_05_category_sentiment_idx;


--
-- Name: news_all_2029_05_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2029_05_entities_idx;


--
-- Name: news_all_2029_05_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2029_05_financial_industries_idx;


--
-- Name: news_all_2029_05_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2029_05_pkey;


--
-- Name: news_all_2029_05_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2029_05_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2029_05_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2029_05_tags_idx;


--
-- Name: news_all_2029_05_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2029_05_to_tsvector_idx;


--
-- Name: news_all_2029_06_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2029_06_broadcast_date_idx;


--
-- Name: news_all_2029_06_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2029_06_category_sentiment_idx;


--
-- Name: news_all_2029_06_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2029_06_entities_idx;


--
-- Name: news_all_2029_06_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2029_06_financial_industries_idx;


--
-- Name: news_all_2029_06_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2029_06_pkey;


--
-- Name: news_all_2029_06_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2029_06_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2029_06_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2029_06_tags_idx;


--
-- Name: news_all_2029_06_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2029_06_to_tsvector_idx;


--
-- Name: news_all_2029_07_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2029_07_broadcast_date_idx;


--
-- Name: news_all_2029_07_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2029_07_category_sentiment_idx;


--
-- Name: news_all_2029_07_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2029_07_entities_idx;


--
-- Name: news_all_2029_07_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2029_07_financial_industries_idx;


--
-- Name: news_all_2029_07_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2029_07_pkey;


--
-- Name: news_all_2029_07_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2029_07_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2029_07_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2029_07_tags_idx;


--
-- Name: news_all_2029_07_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2029_07_to_tsvector_idx;


--
-- Name: news_all_2029_08_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2029_08_broadcast_date_idx;


--
-- Name: news_all_2029_08_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2029_08_category_sentiment_idx;


--
-- Name: news_all_2029_08_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2029_08_entities_idx;


--
-- Name: news_all_2029_08_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2029_08_financial_industries_idx;


--
-- Name: news_all_2029_08_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2029_08_pkey;


--
-- Name: news_all_2029_08_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2029_08_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2029_08_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2029_08_tags_idx;


--
-- Name: news_all_2029_08_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2029_08_to_tsvector_idx;


--
-- Name: news_all_2029_09_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2029_09_broadcast_date_idx;


--
-- Name: news_all_2029_09_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2029_09_category_sentiment_idx;


--
-- Name: news_all_2029_09_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2029_09_entities_idx;


--
-- Name: news_all_2029_09_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2029_09_financial_industries_idx;


--
-- Name: news_all_2029_09_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2029_09_pkey;


--
-- Name: news_all_2029_09_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2029_09_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2029_09_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2029_09_tags_idx;


--
-- Name: news_all_2029_09_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2029_09_to_tsvector_idx;


--
-- Name: news_all_2029_10_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2029_10_broadcast_date_idx;


--
-- Name: news_all_2029_10_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2029_10_category_sentiment_idx;


--
-- Name: news_all_2029_10_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2029_10_entities_idx;


--
-- Name: news_all_2029_10_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2029_10_financial_industries_idx;


--
-- Name: news_all_2029_10_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2029_10_pkey;


--
-- Name: news_all_2029_10_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2029_10_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2029_10_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2029_10_tags_idx;


--
-- Name: news_all_2029_10_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2029_10_to_tsvector_idx;


--
-- Name: news_all_2029_11_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2029_11_broadcast_date_idx;


--
-- Name: news_all_2029_11_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2029_11_category_sentiment_idx;


--
-- Name: news_all_2029_11_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2029_11_entities_idx;


--
-- Name: news_all_2029_11_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2029_11_financial_industries_idx;


--
-- Name: news_all_2029_11_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2029_11_pkey;


--
-- Name: news_all_2029_11_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2029_11_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2029_11_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2029_11_tags_idx;


--
-- Name: news_all_2029_11_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2029_11_to_tsvector_idx;


--
-- Name: news_all_2029_12_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2029_12_broadcast_date_idx;


--
-- Name: news_all_2029_12_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2029_12_category_sentiment_idx;


--
-- Name: news_all_2029_12_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2029_12_entities_idx;


--
-- Name: news_all_2029_12_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2029_12_financial_industries_idx;


--
-- Name: news_all_2029_12_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2029_12_pkey;


--
-- Name: news_all_2029_12_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2029_12_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2029_12_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2029_12_tags_idx;


--
-- Name: news_all_2029_12_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2029_12_to_tsvector_idx;


--
-- Name: news_all_2030_01_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2030_01_broadcast_date_idx;


--
-- Name: news_all_2030_01_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2030_01_category_sentiment_idx;


--
-- Name: news_all_2030_01_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2030_01_entities_idx;


--
-- Name: news_all_2030_01_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2030_01_financial_industries_idx;


--
-- Name: news_all_2030_01_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2030_01_pkey;


--
-- Name: news_all_2030_01_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2030_01_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2030_01_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2030_01_tags_idx;


--
-- Name: news_all_2030_01_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2030_01_to_tsvector_idx;


--
-- Name: news_all_2030_02_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2030_02_broadcast_date_idx;


--
-- Name: news_all_2030_02_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2030_02_category_sentiment_idx;


--
-- Name: news_all_2030_02_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2030_02_entities_idx;


--
-- Name: news_all_2030_02_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2030_02_financial_industries_idx;


--
-- Name: news_all_2030_02_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2030_02_pkey;


--
-- Name: news_all_2030_02_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2030_02_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2030_02_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2030_02_tags_idx;


--
-- Name: news_all_2030_02_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2030_02_to_tsvector_idx;


--
-- Name: news_all_2030_03_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2030_03_broadcast_date_idx;


--
-- Name: news_all_2030_03_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2030_03_category_sentiment_idx;


--
-- Name: news_all_2030_03_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2030_03_entities_idx;


--
-- Name: news_all_2030_03_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2030_03_financial_industries_idx;


--
-- Name: news_all_2030_03_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2030_03_pkey;


--
-- Name: news_all_2030_03_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2030_03_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2030_03_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2030_03_tags_idx;


--
-- Name: news_all_2030_03_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2030_03_to_tsvector_idx;


--
-- Name: news_all_2030_04_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2030_04_broadcast_date_idx;


--
-- Name: news_all_2030_04_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2030_04_category_sentiment_idx;


--
-- Name: news_all_2030_04_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2030_04_entities_idx;


--
-- Name: news_all_2030_04_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2030_04_financial_industries_idx;


--
-- Name: news_all_2030_04_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2030_04_pkey;


--
-- Name: news_all_2030_04_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2030_04_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2030_04_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2030_04_tags_idx;


--
-- Name: news_all_2030_04_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2030_04_to_tsvector_idx;


--
-- Name: news_all_2030_05_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2030_05_broadcast_date_idx;


--
-- Name: news_all_2030_05_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2030_05_category_sentiment_idx;


--
-- Name: news_all_2030_05_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2030_05_entities_idx;


--
-- Name: news_all_2030_05_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2030_05_financial_industries_idx;


--
-- Name: news_all_2030_05_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2030_05_pkey;


--
-- Name: news_all_2030_05_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2030_05_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2030_05_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2030_05_tags_idx;


--
-- Name: news_all_2030_05_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2030_05_to_tsvector_idx;


--
-- Name: news_all_2030_06_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2030_06_broadcast_date_idx;


--
-- Name: news_all_2030_06_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2030_06_category_sentiment_idx;


--
-- Name: news_all_2030_06_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2030_06_entities_idx;


--
-- Name: news_all_2030_06_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2030_06_financial_industries_idx;


--
-- Name: news_all_2030_06_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2030_06_pkey;


--
-- Name: news_all_2030_06_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2030_06_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2030_06_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2030_06_tags_idx;


--
-- Name: news_all_2030_06_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2030_06_to_tsvector_idx;


--
-- Name: news_all_2030_07_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2030_07_broadcast_date_idx;


--
-- Name: news_all_2030_07_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2030_07_category_sentiment_idx;


--
-- Name: news_all_2030_07_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2030_07_entities_idx;


--
-- Name: news_all_2030_07_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2030_07_financial_industries_idx;


--
-- Name: news_all_2030_07_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2030_07_pkey;


--
-- Name: news_all_2030_07_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2030_07_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2030_07_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2030_07_tags_idx;


--
-- Name: news_all_2030_07_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2030_07_to_tsvector_idx;


--
-- Name: news_all_2030_08_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2030_08_broadcast_date_idx;


--
-- Name: news_all_2030_08_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2030_08_category_sentiment_idx;


--
-- Name: news_all_2030_08_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2030_08_entities_idx;


--
-- Name: news_all_2030_08_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2030_08_financial_industries_idx;


--
-- Name: news_all_2030_08_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2030_08_pkey;


--
-- Name: news_all_2030_08_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2030_08_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2030_08_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2030_08_tags_idx;


--
-- Name: news_all_2030_08_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2030_08_to_tsvector_idx;


--
-- Name: news_all_2030_09_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2030_09_broadcast_date_idx;


--
-- Name: news_all_2030_09_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2030_09_category_sentiment_idx;


--
-- Name: news_all_2030_09_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2030_09_entities_idx;


--
-- Name: news_all_2030_09_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2030_09_financial_industries_idx;


--
-- Name: news_all_2030_09_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2030_09_pkey;


--
-- Name: news_all_2030_09_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2030_09_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2030_09_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2030_09_tags_idx;


--
-- Name: news_all_2030_09_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2030_09_to_tsvector_idx;


--
-- Name: news_all_2030_10_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2030_10_broadcast_date_idx;


--
-- Name: news_all_2030_10_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2030_10_category_sentiment_idx;


--
-- Name: news_all_2030_10_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2030_10_entities_idx;


--
-- Name: news_all_2030_10_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2030_10_financial_industries_idx;


--
-- Name: news_all_2030_10_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2030_10_pkey;


--
-- Name: news_all_2030_10_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2030_10_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2030_10_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2030_10_tags_idx;


--
-- Name: news_all_2030_10_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2030_10_to_tsvector_idx;


--
-- Name: news_all_2030_11_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2030_11_broadcast_date_idx;


--
-- Name: news_all_2030_11_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2030_11_category_sentiment_idx;


--
-- Name: news_all_2030_11_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2030_11_entities_idx;


--
-- Name: news_all_2030_11_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2030_11_financial_industries_idx;


--
-- Name: news_all_2030_11_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2030_11_pkey;


--
-- Name: news_all_2030_11_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2030_11_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2030_11_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2030_11_tags_idx;


--
-- Name: news_all_2030_11_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2030_11_to_tsvector_idx;


--
-- Name: news_all_2030_12_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2030_12_broadcast_date_idx;


--
-- Name: news_all_2030_12_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2030_12_category_sentiment_idx;


--
-- Name: news_all_2030_12_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2030_12_entities_idx;


--
-- Name: news_all_2030_12_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2030_12_financial_industries_idx;


--
-- Name: news_all_2030_12_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2030_12_pkey;


--
-- Name: news_all_2030_12_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2030_12_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2030_12_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2030_12_tags_idx;


--
-- Name: news_all_2030_12_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2030_12_to_tsvector_idx;


--
-- Name: api_keys api_keys_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: districts districts_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.districts
    ADD CONSTRAINT districts_state_id_fkey FOREIGN KEY (state_id) REFERENCES public.states(id) ON DELETE CASCADE;


--
-- Name: refresh_tokens fk_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: news_all news_all_district_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public.news_all
    ADD CONSTRAINT news_all_district_id_fkey FOREIGN KEY (district_id) REFERENCES public.districts(id);


--
-- Name: news_all news_all_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public.news_all
    ADD CONSTRAINT news_all_state_id_fkey FOREIGN KEY (state_id) REFERENCES public.states(id);


--
-- Name: users users_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.plans(id);


--
-- PostgreSQL database dump complete
--

\unrestrict 3OksZROxbSLj7AVHa9bSw4ebIs9PeV8mcXSG7C33bDZm1m0wW4eP2PJuEOmOslh

