# Hűtőhőmérő

## Dokumentáció:
### API:
 - #### **Regisztálás:** 
	**```/register``` URI-n lehet.**
  
	Kell neki egy ```username```, és egy ```password``` JSON-ban összefoglalva, és ha sikeres a regisztáció, akkor visszad egy ```access_token```, és egy ```status``` objectet JSON-ban.
	**Példa cURL-t használva:**
	```
	curl -X POST -H "Content-Type: application/json" -d '{
	"username": "username", "password": "password"
	}' http://localhost:5000/register
	```
	**Szerver válasza:**
	```
	{
	  "access_token": "titok",
	  "status": "success"
	}
	```
- #### **Bejelentkezés:** 
  **```/login``` URI-n lehet.**
  
  Kell neki egy ```username```, és egy ```password``` JSON-ban összefoglalva, és ha sikeres a bejelentkezés, akkor visszad egy ```access_token```, és egy ```status``` objectet JSON-ban.
**Példa cURL-t használva:**
	```
	curl -X POST -H "Content-Type: application/json" -d '{
	"username": "username", "password": "password"
	}' http://localhost:5000/login
	```
	**Szerver válasza:**
	```
	{
	  "access_token": "titok",
	  "status": "success"
	}
	```

  
- #### **Adatok feltöltése:** 
  **```/postData``` URI-n lehet.**
  
  A szerver a ```humidity```,```temperature```,```pressure```,```location```, és ```access_token```, objecteket várja el.
  Ha sikeres a feltöltés, visszadja ```status```-ban, hogy ```success```.
**Példa cURL-t használva:**
	```
	curl -X POST -H "Content-Type: application/json" -d '{
	  "humidity": "145",
	  "temperature": "64.95",
	  "pressure": "534",
	  "location": "default",
	  "access_token": "titok"
	}' http://localhost:5000/postData
	```
	**Szerver válasza:**
	```
	{
	  "message": "Successfully posted data",
	  "status": "success"
	}
	```

### Eszköz hibakódjai:
 - ##### **102:**
    **Az eszköz nem tudja elérni a szervert.**
    
 - ##### **103:**
    **Az eszköz nem tudja az üzenetet a szervertől értelmezni.**
    
 - ##### **104:**
    **Az eszközben elmentve rossz felhasználónév/jelszó van.**
    
