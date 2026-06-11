# Next Build Step: Vanilla Kobo Baseline

The brand assets have been processed and committed. The next step is to prove the real KoboToolbox baseline before applying any CARE-AI skin.

## Objective

Run a clean vanilla KoboToolbox instance locally in Workstation mode and confirm the end-to-end data capture flow works.

## Hard guardrails

- Do not build a new data collection platform.
- Do not modify Kobo source code during this step.
- Do not apply CARE-AI branding during this step.
- Do not touch Kobo submission, sync, XLSForm, export, authentication, or API internals.
- The only acceptable output is a working vanilla Kobo baseline and an install/test report.

## Acceptance tests

The baseline is complete only when all of the following are true:

1. Kobo opens locally.
2. Admin user can log in.
3. A test XLSForm can be uploaded.
4. The form can be deployed.
5. A test submission can be made.
6. The submission can be viewed in Kobo.
7. The submission can be exported.
8. API access can retrieve the submission.
9. Docker containers can be stopped and restarted.
10. Any install/configuration changes are documented.

## Local target

Use local/workstation mode first. No domain is required.

Expected local URLs may include:

- `http://kf.kobo.local`
- `http://kc.kobo.local`
- `http://ee.kobo.local`

## Output required

Create this file after installation/testing:

- `docs/vanilla-kobo-baseline-report.md`

The report must include:

- Install mode used
- Local URLs
- Admin account created, excluding password
- Docker containers running
- Test XLSForm used
- Submission test result
- Export test result
- API test result
- Issues encountered
- Files/configuration changed
- Exact commands that were run
