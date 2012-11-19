--Tp2.sql
-- Numéro c5 et le reste


-- C5: Lorsqu'un étudiant est supprimé, toutes ses inscriptions sont
--     automatiquement supprimées
-- A tester avec exemples
CREATE OR REPLACE TRIGGER BDSupprimeEtudiant
BEFORE DELETE ON Etudiant
FOR EACH ROW
BEGIN
    DELETE FROM Inscription
    WHERE codePermanent = :OLD.codePermanent;
END;
/

--Tests pour les contraintes

--Pour C1: premier insert devrait être accepté
INSERT INTO Cours
VALUES('INF3172', 'Système d exploitation', 3)
/

--deuxième insert devrait être accepté aussi.
INSERT INTO Cours
VALUES('inf4170', 'Architecture des ordinateurs', 3)
/

--les autres insert devrait être refusés
INSERT INTO Cours
VALUES('4170INF', 'Architecture des ordinateurs', 3)
/

INSERT INTO Cours
VALUES('in4170', 'Architecture des ordinateurs', 3)
/

INSERT INTO Cours
VALUES('inf417', 'Architecture des ordinateurs', 3)
/

INSERT INTO Cours
VALUES('in41700', 'Architecture des ordinateurs', 3)
/

--Pour C2: Le premier devrait être accepté, alors que les
--  deux autres rejetés
INSERT INTO Cours
VALUES('INF5151', 'Génie Logiciel', 3)
/

INSERT INTO Cours
VALUES('INF5153', 'Génie Logiciel 2', 103)
/

INSERT INTO Cours
VALUES('INM5151', 'Projet', -5)
/

--Pour C3: La première valeur devrait être insérée dans la table, alors
-- que les autres donneront un erreur d'intégrité
INSERT INTO SessionUQAM
VALUES(32004, '01-01-13', '30-04-13')
/

INSERT INTO SessionUQAM
VALUES(32005, '01-01-13', '01-03-13')
/

INSERT INTO SessionUQAM
VALUES(32006, '01-01-13', '31-03-13')
/

