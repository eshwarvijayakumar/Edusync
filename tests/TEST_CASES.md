# EduSync Test Cases

The following cases use only fictional test identities. They are suitable for manual acceptance testing before a demonstration or submission.

| ID | Scenario | Steps | Expected result |
| --- | --- | --- | --- |
| TC-01 | School registration | Register the Aarav sample profile; choose Grade 10, CBSE, Science and Mathematics | Profile saves and the dashboard displays a Grade 10 CBSE badge |
| TC-02 | College registration | Register the Meera sample profile; choose B.Tech CSE and Semester 4 | Profile saves and dashboard displays a B.Tech CSE Semester 4 badge |
| TC-03 | Required profile validation | Leave a required grade/board or degree/department field empty | User is told which field needs completion; invalid profile is not submitted |
| TC-04 | School-level answer | As Aarav, ask about photosynthesis | Answer is understandable for Grade 10 and includes key revision points |
| TC-05 | College-level answer | As Meera, ask about the Waterfall Model | Answer describes sequential phases, advantages, limitations, and an engineering example |
| TC-06 | General question | Ask a valid question outside selected subjects | App returns a concise answer without falsely claiming syllabus alignment |
| TC-07 | Follow-up context | Ask “Give an example” immediately after a topic answer | Follow-up uses the recent conversation topic |
| TC-08 | Uploaded material | Upload a permitted PDF/text note and ask a related question | File is accepted within limit; answer identifies the material when used |
| TC-09 | Unsafe upload | Try an executable or a file above the configured limit | Upload is rejected with a clear error message |
| TC-10 | Data isolation | Sign in as another test user and attempt to open the first user’s chat/material | Access is denied by database rules |
| TC-11 | Missing AI configuration | Temporarily remove the server AI key in a test environment | UI shows an understandable error and Retry Question action; no empty reply bubble appears |
| TC-12 | Secret safety | Inspect the built app source and repository | No AI key, service-role key, `.env`, keystore, APK, or AAB file is committed |
