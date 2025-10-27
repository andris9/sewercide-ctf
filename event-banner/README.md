# Sewercide CTF Banner

Event package containing the challenge briefing banner for the Sewercide CTF challenge.

## Package Type

This is an Event package that displays challenge instructions when the exercise starts.

## Usage

Referenced in the SDL file as an inject:

```yaml
injects:
  intro-banner:
    source:
      name: sewercide-ctf-banner
      version: 0.2.21
    from-entity: target
    to-entities:
      - participant
```

## Publishing

```bash
cd event-banner
cp ../release.sh .
chmod +x release.sh
./release.sh 0.2.21 -y
```

## Version

Matches the main sewercide-ctf package version for consistency.
