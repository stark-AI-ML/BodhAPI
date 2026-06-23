\restrict dbmate

-- Dumped from database version 18.4 (Debian 18.4-1.pgdg13+1)
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
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: access_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.access_type AS ENUM (
    'free',
    'pro',
    'ultra'
);


--
-- Name: crime_severity; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.crime_severity AS ENUM (
    'NONE',
    'LOW',
    'MODERATE',
    'EXTREME'
);


--
-- Name: emergency_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.emergency_type AS ENUM (
    'NONE',
    'PUBLIC_HEALTH',
    'NATURAL_DISASTER',
    'WAR_CONFLICT',
    'CIVIL_UNREST'
);


--
-- Name: impact_scope_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.impact_scope_type AS ENUM (
    'Local',
    'District',
    'State',
    'National',
    'International'
);


--
-- Name: news_category; Type: TYPE; Schema: public; Owner: -
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


--
-- Name: roles; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.roles AS ENUM (
    'user',
    'admin',
    'employe'
);


--
-- Name: sentiment_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.sentiment_type AS ENUM (
    'Positive',
    'Neutral',
    'Negative'
);


--
-- Name: create_monthly_partition(date); Type: FUNCTION; Schema: public; Owner: -
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


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: api_keys; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: api_keys_new_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.api_keys_new_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: api_keys_new_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.api_keys_new_id_seq OWNED BY public.api_keys.id;


--
-- Name: channel_transcripts; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: channel_transcripts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.channel_transcripts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: channel_transcripts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.channel_transcripts_id_seq OWNED BY public.channel_transcripts.id;


--
-- Name: districts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.districts (
    id bigint NOT NULL,
    state_id bigint NOT NULL,
    name character varying(100) NOT NULL
);


--
-- Name: districts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.districts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: districts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.districts_id_seq OWNED BY public.districts.id;


--
-- Name: news_all; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.news_all_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: news_all_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.news_all_id_seq OWNED BY public.news_all.id;


--
-- Name: news_all_2026_04; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2026_05; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2026_06; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2026_07; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2026_08; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2026_09; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2026_10; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2026_11; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2026_12; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2027_01; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2027_02; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2027_03; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2027_04; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2027_05; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2027_06; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2027_07; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2027_08; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2027_09; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2027_10; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2027_11; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2027_12; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2028_01; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2028_02; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2028_03; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2028_04; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2028_05; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2028_06; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2028_07; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2028_08; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2028_09; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2028_10; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2028_11; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2028_12; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2029_01; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2029_02; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2029_03; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2029_04; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2029_05; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2029_06; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2029_07; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2029_08; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2029_09; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2029_10; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2029_11; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2029_12; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2030_01; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2030_02; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2030_03; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2030_04; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2030_05; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2030_06; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2030_07; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2030_08; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2030_09; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2030_10; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2030_11; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2030_12; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plans (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    token_per_day integer CONSTRAINT plans_request_per_day_not_null NOT NULL,
    token_per_minute integer CONSTRAINT plans_request_per_minute_not_null NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    max_key integer DEFAULT 5 NOT NULL
);


--
-- Name: plans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.plans_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.plans_id_seq OWNED BY public.plans.id;


--
-- Name: refresh_tokens; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: state_transcripts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.state_transcripts (
    state_name text NOT NULL,
    news_transcript text,
    finance_transcript text,
    created_at timestamp without time zone DEFAULT now(),
    is_used boolean DEFAULT false,
    max_cnt smallint DEFAULT 0
);


--
-- Name: states; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.states (
    id bigint NOT NULL,
    name character varying(100) NOT NULL
);


--
-- Name: states_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.states_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: states_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.states_id_seq OWNED BY public.states.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: news_all_2026_04; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2026_04 FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');


--
-- Name: news_all_2026_05; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2026_05 FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');


--
-- Name: news_all_2026_06; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2026_06 FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');


--
-- Name: news_all_2026_07; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2026_07 FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');


--
-- Name: news_all_2026_08; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2026_08 FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');


--
-- Name: news_all_2026_09; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2026_09 FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');


--
-- Name: news_all_2026_10; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2026_10 FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');


--
-- Name: news_all_2026_11; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2026_11 FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');


--
-- Name: news_all_2026_12; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2026_12 FOR VALUES FROM ('2026-12-01') TO ('2027-01-01');


--
-- Name: news_all_2027_01; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2027_01 FOR VALUES FROM ('2027-01-01') TO ('2027-02-01');


--
-- Name: news_all_2027_02; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2027_02 FOR VALUES FROM ('2027-02-01') TO ('2027-03-01');


--
-- Name: news_all_2027_03; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2027_03 FOR VALUES FROM ('2027-03-01') TO ('2027-04-01');


--
-- Name: news_all_2027_04; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2027_04 FOR VALUES FROM ('2027-04-01') TO ('2027-05-01');


--
-- Name: news_all_2027_05; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2027_05 FOR VALUES FROM ('2027-05-01') TO ('2027-06-01');


--
-- Name: news_all_2027_06; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2027_06 FOR VALUES FROM ('2027-06-01') TO ('2027-07-01');


--
-- Name: news_all_2027_07; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2027_07 FOR VALUES FROM ('2027-07-01') TO ('2027-08-01');


--
-- Name: news_all_2027_08; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2027_08 FOR VALUES FROM ('2027-08-01') TO ('2027-09-01');


--
-- Name: news_all_2027_09; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2027_09 FOR VALUES FROM ('2027-09-01') TO ('2027-10-01');


--
-- Name: news_all_2027_10; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2027_10 FOR VALUES FROM ('2027-10-01') TO ('2027-11-01');


--
-- Name: news_all_2027_11; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2027_11 FOR VALUES FROM ('2027-11-01') TO ('2027-12-01');


--
-- Name: news_all_2027_12; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2027_12 FOR VALUES FROM ('2027-12-01') TO ('2028-01-01');


--
-- Name: news_all_2028_01; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2028_01 FOR VALUES FROM ('2028-01-01') TO ('2028-02-01');


--
-- Name: news_all_2028_02; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2028_02 FOR VALUES FROM ('2028-02-01') TO ('2028-03-01');


--
-- Name: news_all_2028_03; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2028_03 FOR VALUES FROM ('2028-03-01') TO ('2028-04-01');


--
-- Name: news_all_2028_04; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2028_04 FOR VALUES FROM ('2028-04-01') TO ('2028-05-01');


--
-- Name: news_all_2028_05; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2028_05 FOR VALUES FROM ('2028-05-01') TO ('2028-06-01');


--
-- Name: news_all_2028_06; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2028_06 FOR VALUES FROM ('2028-06-01') TO ('2028-07-01');


--
-- Name: news_all_2028_07; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2028_07 FOR VALUES FROM ('2028-07-01') TO ('2028-08-01');


--
-- Name: news_all_2028_08; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2028_08 FOR VALUES FROM ('2028-08-01') TO ('2028-09-01');


--
-- Name: news_all_2028_09; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2028_09 FOR VALUES FROM ('2028-09-01') TO ('2028-10-01');


--
-- Name: news_all_2028_10; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2028_10 FOR VALUES FROM ('2028-10-01') TO ('2028-11-01');


--
-- Name: news_all_2028_11; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2028_11 FOR VALUES FROM ('2028-11-01') TO ('2028-12-01');


--
-- Name: news_all_2028_12; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2028_12 FOR VALUES FROM ('2028-12-01') TO ('2029-01-01');


--
-- Name: news_all_2029_01; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2029_01 FOR VALUES FROM ('2029-01-01') TO ('2029-02-01');


--
-- Name: news_all_2029_02; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2029_02 FOR VALUES FROM ('2029-02-01') TO ('2029-03-01');


--
-- Name: news_all_2029_03; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2029_03 FOR VALUES FROM ('2029-03-01') TO ('2029-04-01');


--
-- Name: news_all_2029_04; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2029_04 FOR VALUES FROM ('2029-04-01') TO ('2029-05-01');


--
-- Name: news_all_2029_05; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2029_05 FOR VALUES FROM ('2029-05-01') TO ('2029-06-01');


--
-- Name: news_all_2029_06; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2029_06 FOR VALUES FROM ('2029-06-01') TO ('2029-07-01');


--
-- Name: news_all_2029_07; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2029_07 FOR VALUES FROM ('2029-07-01') TO ('2029-08-01');


--
-- Name: news_all_2029_08; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2029_08 FOR VALUES FROM ('2029-08-01') TO ('2029-09-01');


--
-- Name: news_all_2029_09; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2029_09 FOR VALUES FROM ('2029-09-01') TO ('2029-10-01');


--
-- Name: news_all_2029_10; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2029_10 FOR VALUES FROM ('2029-10-01') TO ('2029-11-01');


--
-- Name: news_all_2029_11; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2029_11 FOR VALUES FROM ('2029-11-01') TO ('2029-12-01');


--
-- Name: news_all_2029_12; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2029_12 FOR VALUES FROM ('2029-12-01') TO ('2030-01-01');


--
-- Name: news_all_2030_01; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2030_01 FOR VALUES FROM ('2030-01-01') TO ('2030-02-01');


--
-- Name: news_all_2030_02; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2030_02 FOR VALUES FROM ('2030-02-01') TO ('2030-03-01');


--
-- Name: news_all_2030_03; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2030_03 FOR VALUES FROM ('2030-03-01') TO ('2030-04-01');


--
-- Name: news_all_2030_04; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2030_04 FOR VALUES FROM ('2030-04-01') TO ('2030-05-01');


--
-- Name: news_all_2030_05; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2030_05 FOR VALUES FROM ('2030-05-01') TO ('2030-06-01');


--
-- Name: news_all_2030_06; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2030_06 FOR VALUES FROM ('2030-06-01') TO ('2030-07-01');


--
-- Name: news_all_2030_07; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2030_07 FOR VALUES FROM ('2030-07-01') TO ('2030-08-01');


--
-- Name: news_all_2030_08; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2030_08 FOR VALUES FROM ('2030-08-01') TO ('2030-09-01');


--
-- Name: news_all_2030_09; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2030_09 FOR VALUES FROM ('2030-09-01') TO ('2030-10-01');


--
-- Name: news_all_2030_10; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2030_10 FOR VALUES FROM ('2030-10-01') TO ('2030-11-01');


--
-- Name: news_all_2030_11; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2030_11 FOR VALUES FROM ('2030-11-01') TO ('2030-12-01');


--
-- Name: news_all_2030_12; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ATTACH PARTITION public.news_all_2030_12 FOR VALUES FROM ('2030-12-01') TO ('2031-01-01');


--
-- Name: api_keys id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_keys ALTER COLUMN id SET DEFAULT nextval('public.api_keys_new_id_seq'::regclass);


--
-- Name: channel_transcripts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.channel_transcripts ALTER COLUMN id SET DEFAULT nextval('public.channel_transcripts_id_seq'::regclass);


--
-- Name: districts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.districts ALTER COLUMN id SET DEFAULT nextval('public.districts_id_seq'::regclass);


--
-- Name: news_all id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all ALTER COLUMN id SET DEFAULT nextval('public.news_all_id_seq'::regclass);


--
-- Name: plans id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plans ALTER COLUMN id SET DEFAULT nextval('public.plans_id_seq'::regclass);


--
-- Name: states id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.states ALTER COLUMN id SET DEFAULT nextval('public.states_id_seq'::regclass);


--
-- Name: api_keys api_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_pkey PRIMARY KEY (id);


--
-- Name: channel_transcripts channel_transcripts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.channel_transcripts
    ADD CONSTRAINT channel_transcripts_pkey PRIMARY KEY (id);


--
-- Name: districts districts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.districts
    ADD CONSTRAINT districts_pkey PRIMARY KEY (id);


--
-- Name: districts districts_state_id_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.districts
    ADD CONSTRAINT districts_state_id_name_key UNIQUE (state_id, name);


--
-- Name: news_all news_all_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all
    ADD CONSTRAINT news_all_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2026_04 news_all_2026_04_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2026_04
    ADD CONSTRAINT news_all_2026_04_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2026_05 news_all_2026_05_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2026_05
    ADD CONSTRAINT news_all_2026_05_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2026_06 news_all_2026_06_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2026_06
    ADD CONSTRAINT news_all_2026_06_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2026_07 news_all_2026_07_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2026_07
    ADD CONSTRAINT news_all_2026_07_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2026_08 news_all_2026_08_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2026_08
    ADD CONSTRAINT news_all_2026_08_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2026_09 news_all_2026_09_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2026_09
    ADD CONSTRAINT news_all_2026_09_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2026_10 news_all_2026_10_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2026_10
    ADD CONSTRAINT news_all_2026_10_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2026_11 news_all_2026_11_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2026_11
    ADD CONSTRAINT news_all_2026_11_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2026_12 news_all_2026_12_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2026_12
    ADD CONSTRAINT news_all_2026_12_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2027_01 news_all_2027_01_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2027_01
    ADD CONSTRAINT news_all_2027_01_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2027_02 news_all_2027_02_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2027_02
    ADD CONSTRAINT news_all_2027_02_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2027_03 news_all_2027_03_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2027_03
    ADD CONSTRAINT news_all_2027_03_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2027_04 news_all_2027_04_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2027_04
    ADD CONSTRAINT news_all_2027_04_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2027_05 news_all_2027_05_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2027_05
    ADD CONSTRAINT news_all_2027_05_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2027_06 news_all_2027_06_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2027_06
    ADD CONSTRAINT news_all_2027_06_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2027_07 news_all_2027_07_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2027_07
    ADD CONSTRAINT news_all_2027_07_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2027_08 news_all_2027_08_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2027_08
    ADD CONSTRAINT news_all_2027_08_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2027_09 news_all_2027_09_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2027_09
    ADD CONSTRAINT news_all_2027_09_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2027_10 news_all_2027_10_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2027_10
    ADD CONSTRAINT news_all_2027_10_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2027_11 news_all_2027_11_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2027_11
    ADD CONSTRAINT news_all_2027_11_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2027_12 news_all_2027_12_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2027_12
    ADD CONSTRAINT news_all_2027_12_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2028_01 news_all_2028_01_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2028_01
    ADD CONSTRAINT news_all_2028_01_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2028_02 news_all_2028_02_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2028_02
    ADD CONSTRAINT news_all_2028_02_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2028_03 news_all_2028_03_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2028_03
    ADD CONSTRAINT news_all_2028_03_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2028_04 news_all_2028_04_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2028_04
    ADD CONSTRAINT news_all_2028_04_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2028_05 news_all_2028_05_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2028_05
    ADD CONSTRAINT news_all_2028_05_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2028_06 news_all_2028_06_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2028_06
    ADD CONSTRAINT news_all_2028_06_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2028_07 news_all_2028_07_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2028_07
    ADD CONSTRAINT news_all_2028_07_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2028_08 news_all_2028_08_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2028_08
    ADD CONSTRAINT news_all_2028_08_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2028_09 news_all_2028_09_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2028_09
    ADD CONSTRAINT news_all_2028_09_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2028_10 news_all_2028_10_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2028_10
    ADD CONSTRAINT news_all_2028_10_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2028_11 news_all_2028_11_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2028_11
    ADD CONSTRAINT news_all_2028_11_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2028_12 news_all_2028_12_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2028_12
    ADD CONSTRAINT news_all_2028_12_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2029_01 news_all_2029_01_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2029_01
    ADD CONSTRAINT news_all_2029_01_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2029_02 news_all_2029_02_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2029_02
    ADD CONSTRAINT news_all_2029_02_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2029_03 news_all_2029_03_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2029_03
    ADD CONSTRAINT news_all_2029_03_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2029_04 news_all_2029_04_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2029_04
    ADD CONSTRAINT news_all_2029_04_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2029_05 news_all_2029_05_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2029_05
    ADD CONSTRAINT news_all_2029_05_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2029_06 news_all_2029_06_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2029_06
    ADD CONSTRAINT news_all_2029_06_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2029_07 news_all_2029_07_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2029_07
    ADD CONSTRAINT news_all_2029_07_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2029_08 news_all_2029_08_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2029_08
    ADD CONSTRAINT news_all_2029_08_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2029_09 news_all_2029_09_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2029_09
    ADD CONSTRAINT news_all_2029_09_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2029_10 news_all_2029_10_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2029_10
    ADD CONSTRAINT news_all_2029_10_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2029_11 news_all_2029_11_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2029_11
    ADD CONSTRAINT news_all_2029_11_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2029_12 news_all_2029_12_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2029_12
    ADD CONSTRAINT news_all_2029_12_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2030_01 news_all_2030_01_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2030_01
    ADD CONSTRAINT news_all_2030_01_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2030_02 news_all_2030_02_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2030_02
    ADD CONSTRAINT news_all_2030_02_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2030_03 news_all_2030_03_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2030_03
    ADD CONSTRAINT news_all_2030_03_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2030_04 news_all_2030_04_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2030_04
    ADD CONSTRAINT news_all_2030_04_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2030_05 news_all_2030_05_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2030_05
    ADD CONSTRAINT news_all_2030_05_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2030_06 news_all_2030_06_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2030_06
    ADD CONSTRAINT news_all_2030_06_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2030_07 news_all_2030_07_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2030_07
    ADD CONSTRAINT news_all_2030_07_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2030_08 news_all_2030_08_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2030_08
    ADD CONSTRAINT news_all_2030_08_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2030_09 news_all_2030_09_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2030_09
    ADD CONSTRAINT news_all_2030_09_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2030_10 news_all_2030_10_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2030_10
    ADD CONSTRAINT news_all_2030_10_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2030_11 news_all_2030_11_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2030_11
    ADD CONSTRAINT news_all_2030_11_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: news_all_2030_12 news_all_2030_12_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_all_2030_12
    ADD CONSTRAINT news_all_2030_12_pkey PRIMARY KEY (id, broadcast_date);


--
-- Name: plans plans_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plans
    ADD CONSTRAINT plans_name_key UNIQUE (name);


--
-- Name: plans plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plans
    ADD CONSTRAINT plans_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_jwt_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_jwt_id_key UNIQUE (jwt_id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: state_transcripts state_transcripts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.state_transcripts
    ADD CONSTRAINT state_transcripts_pkey PRIMARY KEY (state_name);


--
-- Name: states states_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.states
    ADD CONSTRAINT states_name_key UNIQUE (name);


--
-- Name: states states_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.states
    ADD CONSTRAINT states_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_google_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_google_id_key UNIQUE (google_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_channel_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_channel_id ON public.channel_transcripts USING btree (channel_id);


--
-- Name: idx_news_broadcast_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_news_broadcast_date_brin ON ONLY public.news_all USING brin (broadcast_date);


--
-- Name: idx_news_category_sentiment; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_news_category_sentiment ON ONLY public.news_all USING btree (category, sentiment);


--
-- Name: idx_news_entities_gin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_news_entities_gin ON ONLY public.news_all USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: idx_news_financial_industries; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_news_financial_industries ON ONLY public.news_all USING gin (financial_industries jsonb_path_ops);


--
-- Name: idx_news_headline_search; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_news_headline_search ON ONLY public.news_all USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: idx_news_state_district_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_news_state_district_date ON ONLY public.news_all USING btree (state_id, district_id, broadcast_date);


--
-- Name: idx_news_tags_gin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_news_tags_gin ON ONLY public.news_all USING gin (tags);


--
-- Name: idx_prefix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_prefix ON public.api_keys USING btree (key_prefix);


--
-- Name: idx_refresh_jwt_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_refresh_jwt_id ON public.refresh_tokens USING btree (jwt_id);


--
-- Name: idx_refresh_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_refresh_user ON public.refresh_tokens USING btree (user_id);


--
-- Name: idx_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user ON public.api_keys USING btree (user_id);


--
-- Name: idx_users_google_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_users_google_id ON public.users USING btree (google_id);


--
-- Name: news_all_2026_04_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_04_broadcast_date_idx ON public.news_all_2026_04 USING brin (broadcast_date);


--
-- Name: news_all_2026_04_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_04_category_sentiment_idx ON public.news_all_2026_04 USING btree (category, sentiment);


--
-- Name: news_all_2026_04_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_04_entities_idx ON public.news_all_2026_04 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2026_04_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_04_financial_industries_idx ON public.news_all_2026_04 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2026_04_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_04_state_id_district_id_broadcast_date_idx ON public.news_all_2026_04 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2026_04_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_04_tags_idx ON public.news_all_2026_04 USING gin (tags);


--
-- Name: news_all_2026_04_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_04_to_tsvector_idx ON public.news_all_2026_04 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2026_05_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_05_broadcast_date_idx ON public.news_all_2026_05 USING brin (broadcast_date);


--
-- Name: news_all_2026_05_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_05_category_sentiment_idx ON public.news_all_2026_05 USING btree (category, sentiment);


--
-- Name: news_all_2026_05_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_05_entities_idx ON public.news_all_2026_05 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2026_05_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_05_financial_industries_idx ON public.news_all_2026_05 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2026_05_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_05_state_id_district_id_broadcast_date_idx ON public.news_all_2026_05 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2026_05_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_05_tags_idx ON public.news_all_2026_05 USING gin (tags);


--
-- Name: news_all_2026_05_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_05_to_tsvector_idx ON public.news_all_2026_05 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2026_06_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_06_broadcast_date_idx ON public.news_all_2026_06 USING brin (broadcast_date);


--
-- Name: news_all_2026_06_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_06_category_sentiment_idx ON public.news_all_2026_06 USING btree (category, sentiment);


--
-- Name: news_all_2026_06_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_06_entities_idx ON public.news_all_2026_06 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2026_06_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_06_financial_industries_idx ON public.news_all_2026_06 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2026_06_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_06_state_id_district_id_broadcast_date_idx ON public.news_all_2026_06 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2026_06_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_06_tags_idx ON public.news_all_2026_06 USING gin (tags);


--
-- Name: news_all_2026_06_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_06_to_tsvector_idx ON public.news_all_2026_06 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2026_07_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_07_broadcast_date_idx ON public.news_all_2026_07 USING brin (broadcast_date);


--
-- Name: news_all_2026_07_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_07_category_sentiment_idx ON public.news_all_2026_07 USING btree (category, sentiment);


--
-- Name: news_all_2026_07_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_07_entities_idx ON public.news_all_2026_07 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2026_07_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_07_financial_industries_idx ON public.news_all_2026_07 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2026_07_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_07_state_id_district_id_broadcast_date_idx ON public.news_all_2026_07 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2026_07_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_07_tags_idx ON public.news_all_2026_07 USING gin (tags);


--
-- Name: news_all_2026_07_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_07_to_tsvector_idx ON public.news_all_2026_07 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2026_08_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_08_broadcast_date_idx ON public.news_all_2026_08 USING brin (broadcast_date);


--
-- Name: news_all_2026_08_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_08_category_sentiment_idx ON public.news_all_2026_08 USING btree (category, sentiment);


--
-- Name: news_all_2026_08_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_08_entities_idx ON public.news_all_2026_08 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2026_08_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_08_financial_industries_idx ON public.news_all_2026_08 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2026_08_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_08_state_id_district_id_broadcast_date_idx ON public.news_all_2026_08 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2026_08_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_08_tags_idx ON public.news_all_2026_08 USING gin (tags);


--
-- Name: news_all_2026_08_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_08_to_tsvector_idx ON public.news_all_2026_08 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2026_09_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_09_broadcast_date_idx ON public.news_all_2026_09 USING brin (broadcast_date);


--
-- Name: news_all_2026_09_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_09_category_sentiment_idx ON public.news_all_2026_09 USING btree (category, sentiment);


--
-- Name: news_all_2026_09_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_09_entities_idx ON public.news_all_2026_09 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2026_09_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_09_financial_industries_idx ON public.news_all_2026_09 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2026_09_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_09_state_id_district_id_broadcast_date_idx ON public.news_all_2026_09 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2026_09_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_09_tags_idx ON public.news_all_2026_09 USING gin (tags);


--
-- Name: news_all_2026_09_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_09_to_tsvector_idx ON public.news_all_2026_09 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2026_10_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_10_broadcast_date_idx ON public.news_all_2026_10 USING brin (broadcast_date);


--
-- Name: news_all_2026_10_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_10_category_sentiment_idx ON public.news_all_2026_10 USING btree (category, sentiment);


--
-- Name: news_all_2026_10_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_10_entities_idx ON public.news_all_2026_10 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2026_10_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_10_financial_industries_idx ON public.news_all_2026_10 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2026_10_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_10_state_id_district_id_broadcast_date_idx ON public.news_all_2026_10 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2026_10_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_10_tags_idx ON public.news_all_2026_10 USING gin (tags);


--
-- Name: news_all_2026_10_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_10_to_tsvector_idx ON public.news_all_2026_10 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2026_11_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_11_broadcast_date_idx ON public.news_all_2026_11 USING brin (broadcast_date);


--
-- Name: news_all_2026_11_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_11_category_sentiment_idx ON public.news_all_2026_11 USING btree (category, sentiment);


--
-- Name: news_all_2026_11_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_11_entities_idx ON public.news_all_2026_11 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2026_11_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_11_financial_industries_idx ON public.news_all_2026_11 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2026_11_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_11_state_id_district_id_broadcast_date_idx ON public.news_all_2026_11 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2026_11_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_11_tags_idx ON public.news_all_2026_11 USING gin (tags);


--
-- Name: news_all_2026_11_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_11_to_tsvector_idx ON public.news_all_2026_11 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2026_12_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_12_broadcast_date_idx ON public.news_all_2026_12 USING brin (broadcast_date);


--
-- Name: news_all_2026_12_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_12_category_sentiment_idx ON public.news_all_2026_12 USING btree (category, sentiment);


--
-- Name: news_all_2026_12_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_12_entities_idx ON public.news_all_2026_12 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2026_12_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_12_financial_industries_idx ON public.news_all_2026_12 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2026_12_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_12_state_id_district_id_broadcast_date_idx ON public.news_all_2026_12 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2026_12_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_12_tags_idx ON public.news_all_2026_12 USING gin (tags);


--
-- Name: news_all_2026_12_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2026_12_to_tsvector_idx ON public.news_all_2026_12 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2027_01_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_01_broadcast_date_idx ON public.news_all_2027_01 USING brin (broadcast_date);


--
-- Name: news_all_2027_01_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_01_category_sentiment_idx ON public.news_all_2027_01 USING btree (category, sentiment);


--
-- Name: news_all_2027_01_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_01_entities_idx ON public.news_all_2027_01 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2027_01_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_01_financial_industries_idx ON public.news_all_2027_01 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2027_01_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_01_state_id_district_id_broadcast_date_idx ON public.news_all_2027_01 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2027_01_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_01_tags_idx ON public.news_all_2027_01 USING gin (tags);


--
-- Name: news_all_2027_01_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_01_to_tsvector_idx ON public.news_all_2027_01 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2027_02_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_02_broadcast_date_idx ON public.news_all_2027_02 USING brin (broadcast_date);


--
-- Name: news_all_2027_02_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_02_category_sentiment_idx ON public.news_all_2027_02 USING btree (category, sentiment);


--
-- Name: news_all_2027_02_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_02_entities_idx ON public.news_all_2027_02 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2027_02_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_02_financial_industries_idx ON public.news_all_2027_02 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2027_02_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_02_state_id_district_id_broadcast_date_idx ON public.news_all_2027_02 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2027_02_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_02_tags_idx ON public.news_all_2027_02 USING gin (tags);


--
-- Name: news_all_2027_02_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_02_to_tsvector_idx ON public.news_all_2027_02 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2027_03_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_03_broadcast_date_idx ON public.news_all_2027_03 USING brin (broadcast_date);


--
-- Name: news_all_2027_03_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_03_category_sentiment_idx ON public.news_all_2027_03 USING btree (category, sentiment);


--
-- Name: news_all_2027_03_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_03_entities_idx ON public.news_all_2027_03 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2027_03_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_03_financial_industries_idx ON public.news_all_2027_03 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2027_03_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_03_state_id_district_id_broadcast_date_idx ON public.news_all_2027_03 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2027_03_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_03_tags_idx ON public.news_all_2027_03 USING gin (tags);


--
-- Name: news_all_2027_03_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_03_to_tsvector_idx ON public.news_all_2027_03 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2027_04_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_04_broadcast_date_idx ON public.news_all_2027_04 USING brin (broadcast_date);


--
-- Name: news_all_2027_04_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_04_category_sentiment_idx ON public.news_all_2027_04 USING btree (category, sentiment);


--
-- Name: news_all_2027_04_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_04_entities_idx ON public.news_all_2027_04 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2027_04_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_04_financial_industries_idx ON public.news_all_2027_04 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2027_04_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_04_state_id_district_id_broadcast_date_idx ON public.news_all_2027_04 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2027_04_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_04_tags_idx ON public.news_all_2027_04 USING gin (tags);


--
-- Name: news_all_2027_04_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_04_to_tsvector_idx ON public.news_all_2027_04 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2027_05_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_05_broadcast_date_idx ON public.news_all_2027_05 USING brin (broadcast_date);


--
-- Name: news_all_2027_05_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_05_category_sentiment_idx ON public.news_all_2027_05 USING btree (category, sentiment);


--
-- Name: news_all_2027_05_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_05_entities_idx ON public.news_all_2027_05 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2027_05_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_05_financial_industries_idx ON public.news_all_2027_05 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2027_05_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_05_state_id_district_id_broadcast_date_idx ON public.news_all_2027_05 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2027_05_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_05_tags_idx ON public.news_all_2027_05 USING gin (tags);


--
-- Name: news_all_2027_05_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_05_to_tsvector_idx ON public.news_all_2027_05 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2027_06_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_06_broadcast_date_idx ON public.news_all_2027_06 USING brin (broadcast_date);


--
-- Name: news_all_2027_06_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_06_category_sentiment_idx ON public.news_all_2027_06 USING btree (category, sentiment);


--
-- Name: news_all_2027_06_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_06_entities_idx ON public.news_all_2027_06 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2027_06_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_06_financial_industries_idx ON public.news_all_2027_06 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2027_06_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_06_state_id_district_id_broadcast_date_idx ON public.news_all_2027_06 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2027_06_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_06_tags_idx ON public.news_all_2027_06 USING gin (tags);


--
-- Name: news_all_2027_06_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_06_to_tsvector_idx ON public.news_all_2027_06 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2027_07_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_07_broadcast_date_idx ON public.news_all_2027_07 USING brin (broadcast_date);


--
-- Name: news_all_2027_07_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_07_category_sentiment_idx ON public.news_all_2027_07 USING btree (category, sentiment);


--
-- Name: news_all_2027_07_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_07_entities_idx ON public.news_all_2027_07 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2027_07_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_07_financial_industries_idx ON public.news_all_2027_07 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2027_07_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_07_state_id_district_id_broadcast_date_idx ON public.news_all_2027_07 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2027_07_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_07_tags_idx ON public.news_all_2027_07 USING gin (tags);


--
-- Name: news_all_2027_07_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_07_to_tsvector_idx ON public.news_all_2027_07 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2027_08_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_08_broadcast_date_idx ON public.news_all_2027_08 USING brin (broadcast_date);


--
-- Name: news_all_2027_08_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_08_category_sentiment_idx ON public.news_all_2027_08 USING btree (category, sentiment);


--
-- Name: news_all_2027_08_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_08_entities_idx ON public.news_all_2027_08 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2027_08_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_08_financial_industries_idx ON public.news_all_2027_08 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2027_08_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_08_state_id_district_id_broadcast_date_idx ON public.news_all_2027_08 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2027_08_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_08_tags_idx ON public.news_all_2027_08 USING gin (tags);


--
-- Name: news_all_2027_08_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_08_to_tsvector_idx ON public.news_all_2027_08 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2027_09_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_09_broadcast_date_idx ON public.news_all_2027_09 USING brin (broadcast_date);


--
-- Name: news_all_2027_09_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_09_category_sentiment_idx ON public.news_all_2027_09 USING btree (category, sentiment);


--
-- Name: news_all_2027_09_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_09_entities_idx ON public.news_all_2027_09 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2027_09_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_09_financial_industries_idx ON public.news_all_2027_09 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2027_09_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_09_state_id_district_id_broadcast_date_idx ON public.news_all_2027_09 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2027_09_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_09_tags_idx ON public.news_all_2027_09 USING gin (tags);


--
-- Name: news_all_2027_09_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_09_to_tsvector_idx ON public.news_all_2027_09 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2027_10_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_10_broadcast_date_idx ON public.news_all_2027_10 USING brin (broadcast_date);


--
-- Name: news_all_2027_10_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_10_category_sentiment_idx ON public.news_all_2027_10 USING btree (category, sentiment);


--
-- Name: news_all_2027_10_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_10_entities_idx ON public.news_all_2027_10 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2027_10_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_10_financial_industries_idx ON public.news_all_2027_10 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2027_10_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_10_state_id_district_id_broadcast_date_idx ON public.news_all_2027_10 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2027_10_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_10_tags_idx ON public.news_all_2027_10 USING gin (tags);


--
-- Name: news_all_2027_10_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_10_to_tsvector_idx ON public.news_all_2027_10 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2027_11_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_11_broadcast_date_idx ON public.news_all_2027_11 USING brin (broadcast_date);


--
-- Name: news_all_2027_11_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_11_category_sentiment_idx ON public.news_all_2027_11 USING btree (category, sentiment);


--
-- Name: news_all_2027_11_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_11_entities_idx ON public.news_all_2027_11 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2027_11_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_11_financial_industries_idx ON public.news_all_2027_11 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2027_11_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_11_state_id_district_id_broadcast_date_idx ON public.news_all_2027_11 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2027_11_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_11_tags_idx ON public.news_all_2027_11 USING gin (tags);


--
-- Name: news_all_2027_11_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_11_to_tsvector_idx ON public.news_all_2027_11 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2027_12_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_12_broadcast_date_idx ON public.news_all_2027_12 USING brin (broadcast_date);


--
-- Name: news_all_2027_12_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_12_category_sentiment_idx ON public.news_all_2027_12 USING btree (category, sentiment);


--
-- Name: news_all_2027_12_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_12_entities_idx ON public.news_all_2027_12 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2027_12_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_12_financial_industries_idx ON public.news_all_2027_12 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2027_12_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_12_state_id_district_id_broadcast_date_idx ON public.news_all_2027_12 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2027_12_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_12_tags_idx ON public.news_all_2027_12 USING gin (tags);


--
-- Name: news_all_2027_12_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2027_12_to_tsvector_idx ON public.news_all_2027_12 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2028_01_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_01_broadcast_date_idx ON public.news_all_2028_01 USING brin (broadcast_date);


--
-- Name: news_all_2028_01_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_01_category_sentiment_idx ON public.news_all_2028_01 USING btree (category, sentiment);


--
-- Name: news_all_2028_01_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_01_entities_idx ON public.news_all_2028_01 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2028_01_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_01_financial_industries_idx ON public.news_all_2028_01 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2028_01_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_01_state_id_district_id_broadcast_date_idx ON public.news_all_2028_01 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2028_01_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_01_tags_idx ON public.news_all_2028_01 USING gin (tags);


--
-- Name: news_all_2028_01_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_01_to_tsvector_idx ON public.news_all_2028_01 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2028_02_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_02_broadcast_date_idx ON public.news_all_2028_02 USING brin (broadcast_date);


--
-- Name: news_all_2028_02_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_02_category_sentiment_idx ON public.news_all_2028_02 USING btree (category, sentiment);


--
-- Name: news_all_2028_02_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_02_entities_idx ON public.news_all_2028_02 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2028_02_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_02_financial_industries_idx ON public.news_all_2028_02 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2028_02_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_02_state_id_district_id_broadcast_date_idx ON public.news_all_2028_02 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2028_02_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_02_tags_idx ON public.news_all_2028_02 USING gin (tags);


--
-- Name: news_all_2028_02_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_02_to_tsvector_idx ON public.news_all_2028_02 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2028_03_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_03_broadcast_date_idx ON public.news_all_2028_03 USING brin (broadcast_date);


--
-- Name: news_all_2028_03_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_03_category_sentiment_idx ON public.news_all_2028_03 USING btree (category, sentiment);


--
-- Name: news_all_2028_03_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_03_entities_idx ON public.news_all_2028_03 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2028_03_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_03_financial_industries_idx ON public.news_all_2028_03 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2028_03_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_03_state_id_district_id_broadcast_date_idx ON public.news_all_2028_03 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2028_03_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_03_tags_idx ON public.news_all_2028_03 USING gin (tags);


--
-- Name: news_all_2028_03_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_03_to_tsvector_idx ON public.news_all_2028_03 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2028_04_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_04_broadcast_date_idx ON public.news_all_2028_04 USING brin (broadcast_date);


--
-- Name: news_all_2028_04_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_04_category_sentiment_idx ON public.news_all_2028_04 USING btree (category, sentiment);


--
-- Name: news_all_2028_04_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_04_entities_idx ON public.news_all_2028_04 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2028_04_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_04_financial_industries_idx ON public.news_all_2028_04 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2028_04_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_04_state_id_district_id_broadcast_date_idx ON public.news_all_2028_04 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2028_04_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_04_tags_idx ON public.news_all_2028_04 USING gin (tags);


--
-- Name: news_all_2028_04_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_04_to_tsvector_idx ON public.news_all_2028_04 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2028_05_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_05_broadcast_date_idx ON public.news_all_2028_05 USING brin (broadcast_date);


--
-- Name: news_all_2028_05_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_05_category_sentiment_idx ON public.news_all_2028_05 USING btree (category, sentiment);


--
-- Name: news_all_2028_05_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_05_entities_idx ON public.news_all_2028_05 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2028_05_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_05_financial_industries_idx ON public.news_all_2028_05 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2028_05_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_05_state_id_district_id_broadcast_date_idx ON public.news_all_2028_05 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2028_05_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_05_tags_idx ON public.news_all_2028_05 USING gin (tags);


--
-- Name: news_all_2028_05_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_05_to_tsvector_idx ON public.news_all_2028_05 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2028_06_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_06_broadcast_date_idx ON public.news_all_2028_06 USING brin (broadcast_date);


--
-- Name: news_all_2028_06_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_06_category_sentiment_idx ON public.news_all_2028_06 USING btree (category, sentiment);


--
-- Name: news_all_2028_06_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_06_entities_idx ON public.news_all_2028_06 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2028_06_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_06_financial_industries_idx ON public.news_all_2028_06 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2028_06_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_06_state_id_district_id_broadcast_date_idx ON public.news_all_2028_06 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2028_06_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_06_tags_idx ON public.news_all_2028_06 USING gin (tags);


--
-- Name: news_all_2028_06_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_06_to_tsvector_idx ON public.news_all_2028_06 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2028_07_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_07_broadcast_date_idx ON public.news_all_2028_07 USING brin (broadcast_date);


--
-- Name: news_all_2028_07_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_07_category_sentiment_idx ON public.news_all_2028_07 USING btree (category, sentiment);


--
-- Name: news_all_2028_07_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_07_entities_idx ON public.news_all_2028_07 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2028_07_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_07_financial_industries_idx ON public.news_all_2028_07 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2028_07_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_07_state_id_district_id_broadcast_date_idx ON public.news_all_2028_07 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2028_07_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_07_tags_idx ON public.news_all_2028_07 USING gin (tags);


--
-- Name: news_all_2028_07_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_07_to_tsvector_idx ON public.news_all_2028_07 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2028_08_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_08_broadcast_date_idx ON public.news_all_2028_08 USING brin (broadcast_date);


--
-- Name: news_all_2028_08_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_08_category_sentiment_idx ON public.news_all_2028_08 USING btree (category, sentiment);


--
-- Name: news_all_2028_08_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_08_entities_idx ON public.news_all_2028_08 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2028_08_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_08_financial_industries_idx ON public.news_all_2028_08 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2028_08_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_08_state_id_district_id_broadcast_date_idx ON public.news_all_2028_08 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2028_08_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_08_tags_idx ON public.news_all_2028_08 USING gin (tags);


--
-- Name: news_all_2028_08_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_08_to_tsvector_idx ON public.news_all_2028_08 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2028_09_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_09_broadcast_date_idx ON public.news_all_2028_09 USING brin (broadcast_date);


--
-- Name: news_all_2028_09_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_09_category_sentiment_idx ON public.news_all_2028_09 USING btree (category, sentiment);


--
-- Name: news_all_2028_09_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_09_entities_idx ON public.news_all_2028_09 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2028_09_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_09_financial_industries_idx ON public.news_all_2028_09 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2028_09_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_09_state_id_district_id_broadcast_date_idx ON public.news_all_2028_09 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2028_09_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_09_tags_idx ON public.news_all_2028_09 USING gin (tags);


--
-- Name: news_all_2028_09_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_09_to_tsvector_idx ON public.news_all_2028_09 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2028_10_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_10_broadcast_date_idx ON public.news_all_2028_10 USING brin (broadcast_date);


--
-- Name: news_all_2028_10_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_10_category_sentiment_idx ON public.news_all_2028_10 USING btree (category, sentiment);


--
-- Name: news_all_2028_10_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_10_entities_idx ON public.news_all_2028_10 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2028_10_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_10_financial_industries_idx ON public.news_all_2028_10 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2028_10_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_10_state_id_district_id_broadcast_date_idx ON public.news_all_2028_10 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2028_10_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_10_tags_idx ON public.news_all_2028_10 USING gin (tags);


--
-- Name: news_all_2028_10_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_10_to_tsvector_idx ON public.news_all_2028_10 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2028_11_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_11_broadcast_date_idx ON public.news_all_2028_11 USING brin (broadcast_date);


--
-- Name: news_all_2028_11_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_11_category_sentiment_idx ON public.news_all_2028_11 USING btree (category, sentiment);


--
-- Name: news_all_2028_11_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_11_entities_idx ON public.news_all_2028_11 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2028_11_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_11_financial_industries_idx ON public.news_all_2028_11 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2028_11_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_11_state_id_district_id_broadcast_date_idx ON public.news_all_2028_11 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2028_11_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_11_tags_idx ON public.news_all_2028_11 USING gin (tags);


--
-- Name: news_all_2028_11_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_11_to_tsvector_idx ON public.news_all_2028_11 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2028_12_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_12_broadcast_date_idx ON public.news_all_2028_12 USING brin (broadcast_date);


--
-- Name: news_all_2028_12_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_12_category_sentiment_idx ON public.news_all_2028_12 USING btree (category, sentiment);


--
-- Name: news_all_2028_12_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_12_entities_idx ON public.news_all_2028_12 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2028_12_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_12_financial_industries_idx ON public.news_all_2028_12 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2028_12_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_12_state_id_district_id_broadcast_date_idx ON public.news_all_2028_12 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2028_12_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_12_tags_idx ON public.news_all_2028_12 USING gin (tags);


--
-- Name: news_all_2028_12_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2028_12_to_tsvector_idx ON public.news_all_2028_12 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2029_01_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_01_broadcast_date_idx ON public.news_all_2029_01 USING brin (broadcast_date);


--
-- Name: news_all_2029_01_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_01_category_sentiment_idx ON public.news_all_2029_01 USING btree (category, sentiment);


--
-- Name: news_all_2029_01_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_01_entities_idx ON public.news_all_2029_01 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2029_01_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_01_financial_industries_idx ON public.news_all_2029_01 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2029_01_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_01_state_id_district_id_broadcast_date_idx ON public.news_all_2029_01 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2029_01_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_01_tags_idx ON public.news_all_2029_01 USING gin (tags);


--
-- Name: news_all_2029_01_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_01_to_tsvector_idx ON public.news_all_2029_01 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2029_02_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_02_broadcast_date_idx ON public.news_all_2029_02 USING brin (broadcast_date);


--
-- Name: news_all_2029_02_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_02_category_sentiment_idx ON public.news_all_2029_02 USING btree (category, sentiment);


--
-- Name: news_all_2029_02_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_02_entities_idx ON public.news_all_2029_02 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2029_02_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_02_financial_industries_idx ON public.news_all_2029_02 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2029_02_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_02_state_id_district_id_broadcast_date_idx ON public.news_all_2029_02 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2029_02_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_02_tags_idx ON public.news_all_2029_02 USING gin (tags);


--
-- Name: news_all_2029_02_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_02_to_tsvector_idx ON public.news_all_2029_02 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2029_03_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_03_broadcast_date_idx ON public.news_all_2029_03 USING brin (broadcast_date);


--
-- Name: news_all_2029_03_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_03_category_sentiment_idx ON public.news_all_2029_03 USING btree (category, sentiment);


--
-- Name: news_all_2029_03_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_03_entities_idx ON public.news_all_2029_03 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2029_03_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_03_financial_industries_idx ON public.news_all_2029_03 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2029_03_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_03_state_id_district_id_broadcast_date_idx ON public.news_all_2029_03 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2029_03_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_03_tags_idx ON public.news_all_2029_03 USING gin (tags);


--
-- Name: news_all_2029_03_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_03_to_tsvector_idx ON public.news_all_2029_03 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2029_04_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_04_broadcast_date_idx ON public.news_all_2029_04 USING brin (broadcast_date);


--
-- Name: news_all_2029_04_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_04_category_sentiment_idx ON public.news_all_2029_04 USING btree (category, sentiment);


--
-- Name: news_all_2029_04_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_04_entities_idx ON public.news_all_2029_04 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2029_04_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_04_financial_industries_idx ON public.news_all_2029_04 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2029_04_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_04_state_id_district_id_broadcast_date_idx ON public.news_all_2029_04 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2029_04_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_04_tags_idx ON public.news_all_2029_04 USING gin (tags);


--
-- Name: news_all_2029_04_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_04_to_tsvector_idx ON public.news_all_2029_04 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2029_05_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_05_broadcast_date_idx ON public.news_all_2029_05 USING brin (broadcast_date);


--
-- Name: news_all_2029_05_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_05_category_sentiment_idx ON public.news_all_2029_05 USING btree (category, sentiment);


--
-- Name: news_all_2029_05_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_05_entities_idx ON public.news_all_2029_05 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2029_05_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_05_financial_industries_idx ON public.news_all_2029_05 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2029_05_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_05_state_id_district_id_broadcast_date_idx ON public.news_all_2029_05 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2029_05_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_05_tags_idx ON public.news_all_2029_05 USING gin (tags);


--
-- Name: news_all_2029_05_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_05_to_tsvector_idx ON public.news_all_2029_05 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2029_06_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_06_broadcast_date_idx ON public.news_all_2029_06 USING brin (broadcast_date);


--
-- Name: news_all_2029_06_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_06_category_sentiment_idx ON public.news_all_2029_06 USING btree (category, sentiment);


--
-- Name: news_all_2029_06_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_06_entities_idx ON public.news_all_2029_06 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2029_06_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_06_financial_industries_idx ON public.news_all_2029_06 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2029_06_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_06_state_id_district_id_broadcast_date_idx ON public.news_all_2029_06 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2029_06_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_06_tags_idx ON public.news_all_2029_06 USING gin (tags);


--
-- Name: news_all_2029_06_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_06_to_tsvector_idx ON public.news_all_2029_06 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2029_07_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_07_broadcast_date_idx ON public.news_all_2029_07 USING brin (broadcast_date);


--
-- Name: news_all_2029_07_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_07_category_sentiment_idx ON public.news_all_2029_07 USING btree (category, sentiment);


--
-- Name: news_all_2029_07_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_07_entities_idx ON public.news_all_2029_07 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2029_07_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_07_financial_industries_idx ON public.news_all_2029_07 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2029_07_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_07_state_id_district_id_broadcast_date_idx ON public.news_all_2029_07 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2029_07_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_07_tags_idx ON public.news_all_2029_07 USING gin (tags);


--
-- Name: news_all_2029_07_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_07_to_tsvector_idx ON public.news_all_2029_07 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2029_08_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_08_broadcast_date_idx ON public.news_all_2029_08 USING brin (broadcast_date);


--
-- Name: news_all_2029_08_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_08_category_sentiment_idx ON public.news_all_2029_08 USING btree (category, sentiment);


--
-- Name: news_all_2029_08_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_08_entities_idx ON public.news_all_2029_08 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2029_08_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_08_financial_industries_idx ON public.news_all_2029_08 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2029_08_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_08_state_id_district_id_broadcast_date_idx ON public.news_all_2029_08 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2029_08_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_08_tags_idx ON public.news_all_2029_08 USING gin (tags);


--
-- Name: news_all_2029_08_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_08_to_tsvector_idx ON public.news_all_2029_08 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2029_09_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_09_broadcast_date_idx ON public.news_all_2029_09 USING brin (broadcast_date);


--
-- Name: news_all_2029_09_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_09_category_sentiment_idx ON public.news_all_2029_09 USING btree (category, sentiment);


--
-- Name: news_all_2029_09_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_09_entities_idx ON public.news_all_2029_09 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2029_09_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_09_financial_industries_idx ON public.news_all_2029_09 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2029_09_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_09_state_id_district_id_broadcast_date_idx ON public.news_all_2029_09 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2029_09_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_09_tags_idx ON public.news_all_2029_09 USING gin (tags);


--
-- Name: news_all_2029_09_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_09_to_tsvector_idx ON public.news_all_2029_09 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2029_10_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_10_broadcast_date_idx ON public.news_all_2029_10 USING brin (broadcast_date);


--
-- Name: news_all_2029_10_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_10_category_sentiment_idx ON public.news_all_2029_10 USING btree (category, sentiment);


--
-- Name: news_all_2029_10_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_10_entities_idx ON public.news_all_2029_10 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2029_10_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_10_financial_industries_idx ON public.news_all_2029_10 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2029_10_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_10_state_id_district_id_broadcast_date_idx ON public.news_all_2029_10 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2029_10_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_10_tags_idx ON public.news_all_2029_10 USING gin (tags);


--
-- Name: news_all_2029_10_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_10_to_tsvector_idx ON public.news_all_2029_10 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2029_11_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_11_broadcast_date_idx ON public.news_all_2029_11 USING brin (broadcast_date);


--
-- Name: news_all_2029_11_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_11_category_sentiment_idx ON public.news_all_2029_11 USING btree (category, sentiment);


--
-- Name: news_all_2029_11_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_11_entities_idx ON public.news_all_2029_11 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2029_11_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_11_financial_industries_idx ON public.news_all_2029_11 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2029_11_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_11_state_id_district_id_broadcast_date_idx ON public.news_all_2029_11 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2029_11_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_11_tags_idx ON public.news_all_2029_11 USING gin (tags);


--
-- Name: news_all_2029_11_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_11_to_tsvector_idx ON public.news_all_2029_11 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2029_12_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_12_broadcast_date_idx ON public.news_all_2029_12 USING brin (broadcast_date);


--
-- Name: news_all_2029_12_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_12_category_sentiment_idx ON public.news_all_2029_12 USING btree (category, sentiment);


--
-- Name: news_all_2029_12_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_12_entities_idx ON public.news_all_2029_12 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2029_12_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_12_financial_industries_idx ON public.news_all_2029_12 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2029_12_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_12_state_id_district_id_broadcast_date_idx ON public.news_all_2029_12 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2029_12_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_12_tags_idx ON public.news_all_2029_12 USING gin (tags);


--
-- Name: news_all_2029_12_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2029_12_to_tsvector_idx ON public.news_all_2029_12 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2030_01_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_01_broadcast_date_idx ON public.news_all_2030_01 USING brin (broadcast_date);


--
-- Name: news_all_2030_01_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_01_category_sentiment_idx ON public.news_all_2030_01 USING btree (category, sentiment);


--
-- Name: news_all_2030_01_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_01_entities_idx ON public.news_all_2030_01 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2030_01_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_01_financial_industries_idx ON public.news_all_2030_01 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2030_01_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_01_state_id_district_id_broadcast_date_idx ON public.news_all_2030_01 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2030_01_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_01_tags_idx ON public.news_all_2030_01 USING gin (tags);


--
-- Name: news_all_2030_01_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_01_to_tsvector_idx ON public.news_all_2030_01 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2030_02_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_02_broadcast_date_idx ON public.news_all_2030_02 USING brin (broadcast_date);


--
-- Name: news_all_2030_02_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_02_category_sentiment_idx ON public.news_all_2030_02 USING btree (category, sentiment);


--
-- Name: news_all_2030_02_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_02_entities_idx ON public.news_all_2030_02 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2030_02_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_02_financial_industries_idx ON public.news_all_2030_02 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2030_02_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_02_state_id_district_id_broadcast_date_idx ON public.news_all_2030_02 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2030_02_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_02_tags_idx ON public.news_all_2030_02 USING gin (tags);


--
-- Name: news_all_2030_02_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_02_to_tsvector_idx ON public.news_all_2030_02 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2030_03_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_03_broadcast_date_idx ON public.news_all_2030_03 USING brin (broadcast_date);


--
-- Name: news_all_2030_03_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_03_category_sentiment_idx ON public.news_all_2030_03 USING btree (category, sentiment);


--
-- Name: news_all_2030_03_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_03_entities_idx ON public.news_all_2030_03 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2030_03_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_03_financial_industries_idx ON public.news_all_2030_03 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2030_03_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_03_state_id_district_id_broadcast_date_idx ON public.news_all_2030_03 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2030_03_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_03_tags_idx ON public.news_all_2030_03 USING gin (tags);


--
-- Name: news_all_2030_03_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_03_to_tsvector_idx ON public.news_all_2030_03 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2030_04_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_04_broadcast_date_idx ON public.news_all_2030_04 USING brin (broadcast_date);


--
-- Name: news_all_2030_04_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_04_category_sentiment_idx ON public.news_all_2030_04 USING btree (category, sentiment);


--
-- Name: news_all_2030_04_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_04_entities_idx ON public.news_all_2030_04 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2030_04_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_04_financial_industries_idx ON public.news_all_2030_04 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2030_04_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_04_state_id_district_id_broadcast_date_idx ON public.news_all_2030_04 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2030_04_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_04_tags_idx ON public.news_all_2030_04 USING gin (tags);


--
-- Name: news_all_2030_04_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_04_to_tsvector_idx ON public.news_all_2030_04 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2030_05_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_05_broadcast_date_idx ON public.news_all_2030_05 USING brin (broadcast_date);


--
-- Name: news_all_2030_05_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_05_category_sentiment_idx ON public.news_all_2030_05 USING btree (category, sentiment);


--
-- Name: news_all_2030_05_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_05_entities_idx ON public.news_all_2030_05 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2030_05_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_05_financial_industries_idx ON public.news_all_2030_05 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2030_05_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_05_state_id_district_id_broadcast_date_idx ON public.news_all_2030_05 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2030_05_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_05_tags_idx ON public.news_all_2030_05 USING gin (tags);


--
-- Name: news_all_2030_05_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_05_to_tsvector_idx ON public.news_all_2030_05 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2030_06_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_06_broadcast_date_idx ON public.news_all_2030_06 USING brin (broadcast_date);


--
-- Name: news_all_2030_06_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_06_category_sentiment_idx ON public.news_all_2030_06 USING btree (category, sentiment);


--
-- Name: news_all_2030_06_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_06_entities_idx ON public.news_all_2030_06 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2030_06_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_06_financial_industries_idx ON public.news_all_2030_06 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2030_06_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_06_state_id_district_id_broadcast_date_idx ON public.news_all_2030_06 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2030_06_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_06_tags_idx ON public.news_all_2030_06 USING gin (tags);


--
-- Name: news_all_2030_06_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_06_to_tsvector_idx ON public.news_all_2030_06 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2030_07_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_07_broadcast_date_idx ON public.news_all_2030_07 USING brin (broadcast_date);


--
-- Name: news_all_2030_07_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_07_category_sentiment_idx ON public.news_all_2030_07 USING btree (category, sentiment);


--
-- Name: news_all_2030_07_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_07_entities_idx ON public.news_all_2030_07 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2030_07_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_07_financial_industries_idx ON public.news_all_2030_07 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2030_07_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_07_state_id_district_id_broadcast_date_idx ON public.news_all_2030_07 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2030_07_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_07_tags_idx ON public.news_all_2030_07 USING gin (tags);


--
-- Name: news_all_2030_07_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_07_to_tsvector_idx ON public.news_all_2030_07 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2030_08_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_08_broadcast_date_idx ON public.news_all_2030_08 USING brin (broadcast_date);


--
-- Name: news_all_2030_08_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_08_category_sentiment_idx ON public.news_all_2030_08 USING btree (category, sentiment);


--
-- Name: news_all_2030_08_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_08_entities_idx ON public.news_all_2030_08 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2030_08_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_08_financial_industries_idx ON public.news_all_2030_08 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2030_08_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_08_state_id_district_id_broadcast_date_idx ON public.news_all_2030_08 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2030_08_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_08_tags_idx ON public.news_all_2030_08 USING gin (tags);


--
-- Name: news_all_2030_08_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_08_to_tsvector_idx ON public.news_all_2030_08 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2030_09_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_09_broadcast_date_idx ON public.news_all_2030_09 USING brin (broadcast_date);


--
-- Name: news_all_2030_09_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_09_category_sentiment_idx ON public.news_all_2030_09 USING btree (category, sentiment);


--
-- Name: news_all_2030_09_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_09_entities_idx ON public.news_all_2030_09 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2030_09_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_09_financial_industries_idx ON public.news_all_2030_09 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2030_09_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_09_state_id_district_id_broadcast_date_idx ON public.news_all_2030_09 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2030_09_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_09_tags_idx ON public.news_all_2030_09 USING gin (tags);


--
-- Name: news_all_2030_09_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_09_to_tsvector_idx ON public.news_all_2030_09 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2030_10_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_10_broadcast_date_idx ON public.news_all_2030_10 USING brin (broadcast_date);


--
-- Name: news_all_2030_10_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_10_category_sentiment_idx ON public.news_all_2030_10 USING btree (category, sentiment);


--
-- Name: news_all_2030_10_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_10_entities_idx ON public.news_all_2030_10 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2030_10_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_10_financial_industries_idx ON public.news_all_2030_10 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2030_10_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_10_state_id_district_id_broadcast_date_idx ON public.news_all_2030_10 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2030_10_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_10_tags_idx ON public.news_all_2030_10 USING gin (tags);


--
-- Name: news_all_2030_10_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_10_to_tsvector_idx ON public.news_all_2030_10 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2030_11_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_11_broadcast_date_idx ON public.news_all_2030_11 USING brin (broadcast_date);


--
-- Name: news_all_2030_11_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_11_category_sentiment_idx ON public.news_all_2030_11 USING btree (category, sentiment);


--
-- Name: news_all_2030_11_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_11_entities_idx ON public.news_all_2030_11 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2030_11_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_11_financial_industries_idx ON public.news_all_2030_11 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2030_11_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_11_state_id_district_id_broadcast_date_idx ON public.news_all_2030_11 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2030_11_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_11_tags_idx ON public.news_all_2030_11 USING gin (tags);


--
-- Name: news_all_2030_11_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_11_to_tsvector_idx ON public.news_all_2030_11 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2030_12_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_12_broadcast_date_idx ON public.news_all_2030_12 USING brin (broadcast_date);


--
-- Name: news_all_2030_12_category_sentiment_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_12_category_sentiment_idx ON public.news_all_2030_12 USING btree (category, sentiment);


--
-- Name: news_all_2030_12_entities_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_12_entities_idx ON public.news_all_2030_12 USING gin (entities) WHERE (entities <> '{}'::jsonb);


--
-- Name: news_all_2030_12_financial_industries_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_12_financial_industries_idx ON public.news_all_2030_12 USING gin (financial_industries jsonb_path_ops);


--
-- Name: news_all_2030_12_state_id_district_id_broadcast_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_12_state_id_district_id_broadcast_date_idx ON public.news_all_2030_12 USING btree (state_id, district_id, broadcast_date);


--
-- Name: news_all_2030_12_tags_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_12_tags_idx ON public.news_all_2030_12 USING gin (tags);


--
-- Name: news_all_2030_12_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_all_2030_12_to_tsvector_idx ON public.news_all_2030_12 USING gin (to_tsvector('english'::regconfig, headline));


--
-- Name: news_all_2026_04_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2026_04_broadcast_date_idx;


--
-- Name: news_all_2026_04_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2026_04_category_sentiment_idx;


--
-- Name: news_all_2026_04_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2026_04_entities_idx;


--
-- Name: news_all_2026_04_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2026_04_financial_industries_idx;


--
-- Name: news_all_2026_04_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2026_04_pkey;


--
-- Name: news_all_2026_04_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2026_04_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2026_04_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2026_04_tags_idx;


--
-- Name: news_all_2026_04_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2026_04_to_tsvector_idx;


--
-- Name: news_all_2026_05_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2026_05_broadcast_date_idx;


--
-- Name: news_all_2026_05_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2026_05_category_sentiment_idx;


--
-- Name: news_all_2026_05_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2026_05_entities_idx;


--
-- Name: news_all_2026_05_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2026_05_financial_industries_idx;


--
-- Name: news_all_2026_05_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2026_05_pkey;


--
-- Name: news_all_2026_05_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2026_05_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2026_05_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2026_05_tags_idx;


--
-- Name: news_all_2026_05_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2026_05_to_tsvector_idx;


--
-- Name: news_all_2026_06_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2026_06_broadcast_date_idx;


--
-- Name: news_all_2026_06_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2026_06_category_sentiment_idx;


--
-- Name: news_all_2026_06_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2026_06_entities_idx;


--
-- Name: news_all_2026_06_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2026_06_financial_industries_idx;


--
-- Name: news_all_2026_06_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2026_06_pkey;


--
-- Name: news_all_2026_06_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2026_06_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2026_06_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2026_06_tags_idx;


--
-- Name: news_all_2026_06_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2026_06_to_tsvector_idx;


--
-- Name: news_all_2026_07_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2026_07_broadcast_date_idx;


--
-- Name: news_all_2026_07_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2026_07_category_sentiment_idx;


--
-- Name: news_all_2026_07_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2026_07_entities_idx;


--
-- Name: news_all_2026_07_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2026_07_financial_industries_idx;


--
-- Name: news_all_2026_07_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2026_07_pkey;


--
-- Name: news_all_2026_07_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2026_07_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2026_07_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2026_07_tags_idx;


--
-- Name: news_all_2026_07_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2026_07_to_tsvector_idx;


--
-- Name: news_all_2026_08_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2026_08_broadcast_date_idx;


--
-- Name: news_all_2026_08_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2026_08_category_sentiment_idx;


--
-- Name: news_all_2026_08_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2026_08_entities_idx;


--
-- Name: news_all_2026_08_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2026_08_financial_industries_idx;


--
-- Name: news_all_2026_08_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2026_08_pkey;


--
-- Name: news_all_2026_08_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2026_08_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2026_08_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2026_08_tags_idx;


--
-- Name: news_all_2026_08_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2026_08_to_tsvector_idx;


--
-- Name: news_all_2026_09_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2026_09_broadcast_date_idx;


--
-- Name: news_all_2026_09_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2026_09_category_sentiment_idx;


--
-- Name: news_all_2026_09_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2026_09_entities_idx;


--
-- Name: news_all_2026_09_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2026_09_financial_industries_idx;


--
-- Name: news_all_2026_09_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2026_09_pkey;


--
-- Name: news_all_2026_09_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2026_09_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2026_09_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2026_09_tags_idx;


--
-- Name: news_all_2026_09_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2026_09_to_tsvector_idx;


--
-- Name: news_all_2026_10_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2026_10_broadcast_date_idx;


--
-- Name: news_all_2026_10_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2026_10_category_sentiment_idx;


--
-- Name: news_all_2026_10_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2026_10_entities_idx;


--
-- Name: news_all_2026_10_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2026_10_financial_industries_idx;


--
-- Name: news_all_2026_10_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2026_10_pkey;


--
-- Name: news_all_2026_10_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2026_10_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2026_10_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2026_10_tags_idx;


--
-- Name: news_all_2026_10_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2026_10_to_tsvector_idx;


--
-- Name: news_all_2026_11_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2026_11_broadcast_date_idx;


--
-- Name: news_all_2026_11_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2026_11_category_sentiment_idx;


--
-- Name: news_all_2026_11_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2026_11_entities_idx;


--
-- Name: news_all_2026_11_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2026_11_financial_industries_idx;


--
-- Name: news_all_2026_11_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2026_11_pkey;


--
-- Name: news_all_2026_11_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2026_11_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2026_11_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2026_11_tags_idx;


--
-- Name: news_all_2026_11_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2026_11_to_tsvector_idx;


--
-- Name: news_all_2026_12_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2026_12_broadcast_date_idx;


--
-- Name: news_all_2026_12_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2026_12_category_sentiment_idx;


--
-- Name: news_all_2026_12_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2026_12_entities_idx;


--
-- Name: news_all_2026_12_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2026_12_financial_industries_idx;


--
-- Name: news_all_2026_12_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2026_12_pkey;


--
-- Name: news_all_2026_12_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2026_12_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2026_12_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2026_12_tags_idx;


--
-- Name: news_all_2026_12_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2026_12_to_tsvector_idx;


--
-- Name: news_all_2027_01_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2027_01_broadcast_date_idx;


--
-- Name: news_all_2027_01_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2027_01_category_sentiment_idx;


--
-- Name: news_all_2027_01_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2027_01_entities_idx;


--
-- Name: news_all_2027_01_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2027_01_financial_industries_idx;


--
-- Name: news_all_2027_01_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2027_01_pkey;


--
-- Name: news_all_2027_01_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2027_01_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2027_01_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2027_01_tags_idx;


--
-- Name: news_all_2027_01_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2027_01_to_tsvector_idx;


--
-- Name: news_all_2027_02_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2027_02_broadcast_date_idx;


--
-- Name: news_all_2027_02_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2027_02_category_sentiment_idx;


--
-- Name: news_all_2027_02_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2027_02_entities_idx;


--
-- Name: news_all_2027_02_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2027_02_financial_industries_idx;


--
-- Name: news_all_2027_02_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2027_02_pkey;


--
-- Name: news_all_2027_02_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2027_02_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2027_02_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2027_02_tags_idx;


--
-- Name: news_all_2027_02_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2027_02_to_tsvector_idx;


--
-- Name: news_all_2027_03_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2027_03_broadcast_date_idx;


--
-- Name: news_all_2027_03_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2027_03_category_sentiment_idx;


--
-- Name: news_all_2027_03_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2027_03_entities_idx;


--
-- Name: news_all_2027_03_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2027_03_financial_industries_idx;


--
-- Name: news_all_2027_03_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2027_03_pkey;


--
-- Name: news_all_2027_03_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2027_03_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2027_03_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2027_03_tags_idx;


--
-- Name: news_all_2027_03_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2027_03_to_tsvector_idx;


--
-- Name: news_all_2027_04_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2027_04_broadcast_date_idx;


--
-- Name: news_all_2027_04_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2027_04_category_sentiment_idx;


--
-- Name: news_all_2027_04_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2027_04_entities_idx;


--
-- Name: news_all_2027_04_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2027_04_financial_industries_idx;


--
-- Name: news_all_2027_04_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2027_04_pkey;


--
-- Name: news_all_2027_04_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2027_04_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2027_04_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2027_04_tags_idx;


--
-- Name: news_all_2027_04_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2027_04_to_tsvector_idx;


--
-- Name: news_all_2027_05_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2027_05_broadcast_date_idx;


--
-- Name: news_all_2027_05_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2027_05_category_sentiment_idx;


--
-- Name: news_all_2027_05_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2027_05_entities_idx;


--
-- Name: news_all_2027_05_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2027_05_financial_industries_idx;


--
-- Name: news_all_2027_05_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2027_05_pkey;


--
-- Name: news_all_2027_05_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2027_05_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2027_05_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2027_05_tags_idx;


--
-- Name: news_all_2027_05_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2027_05_to_tsvector_idx;


--
-- Name: news_all_2027_06_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2027_06_broadcast_date_idx;


--
-- Name: news_all_2027_06_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2027_06_category_sentiment_idx;


--
-- Name: news_all_2027_06_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2027_06_entities_idx;


--
-- Name: news_all_2027_06_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2027_06_financial_industries_idx;


--
-- Name: news_all_2027_06_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2027_06_pkey;


--
-- Name: news_all_2027_06_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2027_06_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2027_06_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2027_06_tags_idx;


--
-- Name: news_all_2027_06_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2027_06_to_tsvector_idx;


--
-- Name: news_all_2027_07_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2027_07_broadcast_date_idx;


--
-- Name: news_all_2027_07_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2027_07_category_sentiment_idx;


--
-- Name: news_all_2027_07_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2027_07_entities_idx;


--
-- Name: news_all_2027_07_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2027_07_financial_industries_idx;


--
-- Name: news_all_2027_07_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2027_07_pkey;


--
-- Name: news_all_2027_07_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2027_07_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2027_07_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2027_07_tags_idx;


--
-- Name: news_all_2027_07_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2027_07_to_tsvector_idx;


--
-- Name: news_all_2027_08_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2027_08_broadcast_date_idx;


--
-- Name: news_all_2027_08_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2027_08_category_sentiment_idx;


--
-- Name: news_all_2027_08_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2027_08_entities_idx;


--
-- Name: news_all_2027_08_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2027_08_financial_industries_idx;


--
-- Name: news_all_2027_08_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2027_08_pkey;


--
-- Name: news_all_2027_08_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2027_08_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2027_08_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2027_08_tags_idx;


--
-- Name: news_all_2027_08_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2027_08_to_tsvector_idx;


--
-- Name: news_all_2027_09_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2027_09_broadcast_date_idx;


--
-- Name: news_all_2027_09_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2027_09_category_sentiment_idx;


--
-- Name: news_all_2027_09_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2027_09_entities_idx;


--
-- Name: news_all_2027_09_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2027_09_financial_industries_idx;


--
-- Name: news_all_2027_09_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2027_09_pkey;


--
-- Name: news_all_2027_09_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2027_09_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2027_09_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2027_09_tags_idx;


--
-- Name: news_all_2027_09_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2027_09_to_tsvector_idx;


--
-- Name: news_all_2027_10_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2027_10_broadcast_date_idx;


--
-- Name: news_all_2027_10_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2027_10_category_sentiment_idx;


--
-- Name: news_all_2027_10_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2027_10_entities_idx;


--
-- Name: news_all_2027_10_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2027_10_financial_industries_idx;


--
-- Name: news_all_2027_10_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2027_10_pkey;


--
-- Name: news_all_2027_10_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2027_10_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2027_10_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2027_10_tags_idx;


--
-- Name: news_all_2027_10_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2027_10_to_tsvector_idx;


--
-- Name: news_all_2027_11_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2027_11_broadcast_date_idx;


--
-- Name: news_all_2027_11_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2027_11_category_sentiment_idx;


--
-- Name: news_all_2027_11_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2027_11_entities_idx;


--
-- Name: news_all_2027_11_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2027_11_financial_industries_idx;


--
-- Name: news_all_2027_11_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2027_11_pkey;


--
-- Name: news_all_2027_11_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2027_11_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2027_11_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2027_11_tags_idx;


--
-- Name: news_all_2027_11_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2027_11_to_tsvector_idx;


--
-- Name: news_all_2027_12_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2027_12_broadcast_date_idx;


--
-- Name: news_all_2027_12_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2027_12_category_sentiment_idx;


--
-- Name: news_all_2027_12_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2027_12_entities_idx;


--
-- Name: news_all_2027_12_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2027_12_financial_industries_idx;


--
-- Name: news_all_2027_12_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2027_12_pkey;


--
-- Name: news_all_2027_12_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2027_12_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2027_12_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2027_12_tags_idx;


--
-- Name: news_all_2027_12_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2027_12_to_tsvector_idx;


--
-- Name: news_all_2028_01_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2028_01_broadcast_date_idx;


--
-- Name: news_all_2028_01_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2028_01_category_sentiment_idx;


--
-- Name: news_all_2028_01_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2028_01_entities_idx;


--
-- Name: news_all_2028_01_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2028_01_financial_industries_idx;


--
-- Name: news_all_2028_01_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2028_01_pkey;


--
-- Name: news_all_2028_01_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2028_01_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2028_01_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2028_01_tags_idx;


--
-- Name: news_all_2028_01_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2028_01_to_tsvector_idx;


--
-- Name: news_all_2028_02_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2028_02_broadcast_date_idx;


--
-- Name: news_all_2028_02_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2028_02_category_sentiment_idx;


--
-- Name: news_all_2028_02_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2028_02_entities_idx;


--
-- Name: news_all_2028_02_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2028_02_financial_industries_idx;


--
-- Name: news_all_2028_02_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2028_02_pkey;


--
-- Name: news_all_2028_02_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2028_02_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2028_02_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2028_02_tags_idx;


--
-- Name: news_all_2028_02_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2028_02_to_tsvector_idx;


--
-- Name: news_all_2028_03_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2028_03_broadcast_date_idx;


--
-- Name: news_all_2028_03_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2028_03_category_sentiment_idx;


--
-- Name: news_all_2028_03_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2028_03_entities_idx;


--
-- Name: news_all_2028_03_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2028_03_financial_industries_idx;


--
-- Name: news_all_2028_03_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2028_03_pkey;


--
-- Name: news_all_2028_03_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2028_03_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2028_03_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2028_03_tags_idx;


--
-- Name: news_all_2028_03_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2028_03_to_tsvector_idx;


--
-- Name: news_all_2028_04_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2028_04_broadcast_date_idx;


--
-- Name: news_all_2028_04_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2028_04_category_sentiment_idx;


--
-- Name: news_all_2028_04_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2028_04_entities_idx;


--
-- Name: news_all_2028_04_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2028_04_financial_industries_idx;


--
-- Name: news_all_2028_04_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2028_04_pkey;


--
-- Name: news_all_2028_04_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2028_04_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2028_04_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2028_04_tags_idx;


--
-- Name: news_all_2028_04_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2028_04_to_tsvector_idx;


--
-- Name: news_all_2028_05_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2028_05_broadcast_date_idx;


--
-- Name: news_all_2028_05_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2028_05_category_sentiment_idx;


--
-- Name: news_all_2028_05_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2028_05_entities_idx;


--
-- Name: news_all_2028_05_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2028_05_financial_industries_idx;


--
-- Name: news_all_2028_05_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2028_05_pkey;


--
-- Name: news_all_2028_05_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2028_05_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2028_05_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2028_05_tags_idx;


--
-- Name: news_all_2028_05_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2028_05_to_tsvector_idx;


--
-- Name: news_all_2028_06_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2028_06_broadcast_date_idx;


--
-- Name: news_all_2028_06_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2028_06_category_sentiment_idx;


--
-- Name: news_all_2028_06_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2028_06_entities_idx;


--
-- Name: news_all_2028_06_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2028_06_financial_industries_idx;


--
-- Name: news_all_2028_06_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2028_06_pkey;


--
-- Name: news_all_2028_06_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2028_06_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2028_06_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2028_06_tags_idx;


--
-- Name: news_all_2028_06_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2028_06_to_tsvector_idx;


--
-- Name: news_all_2028_07_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2028_07_broadcast_date_idx;


--
-- Name: news_all_2028_07_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2028_07_category_sentiment_idx;


--
-- Name: news_all_2028_07_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2028_07_entities_idx;


--
-- Name: news_all_2028_07_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2028_07_financial_industries_idx;


--
-- Name: news_all_2028_07_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2028_07_pkey;


--
-- Name: news_all_2028_07_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2028_07_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2028_07_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2028_07_tags_idx;


--
-- Name: news_all_2028_07_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2028_07_to_tsvector_idx;


--
-- Name: news_all_2028_08_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2028_08_broadcast_date_idx;


--
-- Name: news_all_2028_08_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2028_08_category_sentiment_idx;


--
-- Name: news_all_2028_08_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2028_08_entities_idx;


--
-- Name: news_all_2028_08_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2028_08_financial_industries_idx;


--
-- Name: news_all_2028_08_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2028_08_pkey;


--
-- Name: news_all_2028_08_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2028_08_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2028_08_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2028_08_tags_idx;


--
-- Name: news_all_2028_08_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2028_08_to_tsvector_idx;


--
-- Name: news_all_2028_09_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2028_09_broadcast_date_idx;


--
-- Name: news_all_2028_09_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2028_09_category_sentiment_idx;


--
-- Name: news_all_2028_09_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2028_09_entities_idx;


--
-- Name: news_all_2028_09_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2028_09_financial_industries_idx;


--
-- Name: news_all_2028_09_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2028_09_pkey;


--
-- Name: news_all_2028_09_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2028_09_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2028_09_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2028_09_tags_idx;


--
-- Name: news_all_2028_09_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2028_09_to_tsvector_idx;


--
-- Name: news_all_2028_10_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2028_10_broadcast_date_idx;


--
-- Name: news_all_2028_10_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2028_10_category_sentiment_idx;


--
-- Name: news_all_2028_10_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2028_10_entities_idx;


--
-- Name: news_all_2028_10_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2028_10_financial_industries_idx;


--
-- Name: news_all_2028_10_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2028_10_pkey;


--
-- Name: news_all_2028_10_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2028_10_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2028_10_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2028_10_tags_idx;


--
-- Name: news_all_2028_10_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2028_10_to_tsvector_idx;


--
-- Name: news_all_2028_11_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2028_11_broadcast_date_idx;


--
-- Name: news_all_2028_11_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2028_11_category_sentiment_idx;


--
-- Name: news_all_2028_11_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2028_11_entities_idx;


--
-- Name: news_all_2028_11_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2028_11_financial_industries_idx;


--
-- Name: news_all_2028_11_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2028_11_pkey;


--
-- Name: news_all_2028_11_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2028_11_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2028_11_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2028_11_tags_idx;


--
-- Name: news_all_2028_11_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2028_11_to_tsvector_idx;


--
-- Name: news_all_2028_12_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2028_12_broadcast_date_idx;


--
-- Name: news_all_2028_12_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2028_12_category_sentiment_idx;


--
-- Name: news_all_2028_12_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2028_12_entities_idx;


--
-- Name: news_all_2028_12_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2028_12_financial_industries_idx;


--
-- Name: news_all_2028_12_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2028_12_pkey;


--
-- Name: news_all_2028_12_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2028_12_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2028_12_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2028_12_tags_idx;


--
-- Name: news_all_2028_12_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2028_12_to_tsvector_idx;


--
-- Name: news_all_2029_01_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2029_01_broadcast_date_idx;


--
-- Name: news_all_2029_01_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2029_01_category_sentiment_idx;


--
-- Name: news_all_2029_01_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2029_01_entities_idx;


--
-- Name: news_all_2029_01_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2029_01_financial_industries_idx;


--
-- Name: news_all_2029_01_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2029_01_pkey;


--
-- Name: news_all_2029_01_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2029_01_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2029_01_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2029_01_tags_idx;


--
-- Name: news_all_2029_01_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2029_01_to_tsvector_idx;


--
-- Name: news_all_2029_02_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2029_02_broadcast_date_idx;


--
-- Name: news_all_2029_02_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2029_02_category_sentiment_idx;


--
-- Name: news_all_2029_02_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2029_02_entities_idx;


--
-- Name: news_all_2029_02_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2029_02_financial_industries_idx;


--
-- Name: news_all_2029_02_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2029_02_pkey;


--
-- Name: news_all_2029_02_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2029_02_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2029_02_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2029_02_tags_idx;


--
-- Name: news_all_2029_02_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2029_02_to_tsvector_idx;


--
-- Name: news_all_2029_03_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2029_03_broadcast_date_idx;


--
-- Name: news_all_2029_03_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2029_03_category_sentiment_idx;


--
-- Name: news_all_2029_03_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2029_03_entities_idx;


--
-- Name: news_all_2029_03_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2029_03_financial_industries_idx;


--
-- Name: news_all_2029_03_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2029_03_pkey;


--
-- Name: news_all_2029_03_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2029_03_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2029_03_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2029_03_tags_idx;


--
-- Name: news_all_2029_03_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2029_03_to_tsvector_idx;


--
-- Name: news_all_2029_04_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2029_04_broadcast_date_idx;


--
-- Name: news_all_2029_04_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2029_04_category_sentiment_idx;


--
-- Name: news_all_2029_04_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2029_04_entities_idx;


--
-- Name: news_all_2029_04_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2029_04_financial_industries_idx;


--
-- Name: news_all_2029_04_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2029_04_pkey;


--
-- Name: news_all_2029_04_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2029_04_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2029_04_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2029_04_tags_idx;


--
-- Name: news_all_2029_04_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2029_04_to_tsvector_idx;


--
-- Name: news_all_2029_05_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2029_05_broadcast_date_idx;


--
-- Name: news_all_2029_05_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2029_05_category_sentiment_idx;


--
-- Name: news_all_2029_05_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2029_05_entities_idx;


--
-- Name: news_all_2029_05_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2029_05_financial_industries_idx;


--
-- Name: news_all_2029_05_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2029_05_pkey;


--
-- Name: news_all_2029_05_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2029_05_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2029_05_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2029_05_tags_idx;


--
-- Name: news_all_2029_05_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2029_05_to_tsvector_idx;


--
-- Name: news_all_2029_06_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2029_06_broadcast_date_idx;


--
-- Name: news_all_2029_06_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2029_06_category_sentiment_idx;


--
-- Name: news_all_2029_06_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2029_06_entities_idx;


--
-- Name: news_all_2029_06_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2029_06_financial_industries_idx;


--
-- Name: news_all_2029_06_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2029_06_pkey;


--
-- Name: news_all_2029_06_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2029_06_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2029_06_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2029_06_tags_idx;


--
-- Name: news_all_2029_06_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2029_06_to_tsvector_idx;


--
-- Name: news_all_2029_07_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2029_07_broadcast_date_idx;


--
-- Name: news_all_2029_07_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2029_07_category_sentiment_idx;


--
-- Name: news_all_2029_07_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2029_07_entities_idx;


--
-- Name: news_all_2029_07_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2029_07_financial_industries_idx;


--
-- Name: news_all_2029_07_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2029_07_pkey;


--
-- Name: news_all_2029_07_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2029_07_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2029_07_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2029_07_tags_idx;


--
-- Name: news_all_2029_07_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2029_07_to_tsvector_idx;


--
-- Name: news_all_2029_08_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2029_08_broadcast_date_idx;


--
-- Name: news_all_2029_08_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2029_08_category_sentiment_idx;


--
-- Name: news_all_2029_08_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2029_08_entities_idx;


--
-- Name: news_all_2029_08_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2029_08_financial_industries_idx;


--
-- Name: news_all_2029_08_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2029_08_pkey;


--
-- Name: news_all_2029_08_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2029_08_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2029_08_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2029_08_tags_idx;


--
-- Name: news_all_2029_08_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2029_08_to_tsvector_idx;


--
-- Name: news_all_2029_09_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2029_09_broadcast_date_idx;


--
-- Name: news_all_2029_09_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2029_09_category_sentiment_idx;


--
-- Name: news_all_2029_09_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2029_09_entities_idx;


--
-- Name: news_all_2029_09_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2029_09_financial_industries_idx;


--
-- Name: news_all_2029_09_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2029_09_pkey;


--
-- Name: news_all_2029_09_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2029_09_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2029_09_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2029_09_tags_idx;


--
-- Name: news_all_2029_09_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2029_09_to_tsvector_idx;


--
-- Name: news_all_2029_10_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2029_10_broadcast_date_idx;


--
-- Name: news_all_2029_10_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2029_10_category_sentiment_idx;


--
-- Name: news_all_2029_10_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2029_10_entities_idx;


--
-- Name: news_all_2029_10_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2029_10_financial_industries_idx;


--
-- Name: news_all_2029_10_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2029_10_pkey;


--
-- Name: news_all_2029_10_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2029_10_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2029_10_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2029_10_tags_idx;


--
-- Name: news_all_2029_10_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2029_10_to_tsvector_idx;


--
-- Name: news_all_2029_11_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2029_11_broadcast_date_idx;


--
-- Name: news_all_2029_11_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2029_11_category_sentiment_idx;


--
-- Name: news_all_2029_11_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2029_11_entities_idx;


--
-- Name: news_all_2029_11_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2029_11_financial_industries_idx;


--
-- Name: news_all_2029_11_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2029_11_pkey;


--
-- Name: news_all_2029_11_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2029_11_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2029_11_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2029_11_tags_idx;


--
-- Name: news_all_2029_11_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2029_11_to_tsvector_idx;


--
-- Name: news_all_2029_12_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2029_12_broadcast_date_idx;


--
-- Name: news_all_2029_12_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2029_12_category_sentiment_idx;


--
-- Name: news_all_2029_12_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2029_12_entities_idx;


--
-- Name: news_all_2029_12_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2029_12_financial_industries_idx;


--
-- Name: news_all_2029_12_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2029_12_pkey;


--
-- Name: news_all_2029_12_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2029_12_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2029_12_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2029_12_tags_idx;


--
-- Name: news_all_2029_12_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2029_12_to_tsvector_idx;


--
-- Name: news_all_2030_01_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2030_01_broadcast_date_idx;


--
-- Name: news_all_2030_01_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2030_01_category_sentiment_idx;


--
-- Name: news_all_2030_01_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2030_01_entities_idx;


--
-- Name: news_all_2030_01_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2030_01_financial_industries_idx;


--
-- Name: news_all_2030_01_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2030_01_pkey;


--
-- Name: news_all_2030_01_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2030_01_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2030_01_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2030_01_tags_idx;


--
-- Name: news_all_2030_01_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2030_01_to_tsvector_idx;


--
-- Name: news_all_2030_02_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2030_02_broadcast_date_idx;


--
-- Name: news_all_2030_02_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2030_02_category_sentiment_idx;


--
-- Name: news_all_2030_02_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2030_02_entities_idx;


--
-- Name: news_all_2030_02_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2030_02_financial_industries_idx;


--
-- Name: news_all_2030_02_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2030_02_pkey;


--
-- Name: news_all_2030_02_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2030_02_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2030_02_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2030_02_tags_idx;


--
-- Name: news_all_2030_02_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2030_02_to_tsvector_idx;


--
-- Name: news_all_2030_03_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2030_03_broadcast_date_idx;


--
-- Name: news_all_2030_03_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2030_03_category_sentiment_idx;


--
-- Name: news_all_2030_03_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2030_03_entities_idx;


--
-- Name: news_all_2030_03_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2030_03_financial_industries_idx;


--
-- Name: news_all_2030_03_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2030_03_pkey;


--
-- Name: news_all_2030_03_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2030_03_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2030_03_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2030_03_tags_idx;


--
-- Name: news_all_2030_03_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2030_03_to_tsvector_idx;


--
-- Name: news_all_2030_04_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2030_04_broadcast_date_idx;


--
-- Name: news_all_2030_04_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2030_04_category_sentiment_idx;


--
-- Name: news_all_2030_04_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2030_04_entities_idx;


--
-- Name: news_all_2030_04_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2030_04_financial_industries_idx;


--
-- Name: news_all_2030_04_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2030_04_pkey;


--
-- Name: news_all_2030_04_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2030_04_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2030_04_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2030_04_tags_idx;


--
-- Name: news_all_2030_04_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2030_04_to_tsvector_idx;


--
-- Name: news_all_2030_05_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2030_05_broadcast_date_idx;


--
-- Name: news_all_2030_05_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2030_05_category_sentiment_idx;


--
-- Name: news_all_2030_05_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2030_05_entities_idx;


--
-- Name: news_all_2030_05_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2030_05_financial_industries_idx;


--
-- Name: news_all_2030_05_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2030_05_pkey;


--
-- Name: news_all_2030_05_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2030_05_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2030_05_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2030_05_tags_idx;


--
-- Name: news_all_2030_05_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2030_05_to_tsvector_idx;


--
-- Name: news_all_2030_06_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2030_06_broadcast_date_idx;


--
-- Name: news_all_2030_06_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2030_06_category_sentiment_idx;


--
-- Name: news_all_2030_06_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2030_06_entities_idx;


--
-- Name: news_all_2030_06_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2030_06_financial_industries_idx;


--
-- Name: news_all_2030_06_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2030_06_pkey;


--
-- Name: news_all_2030_06_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2030_06_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2030_06_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2030_06_tags_idx;


--
-- Name: news_all_2030_06_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2030_06_to_tsvector_idx;


--
-- Name: news_all_2030_07_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2030_07_broadcast_date_idx;


--
-- Name: news_all_2030_07_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2030_07_category_sentiment_idx;


--
-- Name: news_all_2030_07_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2030_07_entities_idx;


--
-- Name: news_all_2030_07_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2030_07_financial_industries_idx;


--
-- Name: news_all_2030_07_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2030_07_pkey;


--
-- Name: news_all_2030_07_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2030_07_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2030_07_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2030_07_tags_idx;


--
-- Name: news_all_2030_07_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2030_07_to_tsvector_idx;


--
-- Name: news_all_2030_08_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2030_08_broadcast_date_idx;


--
-- Name: news_all_2030_08_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2030_08_category_sentiment_idx;


--
-- Name: news_all_2030_08_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2030_08_entities_idx;


--
-- Name: news_all_2030_08_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2030_08_financial_industries_idx;


--
-- Name: news_all_2030_08_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2030_08_pkey;


--
-- Name: news_all_2030_08_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2030_08_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2030_08_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2030_08_tags_idx;


--
-- Name: news_all_2030_08_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2030_08_to_tsvector_idx;


--
-- Name: news_all_2030_09_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2030_09_broadcast_date_idx;


--
-- Name: news_all_2030_09_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2030_09_category_sentiment_idx;


--
-- Name: news_all_2030_09_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2030_09_entities_idx;


--
-- Name: news_all_2030_09_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2030_09_financial_industries_idx;


--
-- Name: news_all_2030_09_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2030_09_pkey;


--
-- Name: news_all_2030_09_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2030_09_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2030_09_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2030_09_tags_idx;


--
-- Name: news_all_2030_09_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2030_09_to_tsvector_idx;


--
-- Name: news_all_2030_10_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2030_10_broadcast_date_idx;


--
-- Name: news_all_2030_10_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2030_10_category_sentiment_idx;


--
-- Name: news_all_2030_10_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2030_10_entities_idx;


--
-- Name: news_all_2030_10_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2030_10_financial_industries_idx;


--
-- Name: news_all_2030_10_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2030_10_pkey;


--
-- Name: news_all_2030_10_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2030_10_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2030_10_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2030_10_tags_idx;


--
-- Name: news_all_2030_10_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2030_10_to_tsvector_idx;


--
-- Name: news_all_2030_11_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2030_11_broadcast_date_idx;


--
-- Name: news_all_2030_11_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2030_11_category_sentiment_idx;


--
-- Name: news_all_2030_11_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2030_11_entities_idx;


--
-- Name: news_all_2030_11_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2030_11_financial_industries_idx;


--
-- Name: news_all_2030_11_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2030_11_pkey;


--
-- Name: news_all_2030_11_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2030_11_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2030_11_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2030_11_tags_idx;


--
-- Name: news_all_2030_11_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2030_11_to_tsvector_idx;


--
-- Name: news_all_2030_12_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_broadcast_date_brin ATTACH PARTITION public.news_all_2030_12_broadcast_date_idx;


--
-- Name: news_all_2030_12_category_sentiment_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_category_sentiment ATTACH PARTITION public.news_all_2030_12_category_sentiment_idx;


--
-- Name: news_all_2030_12_entities_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_entities_gin ATTACH PARTITION public.news_all_2030_12_entities_idx;


--
-- Name: news_all_2030_12_financial_industries_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_financial_industries ATTACH PARTITION public.news_all_2030_12_financial_industries_idx;


--
-- Name: news_all_2030_12_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.news_all_pkey ATTACH PARTITION public.news_all_2030_12_pkey;


--
-- Name: news_all_2030_12_state_id_district_id_broadcast_date_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_state_district_date ATTACH PARTITION public.news_all_2030_12_state_id_district_id_broadcast_date_idx;


--
-- Name: news_all_2030_12_tags_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_tags_gin ATTACH PARTITION public.news_all_2030_12_tags_idx;


--
-- Name: news_all_2030_12_to_tsvector_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.idx_news_headline_search ATTACH PARTITION public.news_all_2030_12_to_tsvector_idx;


--
-- Name: api_keys api_keys_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: districts districts_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.districts
    ADD CONSTRAINT districts_state_id_fkey FOREIGN KEY (state_id) REFERENCES public.states(id) ON DELETE CASCADE;


--
-- Name: refresh_tokens fk_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: news_all news_all_district_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.news_all
    ADD CONSTRAINT news_all_district_id_fkey FOREIGN KEY (district_id) REFERENCES public.districts(id);


--
-- Name: news_all news_all_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.news_all
    ADD CONSTRAINT news_all_state_id_fkey FOREIGN KEY (state_id) REFERENCES public.states(id);


--
-- Name: users users_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.plans(id);


--
-- PostgreSQL database dump complete
--

\unrestrict dbmate


--
-- Dbmate schema migrations
--

INSERT INTO public.schema_migrations (version) VALUES
    ('20260620104547');
