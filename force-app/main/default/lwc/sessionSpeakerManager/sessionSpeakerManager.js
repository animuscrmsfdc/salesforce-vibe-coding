import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import SessionSpeakerAddModal from 'c/sessionSpeakerAddModal';

import searchSessions from '@salesforce/apex/SessionSpeakerManagerController.searchSessions';
import getSessionSpeakers from '@salesforce/apex/SessionSpeakerManagerController.getSessionSpeakers';
import getSessionSpeakersLive from '@salesforce/apex/SessionSpeakerManagerController.getSessionSpeakersLive';
import saveSession from '@salesforce/apex/SessionSpeakerManagerController.saveSession';
import saveSessionSpeaker from '@salesforce/apex/SessionSpeakerManagerController.saveSessionSpeaker';
import removeSessionSpeaker from '@salesforce/apex/SessionSpeakerManagerController.removeSessionSpeaker';

// Deterministic avatar color from speaker name
const AVATAR_COLORS = [
    '#1B3A6B', '#4A90D9', '#217346', '#9B59B6',
    '#E67E22', '#C0392B', '#1ABC9C', '#2C3E50'
];

function avatarColor(str) {
    if (!str) return AVATAR_COLORS[0];
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
        // eslint-disable-next-line no-bitwise
        hash = str.charCodeAt(i) + ((hash << 5) - hash);
    }
    return AVATAR_COLORS[Math.abs(hash) % AVATAR_COLORS.length];
}

function initials(firstName, lastName) {
    return ((firstName || '').charAt(0) + (lastName || '').charAt(0)).toUpperCase() || '?';
}

function formatDateTime(dt) {
    if (!dt) return '—';
    return new Date(dt).toLocaleString(undefined, {
        year: 'numeric', month: 'short', day: 'numeric',
        hour: '2-digit', minute: '2-digit'
    });
}

function enrichSession(session, selectedId) {
    const isSelected = session.Id === selectedId;
    const status = session.Status__c || 'Draft';
    const statusMap = {
        Draft: 'ssm-badge ssm-badge--draft',
        Published: 'ssm-badge ssm-badge--published',
        Cancelled: 'ssm-badge ssm-badge--cancelled'
    };
    return {
        ...session,
        formattedDate: formatDateTime(session.Session_Date__c),
        statusBadgeClass: statusMap[status] || 'ssm-badge',
        isSelected,
        cardClass: isSelected
            ? 'ssm-session-card ssm-session-card--selected'
            : 'ssm-session-card'
    };
}

function enrichSessionSpeaker(ss) {
    const fn = (ss.Speaker__r && ss.Speaker__r.First_Name__c) || '';
    const ln = (ss.Speaker__r && ss.Speaker__r.Last_Name__c) || '';
    const name = `${fn} ${ln}`.trim() || 'speaker';
    return {
        ...ss,
        initials: initials(fn, ln),
        avatarStyle: `background: ${avatarColor(ln + fn)};`,
        removeAriaLabel: `Remove ${name}`
    };
}

export default class SessionSpeakerManager extends NavigationMixin(LightningElement) {

    // ─── Step State ──────────────────────────────────────────────────────────
    currentStep = 1;

    get isStep1() { return this.currentStep === 1; }
    get isStep2() { return this.currentStep === 2; }
    get isStep3() { return this.currentStep === 3; }

    get stepPill1Class() {
        return this.currentStep >= 1
            ? 'ssm-step-pill ssm-step-pill--active'
            : 'ssm-step-pill';
    }
    get stepPill2Class() {
        return this.currentStep >= 2
            ? 'ssm-step-pill ssm-step-pill--active'
            : 'ssm-step-pill';
    }
    get stepPill3Class() {
        return this.currentStep >= 3
            ? 'ssm-step-pill ssm-step-pill--active'
            : 'ssm-step-pill';
    }

    // ─── Step 1: Session Search ───────────────────────────────────────────────
    sessionSearchTerm = null;
    selectedSessionId = null;
    selectedSession = null;
    showNewSession = false;
    newSession = { Name: '', Status__c: 'Draft', Level__c: '' };
    isSaving = false;
    _sessionSearchTimeout;
    _sessionSearchLoading = false;
    _rawSessions = { data: null, error: null };

    @wire(searchSessions, { searchTerm: '$sessionSearchTerm' })
    wiredSessions(result) {
        this._rawSessions = result;
        // Only clear the loading flag when actual data or an error arrives,
        // not on the initial empty delivery before Apex resolves.
        if (result.data !== undefined || result.error) {
            this._sessionSearchLoading = false;
        }
    }

    get sessions() {
        if (this.sessionSearchTerm === null) return { data: null, error: null };
        // Guard stale wire results while a new search is in-flight; suppresses
        // the brief error flash that appeared before the new wire resolved.
        if (this._sessionSearchLoading) return { data: null, error: null };
        if (!this._rawSessions) return { data: null, error: null };
        if (this._rawSessions.error) return this._rawSessions;
        if (!this._rawSessions.data) return this._rawSessions;
        return {
            data: this._rawSessions.data.map(s => enrichSession(s, this.selectedSessionId)),
            error: undefined
        };
    }

    get hasSearched() {
        return this.sessionSearchTerm !== null;
    }

    get hasSessions() {
        return this.sessions.data && this.sessions.data.length > 0;
    }

    get noSessionSelected() {
        return !this.selectedSessionId;
    }

    get newSessionToggleIcon() {
        return this.showNewSession ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get statusOptions() {
        return [
            { label: 'Draft', value: 'Draft' },
            { label: 'Published', value: 'Published' },
            { label: 'Cancelled', value: 'Cancelled' }
        ];
    }

    get levelOptions() {
        return [
            { label: '— None —', value: '' },
            { label: 'Beginner', value: 'Beginner' },
            { label: 'Intermediate', value: 'Intermediate' },
            { label: 'Advanced', value: 'Advanced' }
        ];
    }

    handleSessionSearchChange(event) {
        window.clearTimeout(this._sessionSearchTimeout);
        const val = event.target.value || '';
        if (val.length >= 3) {
            // Mark loading immediately so the sessions getter returns empty
            // instead of exposing a stale error from a previous wire call.
            this._sessionSearchLoading = true;
        }
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._sessionSearchTimeout = setTimeout(() => {
            const newTerm = val.length >= 3 ? val : null;
            if (newTerm === null) this._sessionSearchLoading = false;
            this.sessionSearchTerm = newTerm;
        }, 300);
    }

    handleSessionSelect(event) {
        const id = event.currentTarget.dataset.id;
        if (this.selectedSessionId === id) {
            this.selectedSessionId = null;
            this.selectedSession = null;
        } else {
            this.selectedSessionId = id;
            const raw = (this._rawSessions.data || []).find(s => s.Id === id);
            this.selectedSession = raw ? enrichSession(raw, id) : null;
        }
    }

    handleSessionCardKeydown(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            this.handleSessionSelect(event);
        }
    }

    toggleNewSession() {
        this.showNewSession = !this.showNewSession;
    }

    handleNewSessionFieldChange(event) {
        const field = event.target.name;
        const value = event.target.type === 'checkbox'
            ? event.target.checked
            : event.target.value;
        this.newSession = { ...this.newSession, [field]: value };
    }

    async handleSaveNewSession() {
        if (!this.newSession.Name || !this.newSession.Name.trim()) {
            this._toast('Session Name is required', 'Please enter a session name before saving.', 'error');
            return;
        }
        if (!this.newSession.Session_Date__c) {
            this._toast('Session Date is required', 'Please enter a session date before saving.', 'error');
            return;
        }
        this.isSaving = true;
        try {
            const saved = await saveSession({ session: this.newSession });
            this._toast('Session created', `"${saved.Name}" has been created.`, 'success');
            this.selectedSessionId = saved.Id;
            this.selectedSession = enrichSession(saved, saved.Id);
            this.showNewSession = false;
            this.newSession = { Name: '', Status__c: 'Draft', Level__c: '' };
            await refreshApex(this._rawSessions);
        } catch (e) {
            this._toast('Error saving session', this._errorMessage(e), 'error');
        } finally {
            this.isSaving = false;
        }
    }

    async goToStep2() {
        if (!this.selectedSessionId) {
            this._toast('No session selected', 'Please select or create a session before proceeding.', 'warning');
            return;
        }
        this.currentStep = 2;
        // Imperative fetch as fallback in case the wire channel drops in Local Dev
        try {
            const data = await getSessionSpeakersLive({ sessionId: this.selectedSessionId });
            this._enrichedSessionSpeakers = {
                data: data.map(enrichSessionSpeaker),
                error: undefined
            };
        } catch (e) {
            // Surface error if wire hasn't already resolved
            if (this._enrichedSessionSpeakers.data === null) {
                this._enrichedSessionSpeakers = { data: null, error: e };
            }
        }
    }

    // ─── Step 2: Speakers ─────────────────────────────────────────────────────
    _sessionSpeakersResult;
    _enrichedSessionSpeakers = { data: null, error: null };

    @wire(getSessionSpeakers, { sessionId: '$selectedSessionId' })
    wiredSessionSpeakers(result) {
        this._sessionSpeakersResult = result;
        if (result.data) {
            this._enrichedSessionSpeakers = {
                data: result.data.map(enrichSessionSpeaker),
                error: undefined
            };
        } else if (result.error) {
            this._enrichedSessionSpeakers = { data: null, error: result.error };
        }
    }

    get sessionSpeakers() {
        return this._enrichedSessionSpeakers;
    }

    get hasAssignedSpeakers() {
        return this.sessionSpeakers.data && this.sessionSpeakers.data.length > 0;
    }

    get isSessionCancelled() {
        return this.selectedSession && this.selectedSession.Status__c === 'Cancelled';
    }

    get reviewSpeakerCount() {
        return this.sessionSpeakers.data ? this.sessionSpeakers.data.length : 0;
    }

    async openAddSpeakerPanel() {
        if (this.isSessionCancelled) return;
        const speakerName = await SessionSpeakerAddModal.open({
            sessionId: this.selectedSessionId,
            size: 'small'
        });
        if (speakerName) {
            this._toast('Speaker added', `${speakerName} has been added to the session.`, 'success');
            await this._refreshSpeakers();
        }
    }

    async handleRemoveSpeaker(event) {
        const ssId = event.currentTarget.dataset.id;
        try {
            await removeSessionSpeaker({ sessionSpeakerId: ssId });
            this._toast('Speaker removed', 'Speaker has been removed from this session.', 'success');
            await this._refreshSpeakers();
        } catch (e) {
            this._toast('Error removing speaker', this._errorMessage(e), 'error');
        }
    }

    async handleConfirmedToggle(event) {
        const ssId = event.currentTarget.dataset.id;
        const confirmed = event.target.checked;
        const existing = (this._enrichedSessionSpeakers.data || []).find(ss => ss.Id === ssId);
        if (!existing) return;
        try {
            await saveSessionSpeaker({
                ss: {
                    Id: ssId,
                    Session__c: existing.Session__c,
                    Speaker__c: existing.Speaker__c,
                    Role__c: existing.Role__c,
                    Order__c: existing.Order__c,
                    Confirmed__c: confirmed
                }
            });
            await this._refreshSpeakers();
        } catch (e) {
            this._toast('Error updating confirmation', this._errorMessage(e), 'error');
        }
    }

    async _refreshSpeakers() {
        const data = await getSessionSpeakersLive({ sessionId: this.selectedSessionId });
        this._enrichedSessionSpeakers = {
            data: data.map(enrichSessionSpeaker),
            error: undefined
        };
    }

    goToStep1() { this.currentStep = 1; }
    goToStep3() { this.currentStep = 3; }

    // ─── Step 3: Review & Navigation ─────────────────────────────────────────
    navigateToSession() {
        if (!this.selectedSessionId) return;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.selectedSessionId,
                objectApiName: 'Session__c',
                actionName: 'view'
            }
        });
    }

    disconnectedCallback() {
        window.clearTimeout(this._sessionSearchTimeout);
    }

    handleReset() {
        this.currentStep = 1;
        this.sessionSearchTerm = null;
        this.selectedSessionId = null;
        this.selectedSession = null;
        this.showNewSession = false;
        this.newSession = { Name: '', Status__c: 'Draft', Level__c: '' };
        this._enrichedSessionSpeakers = { data: null, error: null };
        this._sessionSpeakersResult = undefined;
        this._sessionSearchLoading = false;
    }

    // ─── Utilities ────────────────────────────────────────────────────────────
    _toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    _errorMessage(error) {
        if (!error) return 'An unexpected error occurred.';
        if (error.body) {
            if (error.body.message) return error.body.message;
            if (error.body.output) {
                const errs = error.body.output.errors;
                if (errs && errs.length > 0) return errs[0].message;
                const fieldErrs = error.body.output.fieldErrors;
                if (fieldErrs) {
                    const flat = Object.values(fieldErrs).flat();
                    if (flat.length > 0) return flat[0].message;
                }
            }
            if (error.body.fieldErrors) {
                const flat = Object.values(error.body.fieldErrors).flat();
                if (flat.length > 0) return flat[0].message;
            }
        }
        if (error.message) return error.message;
        return 'An unexpected error occurred.';
    }
}
