package it.softstrategy.nevis.onvif.discovery;

import org.simpleframework.xml.Element;
import org.simpleframework.xml.Root;

@Root(strict = false)
public class EnvelopeProbeMatches extends Envelope {

    @Element(name = "Body")
    public BodyProbeMatches BodyProbeMatches;
}
