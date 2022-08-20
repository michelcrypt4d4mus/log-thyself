SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: event_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.event_type_enum AS ENUM (
    'activityCreateEvent',
    'logEvent',
    'stateEvent',
    'timesyncEvent',
    'activityTransitionEvent',
    'signpostEvent',
    'traceEvent',
    'userActionEvent'
);


--
-- Name: message_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.message_type AS ENUM (
    'Debug',
    'Info',
    'Default',
    'Error',
    'Fault'
);


--
-- Name: message_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.message_type_enum AS ENUM (
    'Debug',
    'Default',
    'Error',
    'Fault',
    'Info'
);


--
-- Name: msg_type_char(public.message_type, public.event_type_enum); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.msg_type_char(message_type public.message_type, event_type public.event_type_enum) RETURNS character
    LANGUAGE sql IMMUTABLE LEAKPROOF PARALLEL SAFE
    AS $_$
  SELECT
    -- Most to least frequent for speed reasons
    CASE
      WHEN $1 = 'Debug'
        THEN 'D'
      WHEN $1 = 'Info'
        THEN 'I'
      WHEN $1 = 'Default'
        THEN '_'
      WHEN $2 = 'activityCreateEvent'
        THEN 'a'
      WHEN $1 = 'Error'
        THEN 'E'
      WHEN $1 = 'Fault'
        THEN 'F'
      WHEN $2 = 'stateEvent'
        THEN 's'
      WHEN $2 = 'timesyncEvent'
        THEN 't'
      WHEN $2 = 'activityTransitionEvent'
        THEN 'c'
      WHEN $2 = 'signpostEvent'
        THEN 'p'
      WHEN $2 = 'traceEvent'
        THEN 'r'
      WHEN $2 = 'userActionEvent'
        THEN 'u'
      WHEN $1 IS NULL AND $2 IS NULL
        THEN NULL
      ELSE
        '?'
      END
$_$;


--
-- Name: random_int_between(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.random_int_between(low integer, high integer) RETURNS integer
    LANGUAGE sql IMMUTABLE STRICT LEAKPROOF COST 25 PARALLEL SAFE
    AS $$
  SELECT floor(random()* (high-low + 1) + low);
$$;


--
-- Name: redact_ids(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.redact_ids(a_string character varying) RETURNS character varying
    LANGUAGE sql IMMUTABLE LEAKPROOF PARALLEL SAFE
    AS $_$
  SELECT
    REGEXP_REPLACE(
      REGEXP_REPLACE(
        REGEXP_REPLACE(
          REGEXP_REPLACE(
            REGEXP_REPLACE($1, '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}', '[redacted UUID]', 'ig'),
            '0x[0-9a-f]+|[0-9a-f]{6,}', '[redacted hex]', 'ig'
          ),
          'Hostname#[0-9a-f]+:\d+', '[redacted host]', 'ig'
        ),
        '\d{3}-\d{3}-\d{3,}', '[redacted ID]', 'ig'
      ),
      'pid[=: ]{0,2}\d+', '[redacted PID]', 'ig'
    )

$_$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: file_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.file_events (
    id bigint NOT NULL,
    event_timestamp timestamp(6) without time zone,
    event_type character varying,
    file character varying,
    process_name character varying,
    uid smallint,
    pid integer,
    ppid integer,
    rpid integer,
    is_process_signed_as_reported boolean,
    computed_signing_id character varying,
    reported_signing_id character varying,
    raw_event json,
    created_at timestamp without time zone DEFAULT (now() AT TIME ZONE 'utc'::text) NOT NULL,
    signature_signer character varying,
    signature_authorities character varying,
    process_arguments character varying
);


--
-- Name: COLUMN file_events.event_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.file_events.event_type IS 'See https://developer.apple.com/documentation/endpointsecurity/event_types';


--
-- Name: COLUMN file_events.process_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.file_events.process_name IS 'The process causing the event';


--
-- Name: COLUMN file_events.rpid; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.file_events.rpid IS '"Real" parent process ID';


--
-- Name: COLUMN file_events.reported_signing_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.file_events.reported_signing_id IS 'Only populated if it differs from the computed signature';


--
-- Name: logfile_lines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.logfile_lines (
    id bigint NOT NULL,
    logfile_id integer NOT NULL,
    line_number integer NOT NULL,
    line character varying NOT NULL,
    created_at timestamp without time zone DEFAULT (now() AT TIME ZONE 'utc'::text) NOT NULL
);


--
-- Name: logfiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.logfiles (
    id bigint NOT NULL,
    file_path character varying NOT NULL,
    file_created_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: macos_system_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.macos_system_logs (
    id bigint NOT NULL,
    log_timestamp timestamp(6) without time zone,
    event_type public.event_type_enum,
    message_type public.message_type,
    category character varying,
    event_message character varying,
    process_name character varying,
    sender_process_name character varying,
    subsystem character varying,
    process_id integer,
    thread_id integer,
    trace_id numeric(26,0),
    source json,
    activity_identifier character varying,
    parent_activity_identifier integer,
    backtrace json,
    process_image_path character varying,
    sender_image_path character varying,
    boot_uuid character varying,
    process_image_uuid character varying,
    sender_image_uuid character varying,
    mach_timestamp bigint,
    sender_program_counter bigint,
    timezone_name character varying,
    creator_activity_id numeric(26,0),
    created_at timestamp without time zone DEFAULT (now() AT TIME ZONE 'utc'::text) NOT NULL
);


--
-- Name: COLUMN macos_system_logs.trace_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.macos_system_logs.trace_id IS 'Max observed value was 20 digits';


--
-- Name: COLUMN macos_system_logs.creator_activity_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.macos_system_logs.creator_activity_id IS 'Max observed value was 20 digits';


--
-- Name: process_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.process_events (
    id bigint NOT NULL,
    event_timestamp timestamp(6) without time zone NOT NULL,
    event_type character varying,
    process_path character varying NOT NULL,
    process_name character varying NOT NULL,
    process_arguments character varying,
    uid smallint,
    pid integer NOT NULL,
    ppid integer,
    rpid integer,
    exit_code integer,
    is_process_signed_as_reported boolean,
    signature_signer character varying,
    signature_authorities character varying,
    computed_signing_id character varying,
    reported_signing_id character varying,
    raw_event json,
    created_at timestamp without time zone DEFAULT (now() AT TIME ZONE 'utc'::text) NOT NULL
);


--
-- Name: COLUMN process_events.event_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.process_events.event_type IS 'See https://developer.apple.com/documentation/endpointsecurity/event_types';


--
-- Name: COLUMN process_events.rpid; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.process_events.rpid IS '"Real" parent process ID';


--
-- Name: COLUMN process_events.reported_signing_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.process_events.reported_signing_id IS 'Only populated if it differs from the computed signature';


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: simplified_system_logs; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.simplified_system_logs AS
 SELECT public.msg_type_char(macos_system_logs.message_type, macos_system_logs.event_type) AS "L",
    macos_system_logs.log_timestamp,
    macos_system_logs.process_name AS process,
    macos_system_logs.process_id AS pid,
    macos_system_logs.sender_process_name AS sender,
    macos_system_logs.category,
    macos_system_logs.subsystem,
    macos_system_logs.event_message
   FROM public.macos_system_logs;


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: file_events file_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.file_events
    ADD CONSTRAINT file_events_pkey PRIMARY KEY (id);


--
-- Name: logfile_lines logfile_lines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.logfile_lines
    ADD CONSTRAINT logfile_lines_pkey PRIMARY KEY (id);


--
-- Name: logfiles logfiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.logfiles
    ADD CONSTRAINT logfiles_pkey PRIMARY KEY (id);


--
-- Name: macos_system_logs macos_system_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.macos_system_logs
    ADD CONSTRAINT macos_system_logs_pkey PRIMARY KEY (id);


--
-- Name: process_events process_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.process_events
    ADD CONSTRAINT process_events_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: index_file_events_on_computed_signing_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_file_events_on_computed_signing_id ON public.file_events USING btree (computed_signing_id);


--
-- Name: index_file_events_on_event_timestamp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_file_events_on_event_timestamp ON public.file_events USING btree (event_timestamp);


--
-- Name: index_file_events_on_event_type_and_process_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_file_events_on_event_type_and_process_name ON public.file_events USING btree (event_type, process_name);


--
-- Name: index_file_events_on_file; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_file_events_on_file ON public.file_events USING btree (file);


--
-- Name: index_file_events_on_pid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_file_events_on_pid ON public.file_events USING btree (pid);


--
-- Name: index_file_events_on_ppid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_file_events_on_ppid ON public.file_events USING btree (ppid);


--
-- Name: index_file_events_on_process_name_and_event_timestamp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_file_events_on_process_name_and_event_timestamp ON public.file_events USING btree (process_name, event_timestamp);


--
-- Name: index_file_events_on_rpid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_file_events_on_rpid ON public.file_events USING btree (rpid);


--
-- Name: index_file_events_on_signature_signer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_file_events_on_signature_signer ON public.file_events USING btree (signature_signer);


--
-- Name: index_file_events_on_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_file_events_on_uid ON public.file_events USING btree (uid);


--
-- Name: index_line_with_gin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_line_with_gin ON public.logfile_lines USING gin (line public.gin_trgm_ops);


--
-- Name: index_logfile_lines_on_logfile_id_and_line_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_logfile_lines_on_logfile_id_and_line_number ON public.logfile_lines USING btree (logfile_id, line_number);


--
-- Name: index_logfiles_on_file_path_and_file_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_logfiles_on_file_path_and_file_created_at ON public.logfiles USING btree (file_path, file_created_at);


--
-- Name: index_macos_system_logs_on_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_macos_system_logs_on_category ON public.macos_system_logs USING btree (category);


--
-- Name: index_macos_system_logs_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_macos_system_logs_on_created_at ON public.macos_system_logs USING btree (created_at);


--
-- Name: index_macos_system_logs_on_event_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_macos_system_logs_on_event_type ON public.macos_system_logs USING btree (event_type);


--
-- Name: index_macos_system_logs_on_message_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_macos_system_logs_on_message_type ON public.macos_system_logs USING btree (message_type);


--
-- Name: index_macos_system_logs_on_process_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_macos_system_logs_on_process_id ON public.macos_system_logs USING btree (process_id);


--
-- Name: index_macos_system_logs_on_process_image_path; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_macos_system_logs_on_process_image_path ON public.macos_system_logs USING btree (process_image_path);


--
-- Name: index_macos_system_logs_on_process_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_macos_system_logs_on_process_name ON public.macos_system_logs USING btree (process_name);


--
-- Name: index_macos_system_logs_on_sender_image_path; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_macos_system_logs_on_sender_image_path ON public.macos_system_logs USING btree (sender_image_path);


--
-- Name: index_macos_system_logs_on_sender_process_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_macos_system_logs_on_sender_process_name ON public.macos_system_logs USING btree (sender_process_name);


--
-- Name: index_macos_system_logs_on_subsystem; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_macos_system_logs_on_subsystem ON public.macos_system_logs USING btree (subsystem);


--
-- Name: index_msg_with_gin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_msg_with_gin ON public.macos_system_logs USING gin (event_message public.gin_trgm_ops);


--
-- Name: index_process_events_on_event_timestamp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_process_events_on_event_timestamp ON public.process_events USING btree (event_timestamp);


--
-- Name: index_process_events_on_event_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_process_events_on_event_type ON public.process_events USING btree (event_type);


--
-- Name: index_process_events_on_process_name_and_event_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_process_events_on_process_name_and_event_type ON public.process_events USING btree (process_name, event_type);


--
-- Name: index_process_events_on_signature_signer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_process_events_on_signature_signer ON public.process_events USING btree (signature_signer);


--
-- Name: index_process_events_on_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_process_events_on_uid ON public.process_events USING btree (uid);


--
-- Name: not_quite_unique_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX not_quite_unique_index ON public.macos_system_logs USING btree (log_timestamp, event_type, message_type, category, sender_process_name, subsystem, process_id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20220806184924'),
('20220808050618'),
('20220808050807'),
('20220808051131'),
('20220808051132'),
('20220808051133'),
('20220808133420'),
('20220808150616'),
('20220809005855'),
('20220810012947'),
('20220810025110'),
('20220810112513'),
('20220810211858'),
('20220812062112'),
('20220812064730'),
('20220813082201'),
('20220813083906'),
('20220814040244'),
('20220814072136'),
('20220814193021'),
('20220815062356'),
('20220815121442'),
('20220817050309'),
('20220818185936'),
('20220820030108'),
('20220820071433');


