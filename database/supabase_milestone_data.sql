-- MILESTONE 2: DATA POPULATION
-- Populates the database with 20+ records for each table.

-- NOTE: This script assumes you have run the schema script first.
-- Since 'users' table is linked to Auth, we will manually insert dummy users for demonstration.
-- In a real app, users are created via Sign Up.

BEGIN;

-- 1. USERS (20+ Records)
-- Using random UUIDs for auth_id simulation
INSERT INTO public.users (auth_id, full_name, email, dob, student_id) VALUES
(gen_random_uuid(), 'Ali Hassan', '70145252@student.uol.edu.pk', '2000-05-15', '70145252'),
(gen_random_uuid(), 'John Doe', 'john.doe@example.com', '1999-01-10', 'ST-1001'),
(gen_random_uuid(), 'Jane Smith', 'jane.smith@example.com', '1998-11-20', 'ST-1002'),
(gen_random_uuid(), 'Michael Johnson', 'michael.j@example.com', '2001-03-12', 'ST-1003'),
(gen_random_uuid(), 'Emily Davis', 'emily.d@example.com', '2000-07-25', 'ST-1004'),
(gen_random_uuid(), 'Chris Brown', 'chris.b@example.com', '1999-12-05', 'ST-1005'),
(gen_random_uuid(), 'Sarah Wilson', 'sarah.w@example.com', '2002-02-18', 'ST-1006'),
(gen_random_uuid(), 'David Miller', 'david.m@example.com', '2000-09-30', 'ST-1007'),
(gen_random_uuid(), 'Jessica Taylor', 'jessica.t@example.com', '1998-06-14', 'ST-1008'),
(gen_random_uuid(), 'Daniel Anderson', 'daniel.a@example.com', '2001-11-02', 'ST-1009'),
(gen_random_uuid(), 'Laura Thomas', 'laura.t@example.com', '1999-04-22', 'ST-1010'),
(gen_random_uuid(), 'Robert Martinez', 'robert.m@example.com', '2000-08-11', 'ST-1011'),
(gen_random_uuid(), 'Linda Hernandez', 'linda.h@example.com', '1997-12-30', 'ST-1012'),
(gen_random_uuid(), 'James White', 'james.w@example.com', '2001-05-09', 'ST-1013'),
(gen_random_uuid(), 'Barbara Moore', 'barbara.m@example.com', '1998-10-17', 'ST-1014'),
(gen_random_uuid(), 'William Lee', 'william.l@example.com', '2000-02-28', 'ST-1015'),
(gen_random_uuid(), 'Elizabeth Clark', 'elizabeth.c@example.com', '1999-07-07', 'ST-1016'),
(gen_random_uuid(), 'Joseph Rodriguez', 'joseph.r@example.com', '2001-01-15', 'ST-1017'),
(gen_random_uuid(), 'Patricia Lewis', 'patricia.l@example.com', '2000-11-23', 'ST-1018'),
(gen_random_uuid(), 'Thomas Walker', 'thomas.w@example.com', '1998-03-05', 'ST-1019'),
(gen_random_uuid(), 'Jennifer Hall', 'jennifer.h@example.com', '2002-09-09', 'ST-1020');


-- 2. API_CONFIGS (20+ Records)
INSERT INTO public.api_configs (user_id, provider, base_url, api_key) 
SELECT user_id, 
  CASE (user_id % 3)
    WHEN 0 THEN 'Ollama'
    WHEN 1 THEN 'OpenAI'
    ELSE 'Groq'
  END,
  CASE (user_id % 3)
    WHEN 0 THEN 'http://192.168.1.' || (user_id + 10) || ':11434'
    WHEN 1 THEN 'https://api.openai.com/v1'
    ELSE 'https://api.groq.com/openai/v1'
  END,
  CASE (user_id % 3)
    WHEN 0 THEN NULL
    ELSE 'sk-proj-dummy-key-' || user_id
  END
FROM public.users;

-- 3. PERSONAS (20+ Records)
INSERT INTO public.personas (user_id, persona_name, system_prompt) VALUES
((SELECT user_id FROM public.users LIMIT 1 OFFSET 0), 'Code Master', 'You are an expert software engineer. Provide clean, efficient code.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 1), 'Dr. Freud', 'You are a psychoanalyst. Analyze dreams and user thoughts.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 2), 'Samantha', 'You are a friendly and empathetic companion.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 3), 'Math Whiz', 'Solve complex mathematical problems step-by-step.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 4), 'History Buff', 'Explain historical events with detailed context.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 5), 'Fitness Coach', 'Provide workout plans and nutrition advice.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 6), 'Chef Gordon', 'Suggest recipes and critique cooking methods strictly.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 7), 'Travel Guide', 'Recommend destinations and travel tips.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 8), 'Sci-Fi Writer', 'Generate creative science fiction stories.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 9), 'Legal Advisor', 'Provide general legal information (not advice).'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 10), 'Business Analyst', 'Analyze market trends and business strategies.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 11), 'Poet Laureate', 'Compose poems in various styles.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 12), 'Trivia Master', 'Ask and answer trivia questions.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 13), 'Translator', 'Translate text between languages accurately.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 14), 'Debug Bot', 'Help find bugs in code snippets.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 15), 'Philosopher', 'Discuss deep philosophical questions.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 16), 'Music Critic', 'Review albums and suggest music.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 17), 'Startup Mentor', 'Aide in pitching ideas and MVP planning.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 18), 'Gardener', 'Tips for plant care and landscaping.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 19), 'Teacher', 'Explain concepts simply for students.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 0), 'Cyber Punk', 'Speak in futuristic slang and tech jargon.');


-- 4. CHAT_SESSIONS (20+ Records)
INSERT INTO public.chat_sessions (user_id, persona_id, session_title)
SELECT 
  u.user_id, 
  p.persona_id, 
  'Session with ' || p.persona_name
FROM public.users u
JOIN public.personas p ON u.user_id = p.user_id -- Just matching for demo
LIMIT 25;


-- 5. MESSAGES (20+ Generated Records)
INSERT INTO public.messages (session_id, sender_role, content)
SELECT 
  session_id,
  'user',
  'Hello, how can you help me today?'
FROM public.chat_sessions;

INSERT INTO public.messages (session_id, sender_role, content)
SELECT 
  session_id,
  'assistant',
  'I am ready to assist you. What is on your mind?'
FROM public.chat_sessions;


-- 6. KNOWLEDGE_BASE (20+ Records)
INSERT INTO public.knowledge_base (user_id, topic, data_content) VALUES
((SELECT user_id FROM public.users LIMIT 1 OFFSET 0), 'Flutter State Management', 'Riverpod is a reactive caching and data-binding framework.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 1), 'PostgreSQL Joins', 'Inner join returns rows when there is a match in both tables.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 2), 'Machine Learning', 'Supervised learning involves training a model on labeled data.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 3), 'Supabase RLS', 'Row Level Security restricts data access based on user policies.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 4), 'React Hooks', 'UseState allows functional components to have state.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 5), 'Docker Containers', 'Containers package software into standardized units.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 6), 'Agile Methodology', 'Agile is an iterative approach to project management.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 7), 'Cybersecurity', 'Phishing is a method to gather personal information using deceptive e-mails.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 8), 'Cloud Computing', 'AWS provides on-demand cloud computing platforms.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 9), 'REST APIs', 'Representational State Transfer is an architectural style for web services.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 10), 'GraphQL', 'A query language for APIs and a runtime for fulfilling those queries.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 11), 'Python Decorators', 'Decorators modify the behavior of a function or class.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 12), 'Git Version Control', 'Git is a distributed version control system.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 13), 'Mobile App Design', 'UI/UX design focuses on the visual and interactive experience.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 14), 'Big Data', 'Hadoop is a framework for processing large data sets.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 15), 'Blockchain', 'A decentralized ledger of all transactions across a network.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 16), 'IoT', 'Internet of Things connects physical devices to the internet.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 17), 'Microservices', 'An architectural style that structures an application as a collection of services.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 18), 'DevOps', 'Practices that combine software development and IT operations.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 19), 'Serverless', 'A cloud execution model where the cloud provider runs the server.'),
((SELECT user_id FROM public.users LIMIT 1 OFFSET 0), 'Dart Async', 'Futures and Streams are used for asynchronous programming.');

COMMIT;
