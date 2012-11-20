--Tp2.sql
-- Numéro c5 et le reste
--C1 Un sigle de cours doit être formé de 3 lettres suivies de quatre chiffres

--ALTER TABLE Cours
--ADD (CONSTRAINT SigleCours CHECK(REGEXP_LIKE(sigle, '^[A-Z]{3}+[0-9]{4}')))
--/

--C2 Le nombre de crédits est un entier entre 0 et 99
--ALTER TABLE Cours
--ADD (CONSTRAINT NoCredit CHECK(nbCredits < 100 AND nbCredits >= 0))
--/

-- C3 : La date de fin de session doit être au moins 90 jours après la date 
--      de début de session
--ALTER TABLE SessionUqam
--ADD (CONSTRAINT LongueurSession CHECK(DateFin - DateDebut >= 90))
--/

--C4 : Si la date d’abandon est non nulle, la note doit être nulle.
--Fait avec l'équivalence logique (A -> B) <-> (notA V B)
-- À tester plus tard
--ALTER TABLE Inscription
--ADD(CONSTRAINT AbandonNote CHECK(DateAbandon IS NULL OR note IS NULL))
--/

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

--C6 : Interdire un changement de note de plus de 20 points
CREATE OR REPLACE TRIGGER BUChangementDeNote 
BEFORE UPDATE OF note ON Inscription
REFERENCING
  OLD AS ligneAvant
  NEW AS ligneApres
FOR EACH ROW
WHEN (ligneApres.note > ligneAvant.note + 20)
BEGIN
    raise_application_error(-20999, 'Il est impossible de modifier une note de plus de 20 points.');
  END
  



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

