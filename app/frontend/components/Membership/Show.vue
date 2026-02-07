<template>
    <div class="mt-4 p-5 bg-light text-black rounded --bs-gray-500">
        <h1> Afilierea {{membership.id}}</h1>
        <p><strong>Sportiv: </strong><a :href="`/runners/${membership.runner_id}`">{{membership.runner?.runner_name}} {{membership.runner?.surname}}</a></p>
        <p><strong>Club: </strong><a :href="`/clubs/${membership.club_id}`">{{membership.club?.club_name}}</a></p>
        <p><strong>Numarul de rezultate: </strong><a :href="`/results?membership=${membership.id}`">{{results.length}}</a></p>
    </div>
    <p class="d-inline-flex gap-1">
        <a class="btn btn-primary" data-bs-toggle="collapse" href="#resultsTable" role="button" aria-expanded="false" aria-controls="resultsTable">
            Rezultate
        </a>
    </p>
    <div class="collapse" id="resultsTable">
        <div class="card card-body">
            <ResultsTable :elements="results" @order="orderResultTable"></ResultsTable>
        </div>
    </div>
    <p class="lead">
        <button class="btn btn-sm btn-success" @click="editElement(membership)">Editeaza</button>
        <button class="btn btn-danger btn-sm" @click="deleteMembership(membership.id)">Sterge</button>
        <button class="btn btn-secondary btn-sm" @click="goBack()">Înapoi</button>
    </p>
    <Modal ref="modal" :membership="modalElement" :isNew="false" @save="updateElement" />
</template>
<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import Modal from './Modal.vue'
import ResultsTable from '../Result/Table.vue'

axios.defaults.headers['X-CSRF-Token'] = document.querySelector('meta[ name="csrf-token"]').getAttribute('content')

const membership = ref({})
const membershipId = ref("")
const results = ref([])
const resultSorting = ref({
    "sorting[sort_by]": "date",
    "sorting[direction]": "desc"
})

const modalElement = ref({})
const modal = ref(null)

onMounted(() => {
    membershipId.value = window.location.pathname.split('/').pop();
    getData();
    getResults();
})

async function getData() {
    const res = await axios.get(`/memberships/${membershipId.value}.json`)
    membership.value = res.data
}

async function getResults() {
    resultSorting.value["membership"] = membershipId.value
    const res = await axios.get('/results.json', { params: resultSorting.value })
    results.value = res.data;
}

function orderResultTable(sortKey) {
    orderTable(sortKey, resultSorting)
    getResults();
}

function editElement(membership) {
    modalElement.value = { ...membership }
    modal.value.show()
}

function updateElement(membershipData, done) {
    axios.patch(`/memberships/${membershipData.id}.json`, { membership: membershipData }).then(res => {
        getData();
        done()
    })
}

function deleteMembership(id) {
    if (confirm('Esti sigur ca vrei sa stergi această afiliere?')) {
        axios.delete(`/memberships/${id}`).then(() => {
            if (document.referrer) {
                window.location = document.referrer;
            } else {
                window.location = "/memberships";
            }
        })
    }
}

function goBack() {
    if (document.referrer) {
        window.location = document.referrer;
    } else {
        window.location = "/memberships";
    }
}

function orderTable(sortKey, filters) {
    const isCurrentSort = filters.value["sorting[sort_by]"] === sortKey;
    const currentDir = filters.value["sorting[direction]"];

    filters.value["sorting[direction]"] = (isCurrentSort && currentDir === "asc") ? "desc" : "asc";
    filters.value["sorting[sort_by]"] = sortKey;
}

</script>
