CREATE TABLE versions(hash TEXT(7) PRIMARY KEY,
                      description STRING,
                      time INTEGER,
                      major INTEGER,
                      minor INTEGER,
                      wizard INTEGER);