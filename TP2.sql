SET ECHO ON
SET SERVEROUTPUT ON
SPOOL TP2.out

-- TP2.sql
-- Par Guillaume Lahaie
-- LAHG04077707
-- Remise: 12 décembre 2012

ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY'
/

--1. Création des contraintes d'intégrité

--C1 Un sigle de cours doit être formé de 3 lettres suivies de quatre chiffres
--Pour le moment, on accepte les lettres majuscules et minuscules.
ALTER TABLE Cours
ADD (CONSTRAINT SigleCours CHECK(REGEXP_LIKE(sigle, '^[a-zA-Z]{3}+[0-9]{4}')))
/

--C2 Le nombre de crédits est un entier entre 0 et 99
ALTER TABLE Cours
ADD (CONSTRAINT NoCredit CHECK(nbCredits < 100 AND nbCredits >= 0))
/

-- C3 : La date de fin de session doit être au moins 90 jours après la date 
--      de début de session
ALTER TABLE SessionUqam
ADD (CONSTRAINT LongueurSession CHECK(DateFin - DateDebut >= 90))
/

--C4 : Si la date d’abandon est non nulle, la note doit être nulle.
--Fait avec l'équivalence logique (A -> B) <-> (notA V B)
ALTER TABLE Inscription
ADD(CONSTRAINT AbandonNote CHECK(DateAbandon IS NULL OR note IS NULL))
/

-- C5: Lorsqu'un étudiant est supprimé, toutes ses inscriptions sont
--     automatiquement supprimées
CREATE OR REPLACE TRIGGER BDSupprimeEtudiant
BEFORE DELETE ON Etudiant
FOR EACH ROW
BEGIN
    LOCK TABLE Inscription IN ROW SHARE MODE;
    DELETE FROM Inscription
    WHERE codePermanent = :OLD.codePermanent;
END;
/

--C6 : Interdire un changement de note de plus de 20 points
CREATE OR REPLACE TRIGGER BUChangementDeNote 
BEFORE UPDATE OF note ON Inscription
FOR EACH ROW
BEGIN
IF ((:NEW.note > :OLD.note + 20) OR (:NEW.note < :OLD.note -20)) THEN
    raise_application_error(-20100, 'Impossible de modifier une note 
                                      de plus de 20 points.');
END IF;
END;
/
  
--2. Insertion des données et tests de contraintes.

--Tests pour C1: 
--Deux INSERT acceptés
INSERT INTO Cours
VALUES('INF3172', 'Système d exploitation', 3)
/

INSERT INTO Cours
VALUES('inf3172', 'Systeme d exploitation', 3)
/

--Le  INSERT est accepté, mais le update sera refusé
INSERT INTO Cours
VALUES('INF4170', 'Architecture des ordinateurs', 3)
/

UPDATE Cours
SET Sigle = '4170INF'
WHERE Sigle ='INF4170'
/

--Les autres INSERT devraient être refusés
INSERT INTO Cours
VALUES('4170INF', 'Architecture des ordinateurs', 3)
/

INSERT INTO Cours
VALUES('in41700', 'Architecture des ordinateurs', 3)
/

INSERT INTO Cours
VALUES('INFF417', 'Architecture des ordinateurs', 3)
/

ROLLBACK
/

--Tests pour C2: 
--Le premier INSERT est accepté, alors que les deux autres rejetés
INSERT INTO Cours
VALUES('INF5151', 'Génie Logiciel', 3)
/

INSERT INTO Cours
VALUES('INF5153', 'Génie Logiciel 2', 103)
/

INSERT INTO Cours
VALUES('INM5151', 'Projet', -5)
/

--Le premier UPDATE est accepté, le second est refusé
UPDATE Cours
SET nbCredits = 40
WHERE sigle = 'INF3123'
/

UPDATE Cours
SET nbCredits = 200
WHERE sigle = 'INF3123'
/

ROLLBACK
/

--Test pour C3: 
--La première valeur devrait être insérée dans la table, alors que les autres 
--donneront un erreur d'intégrité. Le UPDATE est refusé aussi.
INSERT INTO SessionUQAM
VALUES(32004, '01/01/2013', '30/04/2013')
/

INSERT INTO SessionUQAM
VALUES(32005, '01/01/2013', '01/03/2013')
/

INSERT INTO SessionUQAM
VALUES(32006, '01/01/2013', '31/03/2013')
/

UPDATE SessionUQAM
SET dateFin = '28/02/2013'
WHERE codeSession = 32004
/

ROLLBACK
/

--Tests pour C4: 
--Vérification avec UPDATE et INSERT
--Deux erreurs avec UPDATE. Le premier, la date d'abandon est non-nulle et
--on tente d'ajouter une note, Le second, la note est non-nulle et on tente
--d'ajouter une date d'abandon.
UPDATE Inscription
SET note = 75
WHERE  codePermanent = 'MONC05127201' and sigle = 'INF5180'
/

UPDATE Inscription
SET dateAbandon = '20/09/2003'
WHERE codePermanent = 'MONC05127201' and sigle = 'INF3180'
/

--Un UPDATE qui est accepté.
UPDATE Inscription
SET dateAbandon = '20/09/2003', note = NULL
WHERE codePermanent = 'EMEK10106501' AND sigle = 'INF3180'
/

--Un INSERT qui fonctionne, et UPDATE aussi.
INSERT INTO Inscription
VALUES('VANV05127201', 'INF5180', 10, 12004, '15/12/2003', NULL, NULL)
/

UPDATE Inscription
SET note = 80
WHERE codePermanent = 'VANV05127201' and sigle = 'INF5180'
/

--Un INSERT qui ne fonctionne pas.
INSERT INTO Inscription
VALUES('VANV05127201', 'INF1110', 20, 32003, '17/08/2003', '20/09/2003', 80)
/

ROLLBACK
/

--Tests pour C5: 
--On efface un codePermanent qui existe. On affiche les cours dans la table
--Inscription avant le DELETE de la table Etudiant et après.
SELECT *
FROM Inscription
WHERE codePermanent = 'VANV05127201'
/

DELETE FROM Etudiant
WHERE codePermanent = 'VANV05127201'
/

SELECT *
FROM Inscription
WHERE codePermanent = 'VANV05127201'
/

--Tentative pour un code permanent inexistant.
DELETE FROM Etudiant
WHERE codePermanent = 'LAHG04077707'
/

ROLLBACK
/

--Test pour C6: 
--Vérification des UPDATE. Un UPDATE refusé.
UPDATE Inscription
SET note = 65
WHERE codePermanent = 'MARA25087501' AND sigle = 'INF1130'
/

--UPDATE accepté.
UPDATE Inscription
SET note = 75
WHERE codePermanent = 'MARA25087501' AND sigle = 'INF1130'
/

--UPDATE refusé.
UPDATE Inscription
SET note = 96
WHERE codePermanent = 'STEG03106901' AND sigle = 'INF2110'
/

--UPDATE accepté.
UPDATE Inscription
SET note = 85
WHERE codePermanent = 'STEG03106901' AND sigle = 'INF2110'
/

--Vérification sur un changement sur plusieurs lignes. L'UPDATE est refusé.
UPDATE Inscription
SET note = 95
WHERE sigle='INF3180' AND noGroupe = 40
/

--Un UPDATE sur plusieurs lignes acceptées.
UPDATE Inscription
SET note = 90
WHERE sigle='INF1110' AND noGroupe = 20
/

ROLLBACK
/

-------------------------------------------------------------------------------

--3. Ajout de la cote à la Table Inscription.

--C7: Ajout de la colonne et de la contrainte à la table Inscription
ALTER TABLE Inscription
ADD cote  CHAR(1)
CONSTRAINT BonneCote CHECK(cote IN ('A','B','C','D','E'))
/

--Fonction fCotePourNote: traite les cas pour 
CREATE OR REPLACE FUNCTION fCotePourNote(
  laNote  Inscription.note%TYPE)
  RETURN Inscription.cote%TYPE
IS
  laCote  Inscription.cote%TYPE;
BEGIN
  IF(laNote >100 or laNote < 0) THEN
    raise_application_error(-20100, 'Mauvaise note');
  ELSIF (laNote IS NULL) THEN
      laCote := NULL;
  ELSIF (laNote >=90) THEN
      laCote := 'A';
  ELSIF (laNote < 90 AND laNote >= 80) THEN
      laCote := 'B';
  ELSIF (laNote < 80 AND laNote >= 70) THEN
    laCote := 'C';
  ELSIF (laNote < 70 AND laNote >= 60) THEN
    laCote := 'D';
  ELSE
    laCote :='E';
  END IF;
  
  RETURN laCote;
END;
/

--Mise à jour de toutes les lignes.
UPDATE Inscription
SET COTE = fcotepournote(note)
/

--Affichage de la table mise à jour.
SELECT *
FROM INSCRIPTION
/

--------------------------------------------------------------------------------

--4. Création d'une procédure PL/SQL pBulletin. La procédure affiche un message
--   si un le codePermanent n'existe pas, ou si le codePermanent n'a pas de cous
--   dans la table Inscription. Cas non-traité: cours abandonné.

CREATE OR REPLACE PROCEDURE pBulletin
  (leCodePermanent  Inscription.codepermanent%TYPE)
IS
leNom       etudiant.nom%TYPE;
lePrenom    etudiant.prenom%TYPE;
leSigle     Inscription.sigle%TYPE;
leGroupe    Inscription.noGroupe%TYPE;
laSession   Inscription.codeSession%TYPE;
laNote      Inscription.note%TYPE;
laCote      Inscription.cote%TYPE;
nombreCours NUMBER;

CURSOR touteInscription
(unCodePermanent  inscription.codepermanent%TYPE) IS
  SELECT sigle, noGroupe, codeSession, note, cote
  FROM Inscription
  WHERE codePermanent = unCodePermanent;

BEGIN
  dbms_output.put_line('code permament: ' || leCodePermanent);

  SELECT nom, prenom INTO leNom, lePrenom
  FROM Etudiant
  WHERE codePermanent = leCodePermanent;

  DBMS_OUTPUT.PUT_LINE('nom: ' || leNom);
  DBMS_OUTPUT.PUT_LINE('prenom: ' || lePrenom);

  SELECT COUNT(*) INTO nombreCours
  FROM Inscription
  WHERE codePermanent = leCodePermanent;
  
  IF (nombreCours = 0) THEN
    DBMS_OUTPUT.PUT_LINE('Aucun cours pour ce code permanent.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('sigle   noGroupe  session note  cote');
    OPEN touteInscription(leCodePermanent);

    LOOP
      FETCH touteInscription INTO leSigle, leGroupe, laSession, laNote, laCote;
      EXIT WHEN touteInscription%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE(leSigle || ' ' || leGroupe || '        ' || laSession 
                          || '   ' || laNote || '    ' || laCote);  
    END LOOP;
  
    CLOSE touteInscription;
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN 
    DBMS_OUTPUT.PUT_LINE('Le codePermanent n''existe pas');
END;
/

--Essai de la procédure
EXECUTE pBulletin('TREJ18088001')

EXECUTE pBulletin('VANV05127201')

EXECUTE pBulletin('LAHG04077707')

INSERT INTO Etudiant
VALUES('LAHG04077707','Lahaie','Guillaume', 7316)
/

EXECUTE pBulletin('LAHG04077707')

ROLLBACK
/

--------------------------------------------------------------------------------

--5. Trigger qui calcule automatiquement la cote suite à une insertion
--   ou mise-à-jour d'inscription. Si la note est changée pour NULL, alors
--   la cote est aussi NULL.
CREATE OR REPLACE TRIGGER BIUMiseAJourNote
BEFORE INSERT OR UPDATE OF note ON Inscription
FOR EACH ROW
BEGIN
    IF (:NEW.note IS NOT NULL) THEN
      :NEW.cote:=fCotePourNote(:NEW.note);
    ELSE
      :NEW.cote := NULL;
    END IF;
END;
/

--Tests du déclencheur.
INSERT INTO Inscription
VALUES('DUGR08085001','INF1110',20,32003,'16/08/2003',NULL,80,NULL)
/

SELECT *
FROM Inscription
WHERE codePermanent='DUGR08085001' AND sigle='INF1110' AND noGroupe=20
AND codeSession=32003
/

UPDATE Inscription
SET note= 70
WHERE codePermanent='DUGR08085001' AND sigle='INF1110' AND noGroupe = 20
AND codeSession = 32003
/

SELECT *
FROM Inscription
WHERE codePermanent='DUGR08085001' AND sigle='INF1110' AND noGroupe=20
AND codeSession=32003
/
--Le déclencheur est aussi testé lors du numéro 6.
--------------------------------------------------------------------------------

--6. Création de la vue MoyenneParGroupe
CREATE OR REPLACE VIEW MoyenneParGroupe AS
SELECT sigle, noGroupe, codeSession, AVG(note) AS moyenneNote
FROM Inscription
GROUP BY sigle, noGroupe, codeSession
ORDER BY sigle, noGroupe, codeSession
/

--Vérification de la vue
SELECT *
FROM MoyenneParGroupe
/

--Définition du déclencheur.
CREATE OR REPLACE TRIGGER IUChangementMoyenne 
INSTEAD OF UPDATE ON MoyenneParGroupe
REFERENCING
  OLD AS ligneAvant
  NEW AS ligneApres
FOR EACH ROW
DECLARE
  leCodePermanent   Inscription.codePermanent%TYPE;
  leSigle           Inscription.sigle%TYPE;
  leGroupe          Inscription.codeSession%TYPE;
  leCodeSession     Inscription.codeSession%TYPE;
  laNote            Inscription.note%TYPE;

CURSOR lignesInscription IS
  SELECT codePermanent, sigle, noGroupe, codeSession, note
  FROM Inscription
  WHERE sigle = :ligneApres.sigle AND noGroupe = :ligneApres.noGroupe 
  AND codeSession = :ligneApres.codeSession;
  
BEGIN

--Vérification de la nouvelle valeur de la moyenne
IF (:ligneApres.moyenneNote < 0 OR :ligneApres.moyenneNote > 100 OR 
    :ligneApres.moyenneNote IS NULL) THEN

  raise_application_error(-20100, 'Moyenne invalide');
END IF;

OPEN lignesInscription;
LOOP
  FETCH lignesInscription INTO leCodePermanent, leSigle, leGroupe, 
        leCodeSession, laNote;
  EXIT WHEN lignesInscription%NOTFOUND;

  IF (laNote IS NOT NULL) THEN
    UPDATE Inscription
    SET note = (laNote - :ligneAvant.moyenneNote) + :ligneApres.moyenneNote
    WHERE codePermanent = leCodePermanent AND sigle = leSigle AND
    codeSession = leCodeSession AND noGroupe = leGroupe;
  END IF;

END LOOP;

CLOSE lignesInscription;
END;
/

--Test du déclencheur
UPDATE MoyenneParGroupe
SET MoyenneNote = 70
WHERE sigle = 'INF1130' AND noGroupe = 10 AND codeSession = 32003
/

SELECT * 
FROM MoyenneParGroupe
WHERE sigle = 'INF1130' AND noGroupe = 10 AND codesession = 32003
/

SELECT *
FROM Inscription
WHERE sigle = 'INF1130' AND noGroupe = 10 AND codesession = 32003
/

--Changements de moyenne qui ne fonctionne pas
UPDATE MoyenneParGroupe
SET MoyenneNote = NULL
WHERE sigle = 'INF1130' AND noGroupe = 10 AND codeSession = 32003
/

--Ici la contrainte d'intégrité de changement de note sur inscription devrait
--refuser cette mise à jour
UPDATE MoyenneParGroupe
SET MoyenneNote = 40
WHERE sigle = 'INF1130' AND noGroupe = 10 AND codeSession = 32003
/

UPDATE MoyenneParGroupe
SET MoyenneNote = 120
WHERE sigle = 'INF1130' AND noGroupe = 10 AND codeSession = 32003
/

ROLLBACK
/

SET ECHO OFF
SPOOL OFF
