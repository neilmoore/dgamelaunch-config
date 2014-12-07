CREATE TABLE versions(hash TEXT(7) PRIMARY KEY,
                      description STRING,
                      time INTEGER,
                      major INTEGER,
                      minor INTEGER,
                      wizard INTEGER);
CREATE TABLE branches(name TEXT(50) NOT NULL PRIMARY KEY,
                      git TEXT(50) NOT NULL,
                      description STRING NOT NULL,
                      abbrev TEXT(1) NOT NULL,
                      sprintabbr TEXT(1), -- null means no sprint
                      ord INTEGER,        -- null to disable?
                      wizard INTEGER NOT NULL); -- boolean?
